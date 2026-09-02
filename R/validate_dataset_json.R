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
#' # Validate a file on disk
#' validate_dataset_json(datasetjson_example("dm.json"))
#'
#' # Validate from a URL
#' \dontrun{
#'   validate_dataset_json('https://www.somesite.com/file.json')
#' 
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
#'}
validate_dataset_json <- function(x) {
  # If contents are a URL then pull out the content
  if (path_is_url(x)) {
    js <- read_from_url(x)
  } else {
    js <- x
  }

  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    stop(
      "Package 'jsonvalidate' is required for this function. ",
      "Install it with install.packages('jsonvalidate')",
      call. = FALSE
    )
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

#' Validate a Dataset NDJSON file
#'
#' Checks a Dataset NDJSON file in two parts, matching how the format is
#' structured: the metadata object on line 1 is validated against the Dataset
#' NDJSON v1.1.0 schema, and each subsequent line is checked to be a JSON array
#' carrying one value per declared column.
#'
#' @param x File path or URL of a Dataset NDJSON file, or a character vector
#'   holding the NDJSON text
#'
#' @return A data frame of errors, empty when the file is valid
#' @export
#'
#' @examples
#' # Validate a file on disk
#' validate_dataset_ndjson(datasetjson_example("dm.ndjson"))
#'
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#'
#' validate_dataset_ndjson(write_dataset_ndjson(ds_json))
validate_dataset_ndjson <- function(x) {
  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    stop(
      "Package 'jsonvalidate' is required for this function. ",
      "Install it with install.packages('jsonvalidate')",
      call. = FALSE
    )
  }

  if (path_is_url(x)) {
    lines <- strsplit(read_from_url(x), "\n")[[1]]
  } else if (length(x) == 1 && !any(grepl("\n", x, fixed = TRUE)) && file.exists(x)) {
    lines <- readLines(x, warn = FALSE)
  } else {
    lines <- unlist(strsplit(x, "\n"))
  }

  lines <- lines[nzchar(trimws(lines))]

  no_errors <- data.frame(line = integer(), message = character())

  if (length(lines) == 0) {
    warning("File contains errors!")
    return(data.frame(line = 1L, message = "File is empty"))
  }

  # Line 1: the metadata object. The NDJSON schema describes exactly this
  # object, so it is validated directly rather than reconstructed as JSON.
  v <- jsonvalidate::json_validate(
    lines[1], schema_ndjson_1_1_0, engine = "ajv", verbose = TRUE
  )
  if (!v) {
    warning("File contains errors!")
    return(attr(v, "errors"))
  }

  # Lines 2+: one array per row, one value per column
  shape <- .Call(C_ndjson_shape, lines)
  ncol <- shape$ncol
  lens <- shape$lengths

  bad <- which(is.na(lens) | lens != ncol)
  if (length(bad)) {
    msg <- ifelse(
      is.na(lens[bad]),
      "Invalid JSON",
      ifelse(
        lens[bad] < 0,
        "Line is not an array of values",
        sprintf("Expected %d values, got %d", ncol, lens[bad])
      )
    )
    warning("File contains errors!")
    return(data.frame(line = bad + 1L, message = msg))
  }

  message("File is valid per the Dataset NDJSON v1.1.0 schema\n")
  no_errors
}
