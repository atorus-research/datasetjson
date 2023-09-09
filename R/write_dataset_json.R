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
#' # TODO:
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

    # Write file to disk
    cat(
      jsonlite::toJSON(
        x,
        dataframe = "values",
        na = "null",
        auto_unbox = TRUE,
        pretty = pretty),
      "\n", file = path
      )
  } else {
    # Untested
    cat(
      jsonlite::toJSON(
        x,
        dataframe = "values",
        na = "null",
        auto_unbox = TRUE,
        pretty = pretty),
      "\n"
      )
  }
}
