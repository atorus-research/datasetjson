#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting. *Note: The Dataset
#'   JSON standard prefers compressed formatting without line feeds. It is not
#'   recommended you use pretty printing for submission purposes.*
#' @param float_as_decimals If TRUE, write float variables as the "decimal"
#'   data type, quoting the numbers as JSON strings rather than writing them as
#'   JSON numbers. This is an interoperability choice for systems that expect
#'   the decimal type; it is not needed for precision, as numbers are written at
#'   full precision either way. See the [Dataset JSON user
#'   guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding) for more
#'   information. Defaults to FALSE
#' @param digits When using `float_as_decimals`, the number of significant
#'   digits to render. Defaults to NULL, which uses the shortest representation
#'   that reads back as the same value. Supplying a number fixes the precision
#'   instead, which is lossy below 17 digits.
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
#' js <- write_dataset_json(ds_json)
#'
#' # Write to disk
#' write_dataset_json(ds_json, tempfile(fileext = ".json"))
write_dataset_json <- function(
  x,
  file,
  pretty = FALSE,
  float_as_decimals = FALSE,
  digits = NULL
) {
  prepared <- prepare_dataset_for_write(x, float_as_decimals)

  if (!missing(file)) {
    # Make sure the output path exists
    if (!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call. = FALSE)
    }
  }

  # Serialize natively. Numbers go through yyjson's writer, which emits the
  # shortest representation that parses back to the same double.
  .Call(
    C_write_dsjson,
    prepared$meta,
    prepared$columns,
    prepared$data,
    prepared$as_decimal,
    if (is.null(digits)) NA_integer_ else as.integer(digits),
    isTRUE(pretty),
    if (missing(file)) NULL else file
  )
}

#' Shared preparation for the JSON and NDJSON writers
#'
#' Validates the date/time column types, renders them to character, flags the
#' columns to be written as decimal strings, and assembles the metadata in the
#' order the standard recommends.
#'
#' @param x A datasetjson object
#' @param float_as_decimals Flag float columns to be written as decimal strings
#'
#' @return A list with `meta`, `columns`, `data` and `as_decimal`
#' @noRd
prepare_dataset_for_write <- function(x, float_as_decimals = FALSE) {
  stopifnot_datasetjson(x)

  meta <- attributes(x)

  # Columns to serialize as decimal strings rather than JSON numbers. The
  # values themselves are rendered in C, at whatever precision round-trips.
  as_decimal <- rep(FALSE, length(meta$columns))

  # Find all date, datetime and time columns and convert to character
  for (i in seq_along(meta$columns)) {
    y <- meta$columns[[i]]

    # Make sure metadata is compliant
    if (
      y$dataType %in%
        c("date", "datetime", "time") &
        !("targetDataType" %in% names(y))
    ) {
      if (!inherits(x[[y$name]], "character")) {
        stop_write_error(
          y$name,
          "If dataType is date, time, or datetime and targetDataType is null, the input variable type must be character"
        )
      }
    }

    if (
      y$dataType %in%
        c("date", "datetime", "time") &
        (!is.null(y$targetDataType) && y$targetDataType == "integer")
    ) {
      # Convert date
      if (y$dataType == "date") {
        x[y$name] <- format(x[[y$name]], "%Y-%m-%d", tz = 'UTC')
      }

      # Convert datetime
      if (y$dataType == "datetime") {
        # Ensure type and timezone is right.
        if (
          !inherits(x[[y$name]], "POSIXt") ||
            !("UTC" %in% attr(x[[y$name]], 'tzone'))
        ) {
          stop_write_error(
            y$name,
            "Date time variable must be provided as POSIXlt type with timezone set to UTC."
          )
        }
        x[y$name] <- strftime(x[[y$name]], "%Y-%m-%dT%H:%M:%S", tz = 'UTC')
      }

      # Convert time
      if (y$dataType == "time") {
        if (
          y$dataType == "time" &
            !inherits(x[[y$name]], c("Period", "difftime", "ITime"))
        ) {
          stop_write_error(
            y$name,
            "If dataType is time and targetDataType is integer, the input variable type must be a lubridate Period, an hms difftime, or a data.table ITime object"
          )
        }
        x[y$name] <- strftime(
          as.POSIXlt(
            as.numeric(x[[y$name]]),
            tz = 'UTC',
            origin = "1970-01-01"
          ),
          "%H:%M:%S",
        )
      }
    } else if (
      float_as_decimals && y$dataType %in% c("float", 'double', 'decimal')
    ) {
      meta$columns[[i]]['dataType'] <- "decimal"
      meta$columns[[i]]["targetDataType"] <- "decimal"
      as_decimal[i] <- TRUE
    }
  }

  # Populate the creation datetime
  meta$datasetJSONCreationDateTime <- get_datetime()

  # Store number of records
  records <- nrow(x)
  meta$records <- records

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
    "label"
  )]

  temp <- remove_nulls(temp)

  list(
    meta = temp,
    columns = unname(meta$columns),
    data = unclass(x)[names(x)],
    as_decimal = as_decimal
  )
}

stop_write_error <- function(varname, msg) {
  stop(
    sprintf(
      paste(
        "Please check the variable %s.",
        msg,
        sep = "\n  "
      ),
      varname
    )
  )
}
