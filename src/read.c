#include "datasetjson.h"
#include "yyjson.h"
#include <zlib.h>

#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <errno.h>
#include <stdio.h>

/* ------------------------------------------------------------------------ *
 * Schema-directed Dataset JSON reader.
 *
 * The column metadata tells us every column's type before we touch `rows`, so
 * we allocate typed vectors up front and parse each value straight into them.
 * Numbers never round-trip through an R string, which is what makes this exact
 * where `as.double()` is not.
 * ------------------------------------------------------------------------ */

typedef enum {
  COL_STRING,
  COL_INTEGER,
  COL_DECIMAL,   /* JSON string holding a number; parsed with strtod */
  COL_REAL,
  COL_BOOL
} col_type;

/* Problems are tallied rather than warned about per-cell: a malformed column
   would otherwise emit one warning per row. */
typedef struct {
  R_xlen_t bad_type;
  R_xlen_t bad_decimal;
  R_xlen_t int_overflow;
  R_xlen_t short_row;
} tally;

static const char *val_str(yyjson_val *v, size_t *len) {
  *len = yyjson_get_len(v);
  return yyjson_get_str(v);
}

/* --- metadata helpers --------------------------------------------------- */

static SEXP str_scalar(yyjson_val *obj, const char *key) {
  yyjson_val *v = yyjson_obj_get(obj, key);
  if (!v || !yyjson_is_str(v)) return R_NilValue;
  size_t len;
  const char *s = val_str(v, &len);
  return Rf_ScalarString(Rf_mkCharLenCE(s, (int) len, CE_UTF8));
}

static SEXP int_scalar(yyjson_val *obj, const char *key) {
  yyjson_val *v = yyjson_obj_get(obj, key);
  if (!v || !yyjson_is_num(v)) return R_NilValue;
  double d = yyjson_get_num(v);
  if (d > INT_MAX || d < INT_MIN + 1) return Rf_ScalarReal(d);
  return Rf_ScalarInteger((int) d);
}

static col_type classify(const char *dt, const char *tdt) {
  if (!dt) return COL_STRING;
  if (!strcmp(dt, "string"))  return COL_STRING;
  if (!strcmp(dt, "integer")) return COL_INTEGER;
  if (!strcmp(dt, "decimal")) {
    /* Per the spec decimal is only valid alongside targetDataType "decimal".
       Without it we leave the value as text rather than guessing. */
    return (tdt && !strcmp(tdt, "decimal")) ? COL_DECIMAL : COL_STRING;
  }
  if (!strcmp(dt, "float") || !strcmp(dt, "double")) return COL_REAL;
  if (!strcmp(dt, "boolean")) return COL_BOOL;
  if (!strcmp(dt, "date") || !strcmp(dt, "datetime") || !strcmp(dt, "time")) {
    /* Regardless of targetDataType these arrive as ISO 8601 strings - that is
       what write_dataset_json() emits, and date_time_conversions() builds the
       Date/POSIXct/hms from the string. targetDataType only selects the class.
       A numeric value from another producer is rendered below instead. */
    (void) tdt;
    return COL_STRING;
  }
  return COL_STRING;
}

/* Column metadata: one R vector per known field, across all columns. Fields
   absent from every column are dropped, matching the shape callers expect. */
static const char *COL_FIELDS[] = {
  "itemOID", "name", "label", "dataType", "targetDataType",
  "length", "keySequence", "displayFormat"
};
static const int COL_FIELD_INT[] = { 0, 0, 0, 0, 0, 1, 1, 0 };
#define N_COL_FIELDS 8

