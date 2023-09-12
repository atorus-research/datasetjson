#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting
#'
#' @return NULL
#' @export
#'
#' @examples
#' # Write to character object
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
#' js <- write_dataset_json(ds_json)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_json(ds_json, "path/to/file.json")
#' }
write_dataset_json <- function(x, file, pretty=TRUE) {
  stopifnot_datasetjson(x)

  # Populate the as-of datetime
  x[['asOfDateTime']] <- get_datetime()

  if (!missing(file)) {
    # Make sure the output path exists
    if(!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call.=FALSE)
    }

    # Attach the file OID
    x <- set_file_oid(x, tools::file_path_sans_ext(file))
  } else{
    x <- set_file_oid(x, "NA")
  }

  # Create the JSON text
  js <- jsonlite::toJSON(
    x,
    dataframe = "values",
    na = "null",
    auto_unbox = TRUE,
    pretty = pretty)

  # Run the validator
  jsonvalidate::json_validate(js, schema_1_0_0, engine="ajv", error=TRUE)

  if (!missing(file)) {
    # Write file to disk
    cat(js, "\n", file = file)
  } else {
    # Print to console
    js
  }
}
