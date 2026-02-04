#' Write out a Dataset JSON file in NDJSON format
#'
#' Write a datasetjson object to a newline-delimited JSON (NDJSON) file. Line 1
#' contains the dataset metadata as a JSON object, and each subsequent line
#' contains a single data row as a JSON array.
#'
#' @param x datasetjson object
#' @param file File path to save NDJSON file. If omitted, the NDJSON content is
#'   returned as a character string.
#' @param pretty If TRUE, write the metadata line with readable formatting.
#'   Data row lines are always compact. *Note: The Dataset JSON standard prefers
#'   compressed formatting without line feeds. It is not recommended you use
#'   pretty printing for submission purposes.*
#' @param float_as_decimals If TRUE, Convert float variables to "decimal" data
#'   type in the JSON output. This will manually convert the numeric values
#'   using the `format()` function using the number of digits specified in
#'   `digits`, bypassing the `yyjsonr` handling of float values and writing the
#'   numbers out as JSON character strings. See the [Dataset JSON user
#'   guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding) for more
#'   information. Defaults to FALSE
#' @param digits When using `float_as_decimals`, the number of digits to use
#'   when writing out floats. Going higher than 16 may start writing otherwise
#'   sufficiently precise decimals (i.e. .2) to long strings.
#'
#' @return NULL when file written to disk, otherwise character string
#' @export
#'
#' @examples
#' # Write to character object
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' ndjson <- write_dataset_ndjson(ds_json)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_ndjson(ds_json, "path/to/file.ndjson")
#' }
write_dataset_ndjson <- function(x, file, pretty=FALSE, float_as_decimals=FALSE, digits=16) {

  prepared <- prepare_dataset_for_write(x, float_as_decimals, digits)
  meta <- prepared$meta
  data <- prepared$data

  if (!missing(file)) {
    # Make sure the output path exists
    if(!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call.=FALSE)
    }
  }

  # Line 1: metadata as JSON (no rows)
  meta_opts <- yyjsonr::opts_write_json(
    pretty = pretty,
    auto_unbox = TRUE
  )
  meta_line <- yyjsonr::write_json_str(meta, opts = meta_opts)

  # If pretty printed, collapse to a single line for NDJSON compliance
  if (pretty) {
    meta_line <- paste(trimws(strsplit(meta_line, "\n")[[1]]), collapse = " ")
  } else {
    meta_line <- trimws(meta_line)
  }

  # Lines 2+: each row as a JSON array
  json_opts <- yyjsonr::opts_write_json(auto_unbox = TRUE)
  row_lines <- vapply(seq_len(nrow(data)), function(i) {
    row_data <- unname(as.list(data[i, , drop = FALSE]))
    # Strip AsIs class added by format() to prevent yyjsonr wrapping in arrays
    row_data <- lapply(row_data, function(v) {
      class(v) <- setdiff(class(v), "AsIs")
      v
    })
    trimws(yyjsonr::write_json_str(row_data, opts = json_opts))
  }, character(1))

  all_lines <- c(meta_line, row_lines)

  if (!missing(file)) {
    writeLines(all_lines, file)
  } else {
    paste(all_lines, collapse = "\n")
  }
}