static SEXP build_columns(yyjson_val *cols, size_t ncol) {
  SEXP out = PROTECT(Rf_allocVector(VECSXP, N_COL_FIELDS));
  SEXP nms = PROTECT(Rf_allocVector(STRSXP, N_COL_FIELDS));
  int present[N_COL_FIELDS] = {0};

  for (int f = 0; f < N_COL_FIELDS; f++) {
    SET_VECTOR_ELT(out, f, COL_FIELD_INT[f] ? Rf_allocVector(INTSXP, (R_xlen_t) ncol)
                                            : Rf_allocVector(STRSXP, (R_xlen_t) ncol));
    SET_STRING_ELT(nms, f, Rf_mkChar(COL_FIELDS[f]));
  }

  yyjson_arr_iter it;
  yyjson_arr_iter_init(cols, &it);
  yyjson_val *col;
  R_xlen_t i = 0;
  while ((col = yyjson_arr_iter_next(&it)) && i < (R_xlen_t) ncol) {
    for (int f = 0; f < N_COL_FIELDS; f++) {
      yyjson_val *v = yyjson_is_obj(col) ? yyjson_obj_get(col, COL_FIELDS[f]) : NULL;
      SEXP dest = VECTOR_ELT(out, f);
      if (COL_FIELD_INT[f]) {
        if (v && yyjson_is_num(v)) {
          INTEGER(dest)[i] = (int) yyjson_get_num(v);
          present[f] = 1;
        } else {
          INTEGER(dest)[i] = NA_INTEGER;
        }
      } else {
        if (v && yyjson_is_str(v)) {
          size_t len;
          const char *s = val_str(v, &len);
          SET_STRING_ELT(dest, i, Rf_mkCharLenCE(s, (int) len, CE_UTF8));
          present[f] = 1;
        } else {
          SET_STRING_ELT(dest, i, NA_STRING);
        }
      }
    }
    i++;
  }

  /* drop fields that appeared nowhere */
  int keep = 0;
  for (int f = 0; f < N_COL_FIELDS; f++) keep += present[f];
  SEXP kept  = PROTECT(Rf_allocVector(VECSXP, keep));
  SEXP knms  = PROTECT(Rf_allocVector(STRSXP, keep));
  int k = 0;
  for (int f = 0; f < N_COL_FIELDS; f++) {
    if (!present[f]) continue;
    SET_VECTOR_ELT(kept, k, VECTOR_ELT(out, f));
    SET_STRING_ELT(knms, k, STRING_ELT(nms, f));
    k++;
  }
  Rf_setAttrib(kept, R_NamesSymbol, knms);
  UNPROTECT(4);
  return kept;
}

/* --- row parsing -------------------------------------------------------- */

static void store(SEXP dest, col_type ct, R_xlen_t i, yyjson_val *v, tally *t) {
  if (!v || yyjson_is_null(v)) {
    switch (ct) {
      case COL_STRING:  SET_STRING_ELT(dest, i, NA_STRING);   return;
      case COL_INTEGER: INTEGER(dest)[i] = NA_INTEGER;        return;
      case COL_BOOL:    LOGICAL(dest)[i] = NA_LOGICAL;        return;
      default:          REAL(dest)[i]    = NA_REAL;           return;
    }
  }

  switch (ct) {
  case COL_STRING: {
    if (yyjson_is_str(v)) {
      size_t len;
      const char *s = val_str(v, &len);
      SET_STRING_ELT(dest, i, Rf_mkCharLenCE(s, (int) len, CE_UTF8));
    } else if (yyjson_is_num(v)) {
      /* a producer that wrote a bare number where we expect text; %.17g is the
         round-trip-safe rendering */
      char buf[32];
      snprintf(buf, sizeof(buf), "%.17g", yyjson_get_num(v));
      SET_STRING_ELT(dest, i, Rf_mkChar(buf));
    } else if (yyjson_is_bool(v)) {
      SET_STRING_ELT(dest, i, Rf_mkChar(yyjson_get_bool(v) ? "true" : "false"));
    } else {
      SET_STRING_ELT(dest, i, NA_STRING);
      t->bad_type++;
    }
    return;
  }
  case COL_INTEGER: {
    if (yyjson_is_num(v)) {
      double d = yyjson_get_num(v);
      if (d > INT_MAX || d < INT_MIN + 1) {
        INTEGER(dest)[i] = NA_INTEGER;
        t->int_overflow++;
      } else {
        INTEGER(dest)[i] = (int) d;
      }
    } else {
      INTEGER(dest)[i] = NA_INTEGER;
      t->bad_type++;
    }
    return;
  }
  case COL_BOOL: {
    if (yyjson_is_bool(v)) {
      LOGICAL(dest)[i] = yyjson_get_bool(v) ? TRUE : FALSE;
    } else {
      LOGICAL(dest)[i] = NA_LOGICAL;
      t->bad_type++;
    }
    return;
  }
  case COL_REAL: {
    if (yyjson_is_num(v)) {
      REAL(dest)[i] = yyjson_get_num(v);
    } else {
      REAL(dest)[i] = NA_REAL;
      t->bad_type++;
    }
    return;
  }
  case COL_DECIMAL: {
    /* decimal/decimal arrives as a JSON string. strtod is correctly rounded;
       R's as.double() is not, which is the whole reason this file exists. */
    if (yyjson_is_str(v)) {
      size_t len;
      const char *s = val_str(v, &len);
      if (len == 0) { REAL(dest)[i] = NA_REAL; return; }
      char *end = NULL;
      errno = 0;
      double d = strtod(s, &end);
      if (end == s) {
        REAL(dest)[i] = NA_REAL;
        t->bad_decimal++;
      } else {
        while (*end == ' ' || *end == '\t') end++;
        if (*end != '\0') t->bad_decimal++;
        REAL(dest)[i] = d;
      }
    } else if (yyjson_is_num(v)) {
      /* tolerate a producer that wrote a bare number for a decimal column */
      REAL(dest)[i] = yyjson_get_num(v);
    } else {
      REAL(dest)[i] = NA_REAL;
      t->bad_type++;
    }
    return;
  }
  }
}

