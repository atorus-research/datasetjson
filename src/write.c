#include "datasetjson.h"
#include "yyjson.h"

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
static void render_decimal(double x, int digits, char *buf, size_t n) {
  if (digits != NA_INTEGER) {
    /* explicit precision: reproduces the historical fixed-digits behaviour */
    snprintf(buf, n, "%.*g", digits, x);
    return;
  }
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
                            int as_decimal, int digits, SEXP levels) {
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
      render_decimal(v, digits, buf, sizeof(buf));
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
 * digits_   integer(1); NA means "shortest representation that round-trips"
 * pretty    logical(1)
 * path      character(1) to write a file, or NULL to return a string
 */
SEXP C_write_dsjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                    SEXP digits_, SEXP pretty, SEXP path) {
  const int digits = INTEGER(digits_)[0];
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
        yyjson_mut_arr_add_val(row, cell(doc, cols[j], i, dec[j] == TRUE, digits, levs[j]));
      }
      yyjson_mut_arr_add_val(rows, row);
    }
    yyjson_mut_obj_add_val(doc, root, "rows", rows);
  }

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
