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