/* Classify every column and allocate a typed vector of `nrow` for each.
   Returns the named list; fills `types`. Caller must PROTECT the result. */
static SEXP alloc_columns(yyjson_val *cols, size_t ncol, size_t nrow,
                          col_type *types) {
  SEXP data = PROTECT(Rf_allocVector(VECSXP, (R_xlen_t) ncol));
  SEXP dnms = PROTECT(Rf_allocVector(STRSXP, (R_xlen_t) ncol));

  yyjson_arr_iter it;
  yyjson_arr_iter_init(cols, &it);
  yyjson_val *col;
  size_t j = 0;
  while ((col = yyjson_arr_iter_next(&it)) && j < ncol) {
    yyjson_val *dtv  = yyjson_is_obj(col) ? yyjson_obj_get(col, "dataType") : NULL;
    yyjson_val *tdtv = yyjson_is_obj(col) ? yyjson_obj_get(col, "targetDataType") : NULL;
    yyjson_val *nmv  = yyjson_is_obj(col) ? yyjson_obj_get(col, "name") : NULL;

    types[j] = classify(yyjson_is_str(dtv)  ? yyjson_get_str(dtv)  : NULL,
                        yyjson_is_str(tdtv) ? yyjson_get_str(tdtv) : NULL);

    SEXPTYPE st = (types[j] == COL_STRING)  ? STRSXP
                : (types[j] == COL_INTEGER) ? INTSXP
                : (types[j] == COL_BOOL)    ? LGLSXP
                                            : REALSXP;
    SET_VECTOR_ELT(data, (R_xlen_t) j, Rf_allocVector(st, (R_xlen_t) nrow));

    if (!yyjson_is_str(nmv)) {
      /* `name` is required by the standard, and without it the column cannot be
         placed in the data frame - fail here rather than deeper in R */
      UNPROTECT(2);
      Rf_error("Column %d in `columns` has no `name`", (int) (j + 1));
    }
    {
      size_t len;
      const char *s = val_str(nmv, &len);
      SET_STRING_ELT(dnms, (R_xlen_t) j, Rf_mkCharLenCE(s, (int) len, CE_UTF8));
    }
    j++;
  }
  Rf_setAttrib(data, R_NamesSymbol, dnms);
  UNPROTECT(2);
  return data;
}

/* Fill row `i` of `dest` from a JSON array of values. */
static void store_row(yyjson_val *row, SEXP *dest, const col_type *types,
                      size_t ncol, R_xlen_t i, tally *t) {
  yyjson_arr_iter cit;
  yyjson_arr_iter_init(row, &cit);
  for (size_t j = 0; j < ncol; j++) {
    yyjson_val *v = yyjson_arr_iter_next(&cit);
    if (!v) t->short_row++;
    store(dest[j], types[j], i, v, t);
  }
}

static void warn_tally(const tally *t) {
  if (t->bad_type)     Rf_warning("%lld value(s) did not match the declared column dataType and were set to NA", (long long) t->bad_type);
  if (t->bad_decimal)  Rf_warning("%lld decimal value(s) could not be parsed as numbers", (long long) t->bad_decimal);
  if (t->int_overflow) Rf_warning("%lld integer value(s) exceeded R's integer range and were set to NA", (long long) t->int_overflow);
  if (t->short_row)    Rf_warning("%lld row(s) had fewer values than there are columns", (long long) t->short_row);
}

