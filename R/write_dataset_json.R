#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting
#'
#' @return NULL when file written to disk, otherwise character string
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
write_dataset_json <- function(x, file, pretty=FALSE) {
  stopifnot_datasetjson(x)

  # Populate the creation datetime
  x[['creationDateTime']] <- get_datetime()

  x <- remove_nulls(x)

  if (!missing(file)) {
    # Make sure the output path exists
    if(!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call.=FALSE)
    }
  }

  # Create the JSON text
  js <- jsonlite::toJSON(
    x,
    dataframe = "values",
    na = "null",
    auto_unbox = TRUE,
    pretty = pretty)

  # Run the validator
  valid <- jsonvalidate::json_validate(js, schema_1_0_0, engine="ajv")

  if (!valid) {
    stop(paste0(c("Dataset JSON file is invalid per the JSON schema. ",
                  "Run datasetjson::validate_dataset_json(",substitute(file),") to see details")),
         call.=FALSE)
  }

  if (!missing(file)) {
    # Write file to disk
    cat(js, "\n", file = file)
  } else {
    # Print to console
    js
  }
}
