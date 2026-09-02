#' Write out a Dataset JSON Compressed (DSJC) file
#'
#' Writes the compressed representation of Dataset JSON: the Dataset NDJSON
#' content of the dataset, compressed as a zLib stream. The format carries no
#' wrapper of its own - the file is the zLib stream and nothing else - and uses
#' the `.dsjc` extension.
#'
#' @details
#'
#' Rows are compressed as they are serialized, so writing a large dataset never
#' holds its uncompressed NDJSON in memory.
#'
#' The default `level = 9` follows the specification's recommendation for data
#' exchange. Note that the top of the range buys little: on a 26 MB dataset,
#' level 1 wrote in a fifth of the time for a file only 4% larger. If write
#' time matters more than the last few percent, a lower level is a reasonable
#' choice. Read time is unaffected by the level used to write.
#'
#' @param x datasetjson object
#' @param file File path to save the DSJC file. If not provided, the compressed
#'   bytes are returned as a raw vector.
#' @param float_as_decimals If TRUE, write float variables as "decimal" data
#'   types. This is an interoperability choice; it is not needed for precision,
#'   as numbers are written at full precision either way, and setting it raises
#'   a warning to that effect.
#' @param level zLib compression level, 0 (none) to 9 (maximum). Defaults to 9,
#'   which the specification recommends for data exchange. Lower levels
#'   compress faster and less.
#' @param digits Deprecated and ignored. See `write_dataset_json()`.
#'
#' @return NULL when writing to a file, otherwise a raw vector
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
#' bytes <- write_dataset_dsjc(ds_json)
#'
#' # Write to disk
#' write_dataset_dsjc(ds_json, tempfile(fileext = ".dsjc"))
write_dataset_dsjc <- function(
  x,
  file,
  float_as_decimals = FALSE,
  level = 9L,
  digits = NULL
) {
  if (!is.numeric(level) || length(level) != 1 || is.na(level) ||
      level < 0 || level > 9) {
    stop("`level` must be a single number between 0 and 9", call. = FALSE)
  }

  prepared <- prepare_dataset_for_write(x, float_as_decimals, digits)

  if (!missing(file)) {
    if (!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call. = FALSE)
    }
  }

  .Call(
    C_write_dsjc,
    prepared$meta,
    prepared$columns,
    prepared$data,
    prepared$as_decimal,
    as.integer(level),
    if (missing(file)) NULL else file
  )
}

#' Read a Dataset JSON Compressed (DSJC) file to a datasetjson object
#'
#' Reads the compressed representation of Dataset JSON: a zLib stream holding
#' Dataset NDJSON content. The object returned is the same one
#' `read_dataset_json()` and `read_dataset_ndjson()` return for the equivalent
#' uncompressed file, metadata attributes included.
#'
#' @param file File path or URL of a DSJC file, or a raw vector holding the
#'   compressed bytes
#'
#' @return A dataframe with additional attributes attached containing the
#'   DatasetJSON metadata.
#' @export
#'
#' @examples
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", columns = iris_items)
#' bytes <- write_dataset_dsjc(ds_json)
#' dat <- read_dataset_dsjc(bytes)
read_dataset_dsjc <- function(file) {
  if (is.raw(file)) {
    parsed <- .Call(C_read_dsjc_raw, file)
  } else if (path_is_url(file)) {
    stop(
      "Reading DSJC from a URL is not supported yet; download the file first.",
      call. = FALSE
    )
  } else if (length(file) == 1 && file.exists(file)) {
    parsed <- .Call(C_read_dsjc_file, file)
  } else {
    stop("`file` must be a path to an existing file or a raw vector",
         call. = FALSE)
  }

  build_datasetjson(parsed)
}

#' Validate a Dataset JSON Compressed (DSJC) file
#'
#' Decompresses the zLib stream and validates the Dataset NDJSON content it
#' holds, as `validate_dataset_ndjson()` does: the metadata object on line 1 is
#' checked against the Dataset NDJSON v1.1.0 schema, and each subsequent line
#' must be a JSON array carrying one value per declared column.
#'
#' @param x File path of a DSJC file, or a raw vector holding the compressed
#'   bytes
#'
#' @return A data frame of errors, empty when the file is valid
#' @export
#'
#' @examples
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", columns = iris_items)
#' validate_dataset_dsjc(write_dataset_dsjc(ds_json))
validate_dataset_dsjc <- function(x) {
  if (is.raw(x)) {
    bytes <- x
  } else if (length(x) == 1 && !is.raw(x) && file.exists(x)) {
    bytes <- readBin(x, "raw", file.size(x))
  } else {
    stop("`x` must be a path to an existing file or a raw vector", call. = FALSE)
  }

  txt <- tryCatch(
    rawToChar(memDecompress(bytes, type = "gzip")),
    error = function(e) NULL
  )
  if (is.null(txt)) {
    warning("File contains errors!")
    return(data.frame(
      line = NA_integer_,
      message = "Content is not a valid zLib compressed stream"
    ))
  }

  validate_dataset_ndjson(txt)
}