/* Assemble the list handed back to R: metadata scalars, column metadata and
   the typed data columns. `root` is the object carrying the metadata (the
   whole document for JSON, the first line for NDJSON). */
static SEXP assemble(yyjson_val *root, yyjson_val *cols, size_t ncol, SEXP data) {
  int nprot = 0;
  PROTECT(data); nprot++;
  /* top-level metadata, shaped like the list callers already consume */
  static const char *META[] = {
    "datasetJSONCreationDateTime", "datasetJSONVersion", "fileOID",
    "dbLastModifiedDateTime", "originator", "studyOID", "metaDataVersionOID",
    "metaDataRef", "itemGroupOID", "name", "label"
  };
  const int n_meta = (int) (sizeof(META) / sizeof(META[0]));
  const int n_out  = n_meta + 4;  /* + sourceSystem, records, columns, data */

  SEXP out  = PROTECT(Rf_allocVector(VECSXP, n_out)); nprot++;
  SEXP onms = PROTECT(Rf_allocVector(STRSXP, n_out)); nprot++;

  for (int m = 0; m < n_meta; m++) {
    SET_VECTOR_ELT(out, m, str_scalar(root, META[m]));
    SET_STRING_ELT(onms, m, Rf_mkChar(META[m]));
  }

  {
    yyjson_val *ss = yyjson_obj_get(root, "sourceSystem");
    SEXP ssl = R_NilValue;
    if (ss && yyjson_is_obj(ss)) {
      ssl = PROTECT(Rf_allocVector(VECSXP, 2)); nprot++;
      SEXP ssn = PROTECT(Rf_allocVector(STRSXP, 2)); nprot++;
      SET_VECTOR_ELT(ssl, 0, str_scalar(ss, "name"));
      SET_VECTOR_ELT(ssl, 1, str_scalar(ss, "version"));
      SET_STRING_ELT(ssn, 0, Rf_mkChar("name"));
      SET_STRING_ELT(ssn, 1, Rf_mkChar("version"));
      Rf_setAttrib(ssl, R_NamesSymbol, ssn);
    }
    SET_VECTOR_ELT(out, n_meta, ssl);
    SET_STRING_ELT(onms, n_meta, Rf_mkChar("sourceSystem"));
  }

  SET_VECTOR_ELT(out, n_meta + 1, int_scalar(root, "records"));
  SET_STRING_ELT(onms, n_meta + 1, Rf_mkChar("records"));

  SET_VECTOR_ELT(out, n_meta + 2, build_columns(cols, ncol));
  SET_STRING_ELT(onms, n_meta + 2, Rf_mkChar("columns"));

  SET_VECTOR_ELT(out, n_meta + 3, data);
  SET_STRING_ELT(onms, n_meta + 3, Rf_mkChar("data"));

  Rf_setAttrib(out, R_NamesSymbol, onms);
  UNPROTECT(nprot);
  return out;
}

static SEXP build_result(yyjson_doc *doc) {
  yyjson_val *root = yyjson_doc_get_root(doc);
  if (!root || !yyjson_is_obj(root)) {
    Rf_error("Dataset JSON must be a JSON object at the top level");
  }

  yyjson_val *cols = yyjson_obj_get(root, "columns");
  yyjson_val *rows = yyjson_obj_get(root, "rows");
  if (!cols || !yyjson_is_arr(cols)) Rf_error("`columns` is missing or not an array");
  if (!rows || !yyjson_is_arr(rows)) Rf_error("`rows` is missing or not an array");

  size_t ncol = yyjson_arr_size(cols);
  size_t nrow = yyjson_arr_size(rows);
  if (ncol == 0) Rf_error("`columns` is empty");

  col_type *types = (col_type *) R_alloc(ncol, sizeof(col_type));
  SEXP data = PROTECT(alloc_columns(cols, ncol, nrow, types));

  SEXP *dest = (SEXP *) R_alloc(ncol, sizeof(SEXP));
  for (size_t j = 0; j < ncol; j++) dest[j] = VECTOR_ELT(data, (R_xlen_t) j);

  tally t = {0, 0, 0, 0};
  yyjson_arr_iter rit;
  yyjson_arr_iter_init(rows, &rit);
  yyjson_val *row;
  R_xlen_t i = 0;
  while ((row = yyjson_arr_iter_next(&rit))) {
    if (!yyjson_is_arr(row)) {
      Rf_error("Row %lld is not an array; Dataset JSON rows must be arrays of values",
               (long long) (i + 1));
    }
    store_row(row, dest, types, ncol, i, &t);
    i++;
  }

  SEXP out = PROTECT(assemble(root, cols, ncol, data));
  warn_tally(&t);
  UNPROTECT(2);
  return out;
}

