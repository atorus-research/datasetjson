#' Validate a Dataset JSON file
#'
#' This function calls `jsonvalidate::json_validate()` directly, with the parameters
#' necessary to retrieve the error information of an invalid JSON file per the
#' Dataset JSON schema.
#'
#' @param x Path to a Dataset JSON file or a character vector holding JSON text
#'
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'   validate_dataset_json('path/to/file.json')
#' }
#'
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
#' js <- write_dataset_json(ds_json)
#'
#' validate_dataset_json(js)
validate_dataset_json <- function(x) {
  v <- jsonvalidate::json_validate(x, schema_1_0_0, engine="ajv", verbose=TRUE)
  if (!v) {
    warning("File contains errors!")
    return(attr(v, 'errors'))
  } else {
    message("File is valid per the Dataset JSON v1.0.0 schema\n")
    data.frame(
      instancePath = character(),
      schemaPath = character(),
      keyword = character(),
      params = character(),
      message = character(),
      schema = character(),
      parentSchema = character(),
      data = list(),
      dataPath = character()
    )
  }
}
