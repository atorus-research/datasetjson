#include "datasetjson.h"
#include "yyjson.h"
#include <zlib.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

/* ------------------------------------------------------------------------ *
 * Native Dataset JSON writer.
 *
 * R hands us the metadata already ordered and null-stripped, the column
 * metadata, and the data frame with date/time columns already rendered to
 * character. Everything numeric is serialized by yyjson, whose double writer
 * emits the shortest round-trippable representation.
 * ------------------------------------------------------------------------ */

/* Shortest representation that still parses back to exactly x. This is what
   makes float_as_decimals lossless: R's format(digits = 16) is not. */
static void shortest_round_trip(double x, char *buf, size_t n) {
  for (int prec = 15; prec <= 17; prec++) {
    snprintf(buf, n, "%.*g", prec, x);
    if (strtod(buf, NULL) == x) return;
  }
}

static yyjson_mut_val *chr_val(yyjson_mut_doc *doc, SEXP s) {
  if (s == NA_STRING) return yyjson_mut_null(doc);
  /* CHARSXP data is immovable and stays reachable through the caller's
     arguments for the whole serialization, so ASCII/UTF-8 can be referenced in
     place. Anything needing translation lands in a reused buffer and must be
     copied. */
  const char *c = Rf_translateCharUTF8(s);
  if (c == CHAR(s)) {
    /* no translation happened: point straight at the CHARSXP */
    return yyjson_mut_strn(doc, c, (size_t) LENGTH(s));
  }
  return yyjson_mut_strncpy(doc, c, strlen(c));
}

/* One cell, dispatched on the R vector type. */
static yyjson_mut_val *cell(yyjson_mut_doc *doc, SEXP col, R_xlen_t i,
                            int as_decimal, SEXP levels) {
  if (levels != R_NilValue) {
    int code = INTEGER(col)[i];
    if (code == NA_INTEGER || code < 1 || code > Rf_length(levels)) {
      return yyjson_mut_null(doc);
    }
    return chr_val(doc, STRING_ELT(levels, code - 1));
  }
  switch (TYPEOF(col)) {
  case LGLSXP: {
    int v = LOGICAL(col)[i];
    return (v == NA_LOGICAL) ? yyjson_mut_null(doc) : yyjson_mut_bool(doc, v);
  }
  case INTSXP: {
    int v = INTEGER(col)[i];
    return (v == NA_INTEGER) ? yyjson_mut_null(doc)
                             : yyjson_mut_sint(doc, (int64_t) v);
  }
  case REALSXP: {
    double v = REAL(col)[i];
    if (ISNA(v) || ISNAN(v)) return yyjson_mut_null(doc);
    if (as_decimal) {
      char buf[64];
      shortest_round_trip(v, buf, sizeof(buf));
      return yyjson_mut_strncpy(doc, buf, strlen(buf));
    }
    return yyjson_mut_real(doc, v);
  }
  case STRSXP:
    return chr_val(doc, STRING_ELT(col, i));
  default:
    return yyjson_mut_null(doc);
  }
}

/* A metadata scalar: character, integer or double. */
static yyjson_mut_val *scalar_val(yyjson_mut_doc *doc, SEXP v) {
  if (v == R_NilValue || Rf_xlength(v) == 0) return NULL;
  switch (TYPEOF(v)) {
  case STRSXP:  return chr_val(doc, STRING_ELT(v, 0));
  case INTSXP: {
    int x = INTEGER(v)[0];
    return (x == NA_INTEGER) ? yyjson_mut_null(doc) : yyjson_mut_sint(doc, x);
  }
  case REALSXP: {
    double x = REAL(v)[0];
    if (ISNA(x) || ISNAN(x)) return yyjson_mut_null(doc);
    if (x == floor(x) && fabs(x) < 9.0e15) return yyjson_mut_sint(doc, (int64_t) x);
    return yyjson_mut_real(doc, x);
  }
  case LGLSXP: {
    int x = LOGICAL(v)[0];
    return (x == NA_LOGICAL) ? yyjson_mut_null(doc) : yyjson_mut_bool(doc, x);
  }
  default: return NULL;
  }
}

static void add_kv(yyjson_mut_doc *doc, yyjson_mut_val *obj,
                   const char *key, yyjson_mut_val *val) {
  if (!val) return;
  yyjson_mut_obj_add_val(doc, obj, key, val);
}

/* meta      named list, already in output order with NULLs removed
 * columns   list of per-column named lists (the `columns` metadata)
 * data      list of column vectors
 * as_decimal logical, one per column: write this REALSXP column as a string
 * pretty    logical(1)
 * path      character(1) to write a file, or NULL to return a string
 */
/* Build the document. `rows_out` receives the rows array; it is attached to
   the root for JSON and left standalone for NDJSON, where each row is its own
   line. */
