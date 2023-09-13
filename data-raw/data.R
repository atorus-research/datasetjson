## code to prepare `iris_items` dataset
iris_items <- tibble::tribble(
  ~OID,                 ~name,          ~label,           ~type,    ~length,     ~displayFormat, ~keySequence,
  'IT.IR.Sepal.Length', 'Sepal.Length', 'Sepal Length',   'float',  NA_integer_, NA_character_,  2L,
  'IT.IR.Sepal.Width',  'Sepal.Width',  'Sepal Width',    'float',  NA_integer_, NA_character_,  NA_integer_,
  'IT.IR.Petal.Length', 'Petal.Length', 'Petal Length',   'float',  NA_integer_, NA_character_,  3L,
  'IT.IR.Petal.Width',  'Petal.Width',  'Petal Width',    'float',  NA_integer_, NA_character_,  NA_integer_,
  'IT.IR.Species',      'Species',      'Flower Species', 'string', 10L,         NA_character_, 1L
)

usethis::use_data(iris_items, overwrite = TRUE)

# List form of iris_items once converted to Dataset JSON list
iris_items_list <- list(
  list(
    OID  = 'ITEMGROUPDATASEQ',
    name = 'ITEMGROUPDATASEQ',
    label = 'Record Identifier',
    type = 'integer'
  ),
  list(
    OID = 'IT.IR.Sepal.Length',
    name = 'Sepal.Length',
    label = 'Sepal Length',
    type = 'float',
    keySequence = 2L
  ),
  list(
    OID = 'IT.IR.Sepal.Width',
    name = 'Sepal.Width',
    label = 'Sepal Width',
    type = 'float'
  ),
  list(
    OID = 'IT.IR.Petal.Length',
    name = 'Petal.Length',
    label = 'Petal Length',
    type = 'float',
    keySequence = 3L
  ),
  list(
    OID = 'IT.IR.Petal.Width',
    name = 'Petal.Width',
    label = 'Petal Width',
    type = 'float'
  ),
  list(
    OID = 'IT.IR.Species',
    name = 'Species',
    label = 'Flower Species',
    type = 'string',
    length = 10L,
    keySequence = 1L
  )
)

# code to prepare `iris_items_bad` used for unit tests
iris_items_bad <- tibble::tribble(
  ~OID,                 ~name, ~bad_col,           ~type,      ~length,       ~keySequence,
  'IT.IR.Sepal.Length', 1,     'Sepal Length',     'numeric',   NA_integer_,   2,
  'IT.IR.Sepal.Width',  2,     'Sepal Width',      'float',     NA_integer_,   NA,
  'IT.IR.Petal.Length', 3,     'Petal Length',     'float',     NA_integer_,   3,
  'IT.IR.Petal.Width',  4,     'Petal Width',      'float',     NA_integer_,   NA,
  NA_character_,        5,     'Flower Species',   'character', 10L,           1,
)

# Code for SAS date formats
sas_date_formats <- c(
  'DATE.',
  'DATE9.',
  'DAY.',
  'DDMMYY.',
  'DDMMYY10.',
  'DDMMYYB.',
  'DDMMYYB10.',
  'DDMMYYC.',
  'DDMMYYC10.',
  'DDMMYYD.',
  'DDMMYYD10.',
  'DDMMYYN6.',
  'DDMMYYN8.',
  'DDMMYYP.',
  'DDMMYYP10.',
  'DDMMYYS.',
  'DDMMYYS10.',
  'DOWNAME.',
  'JULIAN.',
  'MMDDYY.',
  'MMDDYY10.',
  'MMDDYYB.',
  'MMDDYYB10.',
  'MMDDYYC.',
  'MMDDYYC10.',
  'MMDDYYD.',
  'MMDDYYD10.',
  'MMDDYYN6.',
  'MMDDYYN8.',
  'MMDDYYP.',
  'MMDDYYP10.',
  'MMDDYYS.',
  'MMDDYYS10.',
  'MMYY.',
  'MMYYC.',
  'MMYYD.',
  'MMYYN.',
  'MMYYP.',
  'MMYYS.',
  'MONNAME.',
  'MONTH.',
  'MONYY.',
  'WEEKDATE.',
  'WEEKDATX',
  'WEEKDAY.'
)

usethis::use_data(sas_date_formats, overwrite = TRUE)

# Code for SAS datetime formats
sas_datetime_formats <- c(
  'DATEAMPM.',
  'DATETIME.',
  'DTDATE.',
  'DTMONYY.',
  'DTWKDATX.',
  'DTYEAR.',
  'DTYYQC.'
)

usethis::use_data(sas_datetime_formats, overwrite = TRUE)

# Code for SAS time formats
sas_time_formats <- c(
  'HOUR.',
  'TIME.',
  'TIMEAMPM.',
  'TOD.'
)
usethis::use_data(sas_time_formats, overwrite = TRUE)

# Dataset JSON Schema V1.0.0 as Character Vector
schema_file <- test_path("testdata", "dataset.schema.json")
schema_1_0_0 = readChar(schema_file, file.info(schema_file)$size)
usethis::use_data(schema_1_0_0, overwrite=TRUE)
