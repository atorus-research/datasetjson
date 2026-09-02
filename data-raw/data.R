devtools::load_all()

## code to prepare `iris_items` dataset
iris_items <- tibble::tribble(
  ~itemOID,             ~name,          ~label,           ~dataType, ~length,    ~keySequence,
  'IT.IR.Sepal.Length', 'Sepal.Length', 'Sepal Length',   'float',   NA_integer_, 2L,
  'IT.IR.Sepal.Width',  'Sepal.Width',  'Sepal Width',    'float',   NA_integer_, NA_integer_,
  'IT.IR.Petal.Length', 'Petal.Length', 'Petal Length',   'float',   NA_integer_, 3L,
  'IT.IR.Petal.Width',  'Petal.Width',  'Petal Width',    'float',   NA_integer_, NA_integer_,
  'IT.IR.Species',      'Species',      'Flower Species', 'string',  10L,         1L
)

usethis::use_data(iris_items, overwrite = TRUE)

# List form of iris_items once converted to Dataset JSON list
iris_items_list <- list(
  list(
    itemOID = 'IT.IR.Sepal.Length',
    name = 'Sepal.Length',
    label = 'Sepal Length',
    dataType = 'float',
    keySequence = 2L
  ),
  list(
    itemOID = 'IT.IR.Sepal.Width',
    name = 'Sepal.Width',
    label = 'Sepal Width',
    dataType = 'float'
  ),
  list(
    itemOID = 'IT.IR.Petal.Length',
    name = 'Petal.Length',
    label = 'Petal Length',
    dataType = 'float',
    keySequence = 3L
  ),
  list(
    itemOID = 'IT.IR.Petal.Width',
    name = 'Petal.Width',
    label = 'Petal Width',
    dataType = 'float'
  ),
  list(
    itemOID = 'IT.IR.Species',
    name = 'Species',
    label = 'Flower Species',
    dataType = 'string',
    length = 10L,
    keySequence = 1L
  )
)

saveRDS(iris_items_list, file=testthat::test_path("testdata", "iris_items_list.Rds"))

# code to prepare `iris_items_bad` used for unit tests
iris_items_bad <- tibble::tribble(
  ~itemOID,             ~name, ~bad_col,           ~dataType,   ~length,       ~keySequence,
  'IT.IR.Sepal.Length', 1,     'Sepal Length',     'numeric',   NA_integer_,   2,
  'IT.IR.Sepal.Width',  2,     'Sepal Width',      'float',     NA_integer_,   NA,
  'IT.IR.Petal.Length', 3,     'Petal Length',     'float',     NA_integer_,   3,
  'IT.IR.Petal.Width',  4,     'Petal Width',      'float',     NA_integer_,   NA,
  NA_character_,        5,     'Flower Species',   'character', 10L,           1,
)

saveRDS(iris_items_list, file=testthat::test_path("testdata", "iris_items_bad.Rds"))

# Dataset JSON Schema V1.0.0 as Character Vector
schema_file <- testthat::test_path("testdata", "dataset.schema.json")
schema_1_1_0 = readChar(schema_file, file.info(schema_file)$size)
usethis::use_data(schema_1_1_0, overwrite=TRUE)

# Dataset NDJSON Schema V1.1.0 as Character Vector
#
# Two things need fixing up before this schema is usable:
#   1. The source file is UTF-16LE encoded with a BOM.
#   2. It references "#/$defs/Column", "#/$defs/DataTypesEnum" and
#      "#/$defs/SourceSystem", none of which are in $defs - each definition is
#      instead nested inside the object that references it. ajv refuses to
#      compile the schema as shipped. We hoist the nested copies into $defs so
#      the references resolve; the content itself is unchanged.
ndjson_schema_file <- testthat::test_path("testdata", "dataset-ndjson-schema.json")
ndjson_schema_raw <- paste(
  system2("iconv", c("-f", "UTF-16LE", "-t", "UTF-8", ndjson_schema_file), stdout = TRUE),
  collapse = "\n"
)
ndjson_schema_raw <- sub("^\uFEFF", "", ndjson_schema_raw)

.ndjson_schema <- jsonlite::fromJSON(ndjson_schema_raw, simplifyVector = FALSE)

