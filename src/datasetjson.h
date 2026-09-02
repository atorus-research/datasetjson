#ifndef DATASETJSON_H
#define DATASETJSON_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

SEXP C_read_dsjson_file(SEXP path_);
SEXP C_read_dsjson_str(SEXP txt_);
SEXP C_write_dsjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                    SEXP digits_, SEXP pretty, SEXP path);

#endif