static yyjson_mut_doc *build_doc(SEXP meta, SEXP columns, SEXP data,
                                 SEXP as_decimal, int attach_rows,
                                 yyjson_mut_val **root_out,
                                 yyjson_mut_val **rows_out) {
  R_xlen_t ncol_d = Rf_xlength(data);
  R_xlen_t nrow_d = ncol_d ? Rf_xlength(VECTOR_ELT(data, 0)) : 0;

  yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
  if (!doc) Rf_error("Could not allocate a JSON document");

  yyjson_mut_val *root = yyjson_mut_obj(doc);
  yyjson_mut_doc_set_root(doc, root);

  SEXP mnames = Rf_getAttrib(meta, R_NamesSymbol);
  R_xlen_t nmeta = Rf_xlength(meta);

  for (R_xlen_t m = 0; m < nmeta; m++) {
    const char *key = Rf_translateCharUTF8(STRING_ELT(mnames, m));
    SEXP v = VECTOR_ELT(meta, m);

    /* sourceSystem is the one nested object */
    if (TYPEOF(v) == VECSXP) {
      SEXP snames = Rf_getAttrib(v, R_NamesSymbol);
      if (snames == R_NilValue) continue;
      yyjson_mut_val *sub = yyjson_mut_obj(doc);
      for (R_xlen_t k = 0; k < Rf_xlength(v); k++) {
        add_kv(doc, sub, Rf_translateCharUTF8(STRING_ELT(snames, k)),
               scalar_val(doc, VECTOR_ELT(v, k)));
      }
      add_kv(doc, root, key, sub);
    } else {
      add_kv(doc, root, key, scalar_val(doc, v));
    }
  }

  /* columns: array of objects, omitting absent fields */
  {
    yyjson_mut_val *arr = yyjson_mut_arr(doc);
    R_xlen_t ncol_meta = Rf_xlength(columns);
    for (R_xlen_t j = 0; j < ncol_meta; j++) {
      SEXP cj = VECTOR_ELT(columns, j);
      SEXP cn = Rf_getAttrib(cj, R_NamesSymbol);
      yyjson_mut_val *o = yyjson_mut_obj(doc);
      for (R_xlen_t f = 0; f < Rf_xlength(cj); f++) {
        SEXP fv = VECTOR_ELT(cj, f);
        if (fv == R_NilValue || Rf_xlength(fv) == 0) continue;
        if (TYPEOF(fv) == STRSXP && STRING_ELT(fv, 0) == NA_STRING) continue;
        if (TYPEOF(fv) == INTSXP && INTEGER(fv)[0] == NA_INTEGER) continue;
        add_kv(doc, o, Rf_translateCharUTF8(STRING_ELT(cn, f)), scalar_val(doc, fv));
      }
      yyjson_mut_arr_add_val(arr, o);
    }
    yyjson_mut_obj_add_val(doc, root, "columns", arr);
  }

  /* rows: array of arrays */
  {
    R_xlen_t ncol = ncol_d;
    R_xlen_t nrow = nrow_d;
    int *dec = LOGICAL(as_decimal);

    SEXP *cols = (SEXP *) R_alloc((size_t) (ncol ? ncol : 1), sizeof(SEXP));
    SEXP *levs = (SEXP *) R_alloc((size_t) (ncol ? ncol : 1), sizeof(SEXP));
    for (R_xlen_t j = 0; j < ncol; j++) {
      cols[j] = VECTOR_ELT(data, j);
      /* factors serialize as their labels, not their integer codes */
      levs[j] = Rf_isFactor(cols[j]) ? Rf_getAttrib(cols[j], R_LevelsSymbol)
                                     : R_NilValue;
    }

    yyjson_mut_val *rows = yyjson_mut_arr(doc);
    for (R_xlen_t i = 0; i < nrow; i++) {
      yyjson_mut_val *row = yyjson_mut_arr(doc);
      for (R_xlen_t j = 0; j < ncol; j++) {
        yyjson_mut_arr_add_val(row, cell(doc, cols[j], i, dec[j] == TRUE, levs[j]));
      }
      yyjson_mut_arr_add_val(rows, row);
    }
    if (attach_rows) yyjson_mut_obj_add_val(doc, root, "rows", rows);
    *rows_out = rows;
  }

  *root_out = root;
  return doc;
}

