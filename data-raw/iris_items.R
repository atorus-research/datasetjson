## code to prepare `iris_items` dataset goes here
iris_items <- tibble::tribble(
  ~OID,                 ~name,          ~label,           ~type,    ~length,     ~keySequence, ~displayFormat,
  "IT.IR.Sepal.Length", "Sepal.Length", "Sepal Length",   "float",  NA_integer_, 2L,           NA_character_,
  "IT.IR.Sepal.Width",  "Sepal.Width",  "Sepal Width",    "float",  NA_integer_, NA_integer_,  NA_character_,
  "IT.IR.Petal.Length", "Petal.Length", "Petal Length",   "float",  NA_integer_, 3L,           NA_character_,
  "IT.IR.Petal.Width",  "Petal.Width",  "Petal Width",    "float",  NA_integer_, NA_integer_,  NA_character_,
  "IT.IR.Species",      "Species",      "Flower Species", "string", 10L,         1L,           NA_character_
)

usethis::use_data(iris_items, overwrite = TRUE)

# List form of iris_items once converted to Dataset JSON list
iris_items_list <- list(
  list(
    OID  = "ITEMGROUPDATASEQ",
    name = "ITEMGROUPDATASEQ",
    label = "Record Identifier",
    type = "integer"
  ),
  list(
    OID = "IT.IR.Sepal.Length",
    name = "Sepal.Length",
    label = "Sepal Length",
    type = "float",
    keySequence = 2L
  ),
  list(
    OID = "IT.IR.Sepal.Width",
    name = "Sepal.Width",
    label = "Sepal Width",
    type = "float"
  ),
  list(
    OID = "IT.IR.Petal.Length",
    name = "Petal.Length",
    label = "Petal Length",
    type = "float",
    keySequence = 3L
  ),
  list(
    OID = "IT.IR.Petal.Width",
    name = "Petal.Width",
    label = "Petal Width",
    type = "float"
  ),
  list(
    OID = "IT.IR.Species",
    name = "Species",
    label = "Flower Species",
    type = "string",
    length = 10L,
    keySequence = 1L
  )
)

# code to prepare `iris_items_bad` used for unit tests
iris_items_bad <- tibble::tribble(
  ~OID,                 ~name, ~bad_col,           ~type,      ~length,       ~keySequence,
  "IT.IR.Sepal.Length", 1,     "Sepal Length",     "numeric",   NA_integer_,   2,
  "IT.IR.Sepal.Width",  2,     "Sepal Width",      "float",     NA_integer_,   NA,
  "IT.IR.Petal.Length", 3,     "Petal Length",     "float",     NA_integer_,   3,
  "IT.IR.Petal.Width",  4,     "Petal Width",      "float",     NA_integer_,   NA,
  NA_character_,        5,     "Flower Species",   "character", 10L,           1,
)
