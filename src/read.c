#include "datasetjson.h"
#include "yyjson.h"

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

  int nprot = 0;

  /* classify each column and allocate its vector */
  col_type *types = (col_type *) R_alloc(ncol, sizeof(col_type));
  SEXP data = PROTECT(Rf_allocVector(VECSXP, (R_xlen_t) ncol)); nprot++;
  SEXP dnms = PROTECT(Rf_allocVector(STRSXP, (R_xlen_t) ncol)); nprot++;

  {
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

      if (yyjson_is_str(nmv)) {
        size_t len;
        const char *s = val_str(nmv, &len);
        SET_STRING_ELT(dnms, (R_xlen_t) j, Rf_mkCharLenCE(s, (int) len, CE_UTF8));
      } else {
        SET_STRING_ELT(dnms, (R_xlen_t) j, NA_STRING);
      }
      j++;
    }
  }
  Rf_setAttrib(data, R_NamesSymbol, dnms);

  /* cache the destination SEXPs so the hot loop avoids VECTOR_ELT dispatch */
  SEXP *dest = (SEXP *) R_alloc(ncol, sizeof(SEXP));
  for (size_t j = 0; j < ncol; j++) dest[j] = VECTOR_ELT(data, (R_xlen_t) j);

  tally t = {0, 0, 0, 0};

  {
    yyjson_arr_iter rit;
    yyjson_arr_iter_init(rows, &rit);
    yyjson_val *row;
    R_xlen_t i = 0;
    while ((row = yyjson_arr_iter_next(&rit))) {
      if (!yyjson_is_arr(row)) {
        Rf_error("Row %lld is not an array; Dataset JSON rows must be arrays of values",
                 (long long) (i + 1));
      }
      yyjson_arr_iter cit;
      yyjson_arr_iter_init(row, &cit);
      for (size_t j = 0; j < ncol; j++) {
        yyjson_val *v = yyjson_arr_iter_next(&cit);
        if (!v) t.short_row++;
        store(dest[j], types[j], i, v, &t);
      }
      i++;
    }
  }

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

  if (t.bad_type)     Rf_warning("%lld value(s) did not match the declared column dataType and were set to NA", (long long) t.bad_type);
  if (t.bad_decimal)  Rf_warning("%lld decimal value(s) could not be parsed as numbers", (long long) t.bad_decimal);
  if (t.int_overflow) Rf_warning("%lld integer value(s) exceeded R's integer range and were set to NA", (long long) t.int_overflow);
  if (t.short_row)    Rf_warning("%lld row(s) had fewer values than there are columns", (long long) t.short_row);

  UNPROTECT(nprot);
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
