#' Read a Dataset NDJSON file to a datasetjson object
#'
#' Reads a newline-delimited JSON (NDJSON) file following the Dataset JSON
#' v1.1.0 specification. Line 1 of the file holds the dataset metadata and each
#' subsequent line holds one data row as a JSON array.
#'
#' @details
#'
#' NDJSON and JSON representations of Dataset JSON carry the same content, so
#' the object returned here is the same as the one `read_dataset_json()`
#' returns for the equivalent `.json` file, including all of the metadata
#' attached as attributes. See `read_dataset_json()` for the full list.
#'
#' @param file File path or URL of a Dataset NDJSON file, or a character string
#'   containing the NDJSON content itself
#'
#' @return A dataframe with additional attributes attached containing the
#'   DatasetJSON metadata.
#' @export
#'
#' @examples
#' # Read one of the example files shipped with the package
#' dm <- read_dataset_ndjson(datasetjson_example("dm.ndjson"))
#'
#' # Or from NDJSON text held in memory
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' dat <- read_dataset_ndjson(write_dataset_ndjson(ds_json))
read_dataset_ndjson <- function(file) {
  if (path_is_url(file)) {
    parsed <- .Call(C_read_dsndjson_str, read_from_url(file))
  } else if (
    length(file) == 1 && !any(grepl("\n", file, fixed = TRUE)) && file.exists(file)
  ) {
    parsed <- .Call(C_read_dsndjson_file, file)
  } else {
    parsed <- .Call(C_read_dsndjson_str, paste(file, collapse = "\n"))
  }

  build_datasetjson(parsed)
}
