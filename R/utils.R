#' Prepare a datasetjson object for writing
#'
#' Shared logic for write_dataset_json and write_dataset_ndjson. Validates the
#' input, converts date/time/decimal columns, and assembles the metadata list.
#'
#' @param x datasetjson object
#' @param float_as_decimals If TRUE, convert float variables to decimal
#' @param digits Number of digits for decimal conversion
#'
#' @return A list with elements `meta` (ordered metadata list) and `data`
#'   (converted data frame)
#' @noRd
prepare_dataset_for_write <- function(x, float_as_decimals = FALSE, digits = 16) {
  stopifnot_datasetjson(x)

  meta <- attributes(x)

  # Find all date, datetime and time columns and convert to character
  for (i in seq_along(meta$columns)) {

    y <- meta$columns[[i]]

    # Make sure metadata is compliant
    if (y$dataType %in% c("date", "datetime", "time") & !("targetDataType" %in% names(y))) {
      if (!inherits(x[[y$name]], "character")) {
        stop_write_error(
          y$name,
          "If dataType is date, time, or datetime and targetDataType is null, the input variable type must be character"
        )
      }
    }

    if(y$dataType %in% c("date", "datetime", "time") & (!is.null(y$targetDataType) && y$targetDataType == "integer")) {
      # Convert date
      if (y$dataType == "date") {
        x[y$name] <- format(x[[y$name]], "%Y-%m-%d", tz='UTC')
      }

      # Convert datetime
      if (y$dataType == "datetime") {
        # Ensure type and timezone is right.
        if (!inherits(x[[y$name]], "POSIXt") || !("UTC" %in% attr(x[[y$name]], 'tzone'))){
          stop_write_error(y$name, "Date time variable must be provided as POSIXlt type with timezone set to UTC.")
        }
        x[y$name] <- strftime(x[[y$name]], "%Y-%m-%dT%H:%M:%S", tz='UTC')
      }

      # Convert time
      if (y$dataType == "time") {
        if (y$dataType == "time" & !inherits(x[[y$name]], c("Period", "difftime", "ITime"))) {
          stop_write_error(
            y$name,
            "If dataType is time and targetDataType is integer, the input variable type must be a lubridate Period, an hms difftime, or a data.table ITime object"
          )
        }
        x[y$name] <- strftime(as.numeric(x[[y$name]]), "%H:%M:%S", tz='UTC')
      }
    } else if (float_as_decimals && y$dataType %in% c("float", 'double', 'decimal')) {
      meta$columns[[i]]['dataType'] <- "decimal"
      meta$columns[[i]]['targetDataType'] <- "decimal"
      x[y$name] <- format(x[y$name], digits=digits)
    }
  }

  # Populate the creation datetime
  meta$datasetJSONCreationDateTime <- get_datetime()

  # Store number of records
  meta$records <- nrow(x)

  # Pull attributes into a list and order
  temp <- meta[c(
    "datasetJSONCreationDateTime",
    "datasetJSONVersion",
    "fileOID",
    "dbLastModifiedDateTime",
    "originator",
    "sourceSystem",
    "studyOID",
    "metaDataVersionOID",
    "metaDataRef",
    "itemGroupOID",
    "records",
    "name",
    "label",
    "columns")
    ]

  temp <- remove_nulls(temp)

  list(meta = temp, data = x)
}

#' Build a datasetjson object from parsed JSON/NDJSON components
#'
#' Shared logic for read_dataset_json and read_dataset_ndjson. Takes the parsed
#' metadata and raw data frame and applies type conversions, labels, and creates
#' the datasetjson S3 object.
#'
#' @param ds_json Parsed metadata list (with columns, fileOID, etc.)
#' @param d Raw data frame (all character columns from JSON parsing)
#' @param decimals_as_floats Convert variables of "decimal" type to float
#'
#' @return A datasetjson object
#' @noRd
build_datasetjson_from_parsed <- function(ds_json, d, decimals_as_floats = FALSE) {
  items <- ds_json$columns

  # Start setting attributes
  colnames(d) <- items$name

  # Process type conversions
  dt <- items$dataType
  tdt <- items$targetDataType
  int_cols <- dt == "integer"
  if (decimals_as_floats) {
    flt_cols <- dt %in% c("float", "double")
    dec_cols <- dt == "decimal" & tdt == "decimal"
    dbl_cols <- flt_cols | dec_cols
  } else {
    dbl_cols <- dt %in% c("float", "double")
  }
  bool_cols <- dt == "boolean"
  d[int_cols] <- lapply(d[int_cols], as.integer)
  d[dbl_cols] <- lapply(d[dbl_cols], as.double)
  d[bool_cols] <- lapply(d[bool_cols], as.logical)

  d <- date_time_conversions(d, dt, tdt)

  # Apply variable labels
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)

  ds_attr <- dataset_json(
    d,
    file_oid = ds_json$fileOID,
    originator = ds_json$originator,
    sys = ds_json$sourceSystem$name,
    sys_version = ds_json$sourceSystem$version,
    study = ds_json$studyOID,
    metadata_version = ds_json$metaDataVersionOID,
    metadata_ref = ds_json$metaDataRef,
    item_oid = ds_json$itemGroupOID,
    name = ds_json$name,
    dataset_label = ds_json$label,
    last_modified = ds_json$dbLastModifiedDateTime,
    version = ds_json$datasetJSONVersion,
    columns = ds_json$columns
  )

  # Apply records and column attribute
  if(ds_json$records != nrow(d)) {
    warning("The number of rows in the data does not match the number of records recorded in the metadata.")
  }

  attr(ds_attr, 'records') <- ds_json$records
  attr(ds_attr, 'datasetJSONCreationDateTime') <- ds_json$datasetJSONCreationDateTime

  ds_attr
}