SEXP C_write_dsjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                    SEXP pretty, SEXP path) {
  yyjson_mut_val *root, *rows;
  yyjson_mut_doc *doc = build_doc(meta, columns, data, as_decimal, 1,
                                  &root, &rows);

  yyjson_write_flag flg = LOGICAL(pretty)[0] ? YYJSON_WRITE_PRETTY : YYJSON_WRITE_NOFLAG;

  if (path != R_NilValue && Rf_xlength(path) > 0) {
    yyjson_write_err err;
    const char *p = Rf_translateCharUTF8(STRING_ELT(path, 0));
    bool ok = yyjson_mut_write_file(p, doc, flg, NULL, &err);
    yyjson_mut_doc_free(doc);
    if (!ok) Rf_error("Failed to write '%s': %s", p, err.msg);
    return R_NilValue;
  }

  size_t len = 0;
  yyjson_write_err err;
  char *txt = yyjson_mut_write_opts(doc, flg, NULL, &len, &err);
  yyjson_mut_doc_free(doc);
  if (!txt) Rf_error("Failed to serialize JSON: %s", err.msg);

  SEXP out = PROTECT(Rf_ScalarString(Rf_mkCharLenCE(txt, (int) len, CE_UTF8)));
  free(txt);
  UNPROTECT(1);
  return out;
}

/* ------------------------------------------------------------------------ *
 * Dataset NDJSON writer: the metadata object on line 1, one row array per
 * line after it. Rows are serialized straight out one at a time, so nothing
 * assembles the whole payload as a single string on the file path.
 * ------------------------------------------------------------------------ */

typedef struct { char *dat; size_t len, cap; } strbuf;

static void sb_reserve(strbuf *b, size_t extra) {
  if (b->len + extra <= b->cap) return;
  size_t cap = b->cap ? b->cap : 1024;
  while (cap < b->len + extra) cap *= 2;
  char *p = (char *) realloc(b->dat, cap);
  if (!p) { free(b->dat); b->dat = NULL; Rf_error("Out of memory building JSON"); }
  b->dat = p; b->cap = cap;
}

static void sb_append(strbuf *b, const char *s, size_t n) {
  sb_reserve(b, n);
  memcpy(b->dat + b->len, s, n);
  b->len += n;
}

SEXP C_write_dsndjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                      SEXP path) {
  yyjson_mut_val *root, *rows;
  yyjson_mut_doc *doc = build_doc(meta, columns, data, as_decimal, 0,
                                  &root, &rows);

  /* NDJSON requires exactly one JSON document per line, so never pretty-print */
  const yyjson_write_flag flg = YYJSON_WRITE_NOFLAG;
  yyjson_write_err err;

  FILE *fp = NULL;
  if (path != R_NilValue && Rf_xlength(path) > 0) {
    const char *p = Rf_translateCharUTF8(STRING_ELT(path, 0));
    fp = fopen(p, "wb");
    if (!fp) { yyjson_mut_doc_free(doc); Rf_error("Could not open '%s' for writing", p); }
  }

  /* Serialize into one buffer rather than calling the file writer per row -
     300k separate writes is dramatically slower than a handful of large ones.
     When writing to disk the buffer is flushed periodically so memory stays
     bounded regardless of dataset size. */
  strbuf b = {NULL, 0, 0};
  const size_t FLUSH_AT = 8u << 20;
  /* mutable arrays are linked lists - index access is O(n), so iterate */
  yyjson_mut_arr_iter rit;
  yyjson_mut_arr_iter_init(rows, &rit);
  size_t len = 0;
  int failed = 0;
  const char *failmsg = NULL;

  char *txt = yyjson_mut_val_write_opts(root, flg, NULL, &len, &err);
  if (!txt) { failed = 1; failmsg = err.msg; }
  else { sb_append(&b, txt, len); free(txt); }

  yyjson_mut_val *row;
  while (!failed && (row = yyjson_mut_arr_iter_next(&rit)) != NULL) {
    txt = yyjson_mut_val_write_opts(row, flg, NULL, &len, &err);
    if (!txt) { failed = 1; failmsg = err.msg; break; }
    sb_append(&b, "\n", 1);
    sb_append(&b, txt, len);
    free(txt);
    if (fp && b.len >= FLUSH_AT) {
      if (fwrite(b.dat, 1, b.len, fp) != b.len) { failed = 1; failmsg = "write error"; break; }
      b.len = 0;
    }
  }

  if (fp) {
    if (!failed) {
      sb_append(&b, "\n", 1);
      if (fwrite(b.dat, 1, b.len, fp) != b.len) { failed = 1; failmsg = "write error"; }
    }
    fclose(fp);
    free(b.dat);
    yyjson_mut_doc_free(doc);
    if (failed) Rf_error("Failed to write Dataset NDJSON: %s", failmsg ? failmsg : "unknown error");
    return R_NilValue;
  }

  yyjson_mut_doc_free(doc);
  if (failed) { free(b.dat); Rf_error("Failed to serialize Dataset NDJSON: %s", failmsg ? failmsg : "unknown error"); }

  SEXP out = PROTECT(Rf_ScalarString(Rf_mkCharLenCE(b.dat, (int) b.len, CE_UTF8)));
  free(b.dat);
  UNPROTECT(1);
  return out;
}

