## code to prepare `iris_items` dataset goes here
iris_items <- tibble::tribble(
  ~OID,                 ~name,          ~label,           ~type,   ~length,       ~keySequence, ~displayFormat,
  "IT.IR.Sepal.Length", "Sepal.Length", "Sepal Length",   "float", NA_integer_, 2L,           NA_character_,
  "IT.IR.Sepal.Width",  "Sepal.Width",  "Sepal Width",    "float", NA_integer_, NA_integer_,  NA_character_,
  "IT.IR.Petal.Length", "Petal.Length", "Petal Length",   "float", NA_integer_, 3L,           NA_character_,
  "IT.IR.Petal.Width",  "Petal.Width",  "Petal Width",    "float", NA_integer_, NA_integer_,  NA_character_,
  "IT.IR.Species",      "Species",      "Flower Species", "string", 10L,         1L,           NA_character_
)

usethis::use_data(iris_items, overwrite = TRUE)