#' Input validator to ensure object is a proper package object
#'
#' @param x Input object to check
#'
#' @return Error
#' @noRd
stopifnot_datasetjson <- function(x) {
  if (!inherits(x, "datasetjson")) {
    stop("Input must be a datasetjson object", call.=FALSE)
  }
}

#' Helper to set column attributes from items metadata
#'
#' @param nm Column name
#' @param d Input data.frame
#' @param attr Attribute to set
#' @param val Named vector holding the list of attributes to set
#'
#' @return Column with attribute applied
#' @noRd
set_col_attr <- function(nm, d, attr, items) {
  # Pull out the column
  x <- d[[nm]]
  attr(x, attr) <- items[items$name == nm,][[attr]]
  x
}

#' Get the index of nulls in a list
#'
#' @param x A list
#'
#' @return Integer vector of indices
#' @noRd
get_null_inds <- function(x) {
  which(vapply(x, is.null, FUN.VALUE = TRUE))
}

#' Remove nulls from a Dataset JSON object
#'
#' Only targets the file and data metadata to pull off optional elements
#'
#' @param x A Dataset JSON object
#'
#' @return A Dataset JSON object
#' @noRd
remove_nulls <- function(x) {

  # Specifically target the data metadata
  dm_nulls <- get_null_inds(x)

  # Top level
  dm_nulls <- get_null_inds(x)
  if (length(dm_nulls) > 0) {
    x <- x[-dm_nulls]
  }

  x
}



#' Check if given path is a URL
#'
#' @param path character string
#'
#' @return Boolean
#' @noRd
path_is_url <- function(path) {
  grepl("^((http|ftp)s?|sftp|file)://", path)
}

#' Read data from a URL
#'
#' This function will let you pull data that's provided from a simple curl of a
#' URL
#'
#' @param path valid URL string
#'
#' @return Contents of URL
#' @noRd
read_from_url <- function(path) {
  con <- url(path, method = "libcurl")
  x <- readLines(con, warn=FALSE) # the EOL warning shouldn't be a problem for readers
  close(con)
  x
}

#' Convert an dataframe into a named list of rows without NAs
#'
#' The variable attributes are stored as named lists within the output
#' JSON file, so to write them out the dataframe needs to be a named
#' list of rows
#'
#' @param x A data.frame
#'
#' @return List of named lists with single elements
#' @noRd
df_to_list_rows <- function(x) {
  # Split the dataframe rows into individual rows
  rows <- unname(split(x, seq(nrow(x))))
  # Convert each row into a named list while removing NAs
  lapply(rows, function(X) {
    y <- as.list(X)
    y[!is.na(y)]
  })
}

#' Convert date, datetime and time
#'
#' The variable attributes are stored as named lists within the output
#' JSON file, so to write them out the dataframe needs to be a named
#' list of rows
#'
#' @param d A data.frame
#' @param dt A character vector of dataTypes
#' @param tdt A character vector of targetDataTypes
#'
#' @return A data.frame with converted columns
#' @noRd
date_time_conversions <- function(d, dt, tdt){
  date_cols <- dt %in% c("date") & tdt %in% "integer"
  datetime_cols <- dt %in% c("datetime") & tdt %in% "integer"
  time_cols <- dt %in% c("time") & tdt %in% "integer"
  d[date_cols] <- lapply(d[date_cols], as.Date, tz = "UTC")
  d[datetime_cols] <- lapply(d[datetime_cols],
                             as.POSIXct,
                             tz = "UTC",
                             tryFormats = "%Y-%m-%dT%H:%M:%S")
  d[time_cols] <- lapply(d[time_cols], as_hms)
  d
}

