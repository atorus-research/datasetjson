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

#' Validate a Dataset NDJSON file
#'
#' This function validates the metadata line (line 1) of an NDJSON file against
#' the Dataset NDJSON schema, and checks that each data row is a valid JSON
#' array with the expected number of elements.
#'
#' @param x File path or URL of a Dataset NDJSON file, or a character string
#'   holding NDJSON text
#'
#' @return A data frame
#' @export
#'
#' @examples
#'
#' \dontrun{
#'   validate_dataset_ndjson('path/to/file.ndjson')
#' }
#'
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' ndjson <- write_dataset_ndjson(ds_json)
#'
#' validate_dataset_ndjson(ndjson)
validate_dataset_ndjson <- function(x) {
  # Read lines from source
  if (path_is_url(x)) {
    lines <- read_from_url(x)
  } else if (file.exists(x)) {
    lines <- readLines(x, warn = FALSE)
  } else {
    lines <- strsplit(x, "\n")[[1]]
  }

  # Remove empty trailing lines
  lines <- lines[nzchar(trimws(lines))]

  if (length(lines) == 0) {
    warning("File contains errors!")
    return(data.frame(
      line = 1L,
      message = "File is empty",
      stringsAsFactors = FALSE
    ))
  }

  # Validate line 1 (metadata) by injecting an empty rows array into the raw

  # JSON string, then validating against the standard Dataset JSON schema.
  # This avoids parsing/re-serializing which loses integer type info.
  meta_line <- trimws(lines[1])

  # Verify it's valid JSON first
  meta <- tryCatch(
    yyjsonr::read_json_str(meta_line),
    error = function(e) NULL
  )

  if (is.null(meta)) {
    warning("Metadata line contains errors!")
    return(data.frame(
      line = 1L,
      message = "Line 1: Invalid JSON",
      stringsAsFactors = FALSE
    ))
  }

  # Inject empty rows array into raw JSON string for schema validation
  meta_as_json <- sub("\\}\\s*$", ",\"rows\":[]}", meta_line)

  v <- jsonvalidate::json_validate(meta_as_json, schema_1_1_0, engine="ajv", verbose=TRUE)
  if (!v) {
    warning("Metadata line contains errors!")
    return(attr(v, 'errors'))
  }

  # Get expected column count from metadata
  # columns is parsed as a data.frame, so use nrow
  expected_cols <- if (is.data.frame(meta$columns)) nrow(meta$columns) else length(meta$columns)

  # Validate data lines
  data_lines <- lines[-1]
  errors <- character()

  for (i in seq_along(data_lines)) {
    parsed <- tryCatch(
      yyjsonr::read_json_str(data_lines[i]),
      error = function(e) NULL
    )
    if (is.null(parsed)) {
      errors <- c(errors, sprintf("Line %d: Invalid JSON", i + 1))
    } else if (length(parsed) != expected_cols) {
      errors <- c(errors, sprintf("Line %d: Expected %d values, got %d",
                                   i + 1, expected_cols, length(parsed)))
    }
  }

  if (length(errors) > 0) {
    warning("File contains errors!")
    return(data.frame(
      line = seq_along(errors),
      message = errors,
      stringsAsFactors = FALSE
    ))
  }

  message("File is valid per the Dataset NDJSON v1.1.0 schema\n")
  data.frame(
    line = integer(),
    message = character(),
    stringsAsFactors = FALSE
  )
}