/* ------------------------------------------------------------------------ *
 * Dataset JSON Compressed (DSJC): a zLib stream of Dataset NDJSON content,
 * with no wrapper of its own. Rows are deflated as they are serialized rather
 * than after, so a large dataset never needs its NDJSON held in full.
 * ------------------------------------------------------------------------ */

/* Compressed output goes either straight to a file or into a growing buffer
   that becomes a raw vector. */
typedef struct {
  FILE *fp;        /* non-NULL when writing to disk */
  strbuf *buf;     /* non-NULL when returning bytes */
} zsink;

static int zsink_put(zsink *s, const char *dat, size_t n) {
  if (n == 0) return 1;
  if (s->fp) return fwrite(dat, 1, n, s->fp) == n;
  sb_append(s->buf, dat, n);
  return 1;
}

/* Push `n` bytes through the deflate stream into the sink. */
static int zpush(z_stream *zs, zsink *sink, const char *dat, size_t n, int flush) {
  static char out[65536];
  zs->next_in = (Bytef *) dat;
  zs->avail_in = (uInt) n;
  do {
    zs->next_out = (Bytef *) out;
    zs->avail_out = (uInt) sizeof(out);
    int rc = deflate(zs, flush);
    if (rc == Z_STREAM_ERROR) return 0;
    size_t have = sizeof(out) - zs->avail_out;
    if (!zsink_put(sink, out, have)) return 0;
  } while (zs->avail_out == 0);
  return zs->avail_in == 0;
}

SEXP C_write_dsjc(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                  SEXP level_, SEXP path) {
  yyjson_mut_val *root, *rows;
  yyjson_mut_doc *doc = build_doc(meta, columns, data, as_decimal, 0, &root, &rows);

  const int level = INTEGER(level_)[0];
  const yyjson_write_flag flg = YYJSON_WRITE_NOFLAG;
  yyjson_write_err err;

  strbuf out = {NULL, 0, 0};
  zsink sink = {NULL, NULL};
  if (path != R_NilValue && Rf_xlength(path) > 0) {
    const char *p = Rf_translateCharUTF8(STRING_ELT(path, 0));
    sink.fp = fopen(p, "wb");
    if (!sink.fp) { yyjson_mut_doc_free(doc); Rf_error("Could not open '%s' for writing", p); }
  } else {
    sink.buf = &out;
  }

  z_stream zs;
  memset(&zs, 0, sizeof(zs));
  /* 15 window bits selects the zLib wrapper and the 32KB window the
     specification recommends */
  if (deflateInit2(&zs, level, Z_DEFLATED, 15, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
    if (sink.fp) fclose(sink.fp);
    yyjson_mut_doc_free(doc);
    Rf_error("Could not initialise zLib compression");
  }

  int failed = 0;
  const char *failmsg = NULL;
  size_t len = 0;
  char *txt = yyjson_mut_val_write_opts(root, flg, NULL, &len, &err);
  if (!txt) { failed = 1; failmsg = err.msg; }
  else {
    if (!zpush(&zs, &sink, txt, len, Z_NO_FLUSH)) { failed = 1; failmsg = "compression error"; }
    free(txt);
  }

  yyjson_mut_arr_iter rit;
  yyjson_mut_arr_iter_init(rows, &rit);
  yyjson_mut_val *row;
  while (!failed && (row = yyjson_mut_arr_iter_next(&rit)) != NULL) {
    txt = yyjson_mut_val_write_opts(row, flg, NULL, &len, &err);
    if (!txt) { failed = 1; failmsg = err.msg; break; }
    if (!zpush(&zs, &sink, "\n", 1, Z_NO_FLUSH) ||
        !zpush(&zs, &sink, txt, len, Z_NO_FLUSH)) {
      failed = 1; failmsg = "compression error";
    }
    free(txt);
  }
  if (!failed && !zpush(&zs, &sink, "\n", 1, Z_FINISH)) {
    failed = 1; failmsg = "compression error";
  }

  deflateEnd(&zs);
  yyjson_mut_doc_free(doc);

  if (sink.fp) {
    fclose(sink.fp);
    if (failed) Rf_error("Failed to write Dataset JSON Compressed: %s",
                         failmsg ? failmsg : "unknown error");
    return R_NilValue;
  }
  if (failed) { free(out.dat); Rf_error("Failed to build Dataset JSON Compressed: %s",
                                        failmsg ? failmsg : "unknown error"); }

  SEXP res = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t) out.len));
  if (out.len) memcpy(RAW(res), out.dat, out.len);
  free(out.dat);
  UNPROTECT(1);
  return res;
}