/* --- entry points ------------------------------------------------------- */

SEXP C_read_dsjson_file(SEXP path_) {
  const char *path = CHAR(STRING_ELT(path_, 0));
  yyjson_read_err err;
  yyjson_doc *doc = yyjson_read_file(path, 0, NULL, &err);
  if (!doc) Rf_error("Failed to parse '%s': %s (at byte %lu)", path, err.msg, (unsigned long) err.pos);
  SEXP out;
  /* build_result may longjmp on error; yyjson's arena is freed either way by
     the R error handler only if we free before erroring, so keep errors above
     allocation-heavy work and free explicitly on the success path. */
  out = PROTECT(build_result(doc));
  yyjson_doc_free(doc);
  UNPROTECT(1);
  return out;
}

SEXP C_read_dsjson_str(SEXP txt_) {
  SEXP s = STRING_ELT(txt_, 0);
  const char *txt = CHAR(s);
  size_t len = (size_t) LENGTH(s);
  yyjson_read_err err;
  yyjson_doc *doc = yyjson_read_opts((char *) txt, len, 0, NULL, &err);
  if (!doc) Rf_error("Failed to parse JSON: %s (at byte %lu)", err.msg, (unsigned long) err.pos);
  SEXP out = PROTECT(build_result(doc));
  yyjson_doc_free(doc);
  UNPROTECT(1);
  return out;
}

/* ------------------------------------------------------------------------ *
 * Dataset NDJSON: line 1 is the metadata object, lines 2..n are row arrays.
 * ------------------------------------------------------------------------ */

typedef struct { const char *ptr; size_t len; } line;

/* Split on \n, trimming a trailing \r and dropping blank lines. */
static line *split_lines(const char *buf, size_t len, size_t *nlines) {
  size_t cap = 64, n = 0;
  line *out = (line *) R_alloc(cap, sizeof(line));
  size_t i = 0;
  while (i < len) {
    const char *nl = (const char *) memchr(buf + i, '\n', len - i);
    size_t stop = nl ? (size_t) (nl - buf) : len;
    size_t start = i, end = stop;
    if (end > start && buf[end - 1] == '\r') end--;
    /* skip lines that are entirely whitespace */
    size_t k = start;
    while (k < end && (buf[k] == ' ' || buf[k] == '\t')) k++;
    if (k < end) {
      if (n == cap) {
        size_t ncap = cap * 2;
        line *bigger = (line *) R_alloc(ncap, sizeof(line));
        memcpy(bigger, out, n * sizeof(line));
        out = bigger; cap = ncap;
      }
      out[n].ptr = buf + start;
      out[n].len = end - start;
      n++;
    }
    if (!nl) break;
    i = stop + 1;
  }
  *nlines = n;
  return out;
}

