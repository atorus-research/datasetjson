#' Validate a Dataset JSON file
#'
#' This function calls `jsonvalidate::json_validate()` directly, with the
#' parameters necessary to retrieve the error information of an invalid JSON
#' file per the Dataset JSON schema.
#'
#' @param x File path or URL of a Dataset JSON file, or a character vector
#'   holding JSON text
#'
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'   validate_dataset_json('path/to/file.json')
#'   validate_dataset_json('https://www.somesite.com/file.json')
#' }
#'
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' js <- write_dataset_json(ds_json)
#'
#' validate_dataset_json(js)
validate_dataset_json <- function(x) {
  # If contents are a URL then pull out the content
  if (path_is_url(x)) {
    js <- read_from_url(x)
  } else {
    js <- x
  }

  v <- jsonvalidate::json_validate(js, schema_1_1_0, engine="ajv", verbose=TRUE)
  if (!v) {
    warning("File contains errors!")
    return(attr(v, 'errors'))
  } else {
    message("File is valid per the Dataset JSON v1.1.0 schema\n")
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
