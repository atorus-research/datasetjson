#include "datasetjson.h"
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

static const R_CallMethodDef CallEntries[] = {
  {"C_read_dsjson_file", (DL_FUNC) &C_read_dsjson_file, 1},
  {"C_read_dsjson_str",  (DL_FUNC) &C_read_dsjson_str,  1},
  {"C_read_dsndjson_file", (DL_FUNC) &C_read_dsndjson_file, 1},
  {"C_read_dsndjson_str",  (DL_FUNC) &C_read_dsndjson_str,  1},
  {"C_ndjson_shape",     (DL_FUNC) &C_ndjson_shape,     1},
  {"C_write_dsjson",     (DL_FUNC) &C_write_dsjson,     7},
  {"C_write_dsndjson",   (DL_FUNC) &C_write_dsndjson,   6},
  {NULL, NULL, 0}
};

void attribute_visible R_init_datasetjson(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
