# Claude Code Instructions

## Temporary Files

All temporary files created for planning, testing, scratch work, or any other transient purpose must be placed in the `scratch/` directory at the project root. Do not use `/tmp`, system temp directories, or any other location within the project for temporary files.

## Package Structure

### Overview
- **Package**: datasetjson (v0.3.0)
- **Purpose**: Read and write CDISC Dataset JSON files
- **Core object**: `datasetjson` S3 class inheriting from `data.frame` with metadata stored as attributes

### Key R Source Files
- `R/datasetjson.R` - `dataset_json()` constructor. Creates the S3 object with attributes: fileOID, dbLastModifiedDateTime, originator, sourceSystem, studyOID, metaDataVersionOID, metaDataRef, itemGroupOID, name, label, datasetJSONVersion, columns
- `R/write_dataset_json.R` - `write_dataset_json()`. Converts date/time/decimal columns, assembles metadata list, uses `unname(x)` to strip column names so rows serialize as arrays, writes via `yyjsonr::write_json_file/str()`
- `R/read_dataset_json.R` - `read_dataset_json()`. Reads JSON via yyjsonr, extracts `ds_json$rows` as data frame, applies type conversions (integer/float/double/decimal/boolean/date/datetime/time), creates `dataset_json()` object
- `R/validate_dataset_json.R` - `validate_dataset_json()`. Uses `jsonvalidate::json_validate()` with embedded `schema_1_1_0`
- `R/column_metadata.R` - `get_column_metadata()`, `set_variable_attributes()`
- `R/file_metadata.R` - Setter functions for file/dataset metadata attributes
- `R/helpers.R` - `cols_list_to_df()` helper for column metadata
- `R/utils.R` - Internal helpers: `stopifnot_datasetjson()`, `set_col_attr()`, `remove_nulls()`, `path_is_url()`, `read_from_url()`, `df_to_list_rows()`, `date_time_conversions()`
- `R/global.R` - `globalVariables()` declarations
- `R/data.R` - Documentation for `iris_items` and `schema_1_1_0` package data
- `R/zzz.R` - Package initialization

### Dependencies
- **yyjsonr** (>= 0.1.18) - JSON serialization/deserialization
- **jsonvalidate** (>= 1.3.1) - Schema validation
- **hms** - Time handling

### Test Structure
- `tests/testthat/test-datasetjson.R` - Object creation tests
- `tests/testthat/test-write_dataset_json.R` - Write tests (compare against reference JSON, datetime handling, float_as_decimals)
- `tests/testthat/test-read_dataset_json.R` - Read tests
- `tests/testthat/test-validate_dataset_json.R` - Validation tests
- `tests/testthat/test-helpers.R` - Helper function tests
- `tests/testthat/test-utils.R` - Utility function tests
- `tests/testthat/testdata/` - Reference files: dm/ta/ae/adsl as .json, .ndjson, .xpt, plus metadata .Rds files and schema files

### yyjsonr Usage
- **Write**: `opts_write_json(pretty, auto_unbox=TRUE)`, `write_json_file()`, `write_json_str()`
- **Read**: `opts_read_json(promote_num_to_string=TRUE)`, `read_json_file()`, `read_json_str()`
- **Key technique**: `unname(x)` on data frame before nesting in list causes yyjsonr to serialize rows as JSON arrays instead of objects