# every "#/$defs/<name>" the schema refers to
.collect_refs <- function(x, acc = character()) {
  if (!is.list(x)) return(acc)
  if (!is.null(x[["$ref"]])) acc <- c(acc, x[["$ref"]])
  for (el in x) acc <- .collect_refs(el, acc)
  acc
}
# the first definition of <name> found anywhere in the tree
.find_def <- function(x, nm) {
  if (!is.list(x)) return(NULL)
  if (!is.null(x[[nm]]) && is.list(x[[nm]])) return(x[[nm]])
  for (el in x) {
    hit <- .find_def(el, nm)
    if (!is.null(hit)) return(hit)
  }
  NULL
}

.prefix <- "#/$defs/"
.wanted <- unique(sub(.prefix, "",
  grep(.prefix, .collect_refs(.ndjson_schema), value = TRUE, fixed = TRUE),
  fixed = TRUE))
for (.nm in setdiff(.wanted, names(.ndjson_schema[["$defs"]]))) {
  .def <- .find_def(.ndjson_schema, .nm)
  if (is.null(.def)) stop("No definition found for ", .nm, " in the NDJSON schema")
  .ndjson_schema[["$defs"]][[.nm]] <- .def
}
# the columns array now resolves through $defs rather than an inline copy
.ndjson_schema[["$defs"]]$DatasetMetadata$properties$columns$items <-
  list(`$ref` = "#/$defs/Column")

schema_ndjson_1_1_0 <- as.character(
  jsonlite::toJSON(.ndjson_schema, auto_unbox = TRUE, null = "null")
)
stopifnot(!inherits(
  try(jsonvalidate::json_validate("{}", schema_ndjson_1_1_0, engine = "ajv"), silent = TRUE),
  "try-error"
))
usethis::use_data(schema_ndjson_1_1_0, overwrite = TRUE)

# Example files shipped in inst/extdata for datasetjson_example()
#
# dm.json is the CDISC-published Dataset JSON example. The compressed form is
# generated from it so the three representations stay in step.
dm_example <- read_dataset_json(
  system.file("extdata", "dm.json", package = "datasetjson")
)
write_dataset_dsjc(dm_example, file.path("inst", "extdata", "dm.dsjc"))

# Test data metadata

save_metadata <- function(df) {
  .data <- read_dataset_json(testthat::test_path("testdata", sprintf("%s.json", df)))
  .data_metadata <- purrr::map_df(attributes(.data)$columns, as.data.frame)
  saveRDS(.data_metadata, testthat::test_path("testdata", sprintf("%s_metadata.Rds", df)))
}

save_metadata("ae")
save_metadata("dm")
save_metadata("ta")
save_metadata("adsl")

# Time type ----
adsl <- haven::read_xpt(testthat::test_path("testdata", "adsl.xpt"))

time_options <- c("12:34:56", "15:34:34", "11:12:52", "21:16:11")

adsl$VIST1TMC <- sample(time_options, 254, replace=TRUE)
adsl$VIST1DTC <-paste(format(adsl$VISIT1DT, "%Y-%m-%d"), sample(time_options, 254, replace=TRUE), sep="T")
adsl$VISIT1TM <- hms::as_hms(adsl$VIST1TMC)
adsl$VIST1DTM <- as.POSIXct(strptime(adsl$VIST1DTC, "%Y-%m-%dT%H:%M:%S", tz="UTC"))

new_meta <- tibble::tribble(
  ~itemOID,             ~name,          ~label,             ~dataType, ~length,      ~targetDataType, ~displayFormat, ~keySequence,
  'IT.ADSL.VIST1TMC',   'VIST1TMC',     'Visit 1 Time',     'date',   8L,          NA_character_,   NA_character_,  NA_integer_,
  'IT.ADSL.VIST1DTC',   'VIST1DTC',     'Visit 1 Datetime', 'datetime',   19L,         NA_character_,   NA_character_,  NA_integer_,
  'IT.ADSL.VISIT1TM',   'VISIT1TM',     'Numeric time',     'time',     NA_integer_, "integer",       "TIME8",        NA_integer_,
  'IT.ADSL.VIST1DTM',   'VIST1DTM',     'Numeric datetime', 'datetime', NA_integer_, "integer",      "E8601DT",       NA_integer_
)

adsl_meta <- readRDS(testthat::test_path("testdata", "adsl_metadata.Rds")) |>
  dplyr::bind_rows(
    new_meta
  )

saveRDS(adsl, file=testthat::test_path("testdata", "adsl_time_test.Rds"))
saveRDS(adsl_meta, file=testthat::test_path("testdata", "adsl_time_test_meta.Rds"))