static SEXP ndjson_core(const char *buf, size_t len) {
  size_t nlines = 0;
  line *lines = split_lines(buf, len, &nlines);
  if (nlines == 0) Rf_error("Dataset NDJSON file is empty");

  yyjson_read_err err;
  yyjson_doc *mdoc = yyjson_read_opts((char *) lines[0].ptr, lines[0].len,
                                      0, NULL, &err);
  if (!mdoc) Rf_error("Failed to parse the metadata line: %s (at byte %lu)",
                      err.msg, (unsigned long) err.pos);

  yyjson_val *root = yyjson_doc_get_root(mdoc);
  if (!root || !yyjson_is_obj(root)) {
    yyjson_doc_free(mdoc);
    Rf_error("The first NDJSON line must be a JSON object of dataset metadata");
  }
  yyjson_val *cols = yyjson_obj_get(root, "columns");
  if (!cols || !yyjson_is_arr(cols)) {
    yyjson_doc_free(mdoc);
    Rf_error("`columns` is missing from the metadata line or is not an array");
  }
  size_t ncol = yyjson_arr_size(cols);
  if (ncol == 0) { yyjson_doc_free(mdoc); Rf_error("`columns` is empty"); }

  size_t nrow = nlines - 1;
  col_type *types = (col_type *) R_alloc(ncol, sizeof(col_type));
  SEXP data = PROTECT(alloc_columns(cols, ncol, nrow, types));

  SEXP *dest = (SEXP *) R_alloc(ncol, sizeof(SEXP));
  for (size_t j = 0; j < ncol; j++) dest[j] = VECTOR_ELT(data, (R_xlen_t) j);

  /* One pooled arena, re-initialised per line, keeps row parsing malloc-free.
     Sized off the longest line; if a read still fails we fall back to malloc. */
  size_t maxlen = 0;
  for (size_t l = 1; l < nlines; l++) if (lines[l].len > maxlen) maxlen = lines[l].len;
  size_t pool_sz = maxlen * 8 + 4096;
  void *pool = R_alloc(pool_sz, 1);

  tally t = {0, 0, 0, 0};
  for (size_t l = 1; l < nlines; l++) {
    yyjson_alc alc;
    yyjson_doc *rdoc = NULL;
    if (pool && yyjson_alc_pool_init(&alc, pool, pool_sz)) {
      rdoc = yyjson_read_opts((char *) lines[l].ptr, lines[l].len, 0, &alc, &err);
    }
    if (!rdoc) {
      rdoc = yyjson_read_opts((char *) lines[l].ptr, lines[l].len, 0, NULL, &err);
      if (!rdoc) {
        yyjson_doc_free(mdoc);
        Rf_error("Failed to parse data line %lu: %s", (unsigned long) (l + 1), err.msg);
      }
    }
    yyjson_val *row = yyjson_doc_get_root(rdoc);
    if (!row || !yyjson_is_arr(row)) {
      yyjson_doc_free(mdoc);
      Rf_error("NDJSON line %lu is not an array of values", (unsigned long) (l + 1));
    }
    store_row(row, dest, types, ncol, (R_xlen_t) (l - 1), &t);
    /* pooled docs own no heap memory; freeing a malloc-backed one is required */
  }

  SEXP out = PROTECT(assemble(root, cols, ncol, data));
  yyjson_doc_free(mdoc);
  warn_tally(&t);
  UNPROTECT(2);
  return out;
}

SEXP C_read_dsndjson_file(SEXP path_) {
  const char *path = CHAR(STRING_ELT(path_, 0));
  FILE *fp = fopen(path, "rb");
  if (!fp) Rf_error("Could not open '%s'", path);
  if (fseek(fp, 0, SEEK_END) != 0) { fclose(fp); Rf_error("Could not read '%s'", path); }
  long sz = ftell(fp);
  if (sz < 0) { fclose(fp); Rf_error("Could not read '%s'", path); }
  rewind(fp);

  char *buf = (char *) R_alloc((size_t) sz + 1, 1);
  size_t got = fread(buf, 1, (size_t) sz, fp);
  fclose(fp);
  buf[got] = '\0';

  return ndjson_core(buf, got);
}

SEXP C_read_dsndjson_str(SEXP txt_) {
  SEXP s = STRING_ELT(txt_, 0);
  return ndjson_core(CHAR(s), (size_t) LENGTH(s));
}

/* Structural check used by validate_dataset_ndjson(): how many columns the
   metadata line declares, and how many values each data line carries.
   NA marks a line that is not valid JSON; -1 marks valid JSON that is not an
   array. */
