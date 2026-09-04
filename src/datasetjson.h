#ifndef DATASETJSON_H
#define DATASETJSON_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

SEXP C_read_dsjson_file(SEXP path_);
SEXP C_read_dsjson_str(SEXP txt_);
SEXP C_read_dsndjson_file(SEXP path_);
SEXP C_read_dsndjson_str(SEXP txt_);
SEXP C_ndjson_shape(SEXP lines_);
SEXP C_read_dsjc_file(SEXP path_);
SEXP C_read_dsjc_raw(SEXP raw_);
SEXP C_write_dsjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                    SEXP pretty, SEXP path);
SEXP C_write_dsndjson(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                      SEXP path);
SEXP C_write_dsjc(SEXP meta, SEXP columns, SEXP data, SEXP as_decimal,
                  SEXP level_, SEXP path);

#endif
