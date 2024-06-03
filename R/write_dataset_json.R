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
  json_opts <- yyjsonr::opts_write_json(
    pretty = pretty,
    auto_unbox = TRUE,
  )

  if (!missing(file)) {
    # Write file to disk
    yyjsonr::write_json_file(
      x,
      filename = file,
      opts = json_opts
    )
  } else {
    # Print to console
    yyjsonr::write_json_str(
      x,
      opts = json_opts
    )
  }
}