SEXP C_ndjson_shape(SEXP lines_) {
  R_xlen_t n = Rf_xlength(lines_);
  SEXP lens = PROTECT(Rf_allocVector(INTSXP, n > 0 ? n - 1 : 0));
  int ncol = NA_INTEGER;
  yyjson_read_err err;

  for (R_xlen_t i = 0; i < n; i++) {
    SEXP s = STRING_ELT(lines_, i);
    if (s == NA_STRING) {
      if (i > 0) INTEGER(lens)[i - 1] = NA_INTEGER;
      continue;
    }
    yyjson_doc *d = yyjson_read_opts((char *) CHAR(s), (size_t) LENGTH(s), 0, NULL, &err);
    if (!d) {
      if (i > 0) INTEGER(lens)[i - 1] = NA_INTEGER;
      continue;
    }
    yyjson_val *root = yyjson_doc_get_root(d);
    if (i == 0) {
      yyjson_val *cols = (root && yyjson_is_obj(root)) ? yyjson_obj_get(root, "columns") : NULL;
      if (cols && yyjson_is_arr(cols)) ncol = (int) yyjson_arr_size(cols);
    } else {
      INTEGER(lens)[i - 1] = (root && yyjson_is_arr(root)) ? (int) yyjson_arr_size(root) : -1;
    }
    yyjson_doc_free(d);
  }

  SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
  SEXP nms = PROTECT(Rf_allocVector(STRSXP, 2));
  SET_VECTOR_ELT(out, 0, Rf_ScalarInteger(ncol));
  SET_VECTOR_ELT(out, 1, lens);
  SET_STRING_ELT(nms, 0, Rf_mkChar("ncol"));
  SET_STRING_ELT(nms, 1, Rf_mkChar("lengths"));
  Rf_setAttrib(out, R_NamesSymbol, nms);
  UNPROTECT(3);
  return out;
}

/* ------------------------------------------------------------------------ *
 * Dataset JSON Compressed (DSJC): inflate the zLib stream, then read the
 * result as Dataset NDJSON.
 * ------------------------------------------------------------------------ */

/* Inflate the whole stream into an R-managed raw vector.
   Inflating into R memory rather than malloc means the buffer needs no copy
   before parsing and cannot leak if parsing later raises an error - which
   matters at scale, where the copy alone cost as much resident memory as the
   decompressed content. */
static SEXP dsjc_core(const unsigned char *in, size_t n) {
  z_stream zs;
  memset(&zs, 0, sizeof(zs));
  if (inflateInit(&zs) != Z_OK) Rf_error("Could not initialise zLib");

  /* zLib streams carry no uncompressed size, so this is an estimate; text of
     this shape typically compresses to under a third */
  R_xlen_t cap = (R_xlen_t) n * 4 + 1024;
  PROTECT_INDEX pi;
  SEXP buf;
  PROTECT_WITH_INDEX(buf = Rf_allocVector(RAWSXP, cap), &pi);

  size_t len = 0;
  int rc = Z_OK;
  const char *msg = NULL;

  zs.next_in = (Bytef *) in;
  zs.avail_in = (uInt) n;
  while (rc != Z_STREAM_END) {
    if ((R_xlen_t) len == cap) {
      cap *= 2;
      REPROTECT(buf = Rf_xlengthgets(buf, cap), pi);
    }
    zs.next_out = (Bytef *) (RAW(buf) + len);
    zs.avail_out = (uInt) ((size_t) cap - len);
    rc = inflate(&zs, Z_NO_FLUSH);
    if (rc != Z_OK && rc != Z_STREAM_END) {
      msg = zs.msg ? zs.msg : "invalid or corrupt compressed data";
      break;
    }
    len = (size_t) cap - zs.avail_out;
    if (rc == Z_OK && zs.avail_in == 0 && zs.avail_out != 0) {
      msg = "compressed stream ended before it was complete";
      break;
    }
  }
  inflateEnd(&zs);
  if (msg) {
    UNPROTECT(1);
    Rf_error("Could not read Dataset JSON Compressed content: %s", msg);
  }

  SEXP out = PROTECT(ndjson_core((const char *) RAW(buf), len));
  UNPROTECT(2);
  return out;
}

SEXP C_read_dsjc_file(SEXP path_) {
  const char *path = CHAR(STRING_ELT(path_, 0));
  FILE *fp = fopen(path, "rb");
  if (!fp) Rf_error("Could not open '%s'", path);
  if (fseek(fp, 0, SEEK_END) != 0) { fclose(fp); Rf_error("Could not read '%s'", path); }
  long sz = ftell(fp);
  if (sz < 0) { fclose(fp); Rf_error("Could not read '%s'", path); }
  rewind(fp);
  unsigned char *buf = (unsigned char *) R_alloc((size_t) sz + 1, 1);
  size_t got = fread(buf, 1, (size_t) sz, fp);
  fclose(fp);
  return dsjc_core(buf, got);
}

SEXP C_read_dsjc_raw(SEXP raw_) {
  return dsjc_core(RAW(raw_), (size_t) Rf_xlength(raw_));
}
