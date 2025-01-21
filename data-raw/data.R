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
# adsl$VISIT1TM <- lubridate::hms(adsl$VIST1TMC)
adsl$VIST1DTM <- strptime(adsl$VIST1DTC, "%Y-%m-%dT%H:%M:%S")

new_meta <- tibble::tribble(
  ~itemOID,             ~name,          ~label,             ~dataType, ~length,      ~targetDataType, ~displayFormat, ~keySequence,
  'IT.ADSL.VIST1TMC',   'VIST1TMC',     'Visit 1 Time',     'string',   8L,          NA_character_,   NA_character_,  NA_integer_,
  'IT.ADSL.VIST1DTC',   'VIST1DTC',     'Visit 1 Datetime', 'string',   19L,         NA_character_,   NA_character_,  NA_integer_,
  # 'IT.ADSL.VISIT1TM',   'VISIT1TM',     'Numeric time',     'time',     NA_integer_, "integer",       "TIME8",        NA_integer_,
  'IT.ADSL.VIST1DTM',   'VIST1DTM',     'Numeric datetime', 'datetime', NA_integer_, "integer",      "E8601DT",       NA_integer_
)

adsl_meta <- readRDS(testthat::test_path("testdata", "adsl_metadata.Rds")) |>
  dplyr::bind_rows(
    new_meta
  )

saveRDS(adsl, file=testthat::test_path("testdata", "adsl_time_test.Rds"))
saveRDS(new_meta, file=testthat::test_path("testdata", "adsl_time_test_meta.Rds"))
