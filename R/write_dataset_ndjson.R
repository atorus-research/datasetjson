#' Write out a Dataset NDJSON file
#'
#' Writes the newline-delimited JSON representation of Dataset JSON: the
#' dataset metadata as a single JSON object on line 1, then one JSON array per
#' data row. The content is identical to what `write_dataset_json()` produces;
#' only the framing differs, which is what makes NDJSON straightforward to
#' stream a row at a time.
#'
#' @param x datasetjson object
#' @param file File path to save the Dataset NDJSON file. If not provided, the
#'   NDJSON is returned as a character string.
#' @param float_as_decimals If TRUE, write float variables as "decimal" data
#'   types, serialized as JSON strings rather than numbers. This is an
#'   interoperability choice; it is not needed for precision, as numbers are
#'   written at full precision either way, and setting it raises a warning to
#'   that effect.
#' @param digits Deprecated and ignored. Decimals are written at
#'   whatever precision reads back as the same value, so there is no precision
#'   for this argument to control. It is ignored, and supplying it warns.
#'
#' @return NULL when writing to a file, otherwise a character string
#' @export
#'
#' @examples
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' nd <- write_dataset_ndjson(ds_json)
#'
#' # Write to disk
#' write_dataset_ndjson(ds_json, tempfile(fileext = ".ndjson"))
write_dataset_ndjson <- function(
  x,
  file,
  float_as_decimals = FALSE,
  digits = NULL
) {
  prepared <- prepare_dataset_for_write(x, float_as_decimals, digits)

  if (!missing(file)) {
    if (!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call. = FALSE)
    }
  }

  .Call(
    C_write_dsndjson,
    prepared$meta,
    prepared$columns,
    prepared$data,
    prepared$as_decimal,
    if (missing(file)) NULL else file
  )
}
