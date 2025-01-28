#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting. *Note: The Dataset
#'   JSON standard prefers compressed formatting without line feeds. It is not
#'   recommended you use pretty printing for submission purposes.*
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
#' js <- write_dataset_json(ds_json)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_json(ds_json, "path/to/file.json")
#' }
write_dataset_json <- function(x, file, pretty=FALSE, float_as_decimals=FALSE, digits=16) {
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
    "label",
    "columns")
    ]

  temp <- remove_nulls(temp)

  # add data rows
  temp$rows <- unname(x)

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
      temp,
      filename = file,
      opts = json_opts
    )
  } else {
    # Print to console
    yyjsonr::write_json_str(
      temp,
      opts = json_opts
    )
  }
}

stop_write_error <- function(varname, msg){
  stop(
    sprintf(paste(
      "Please check the variable %s.",
      msg,
      sep="\n  "),
      varname)
  )
}
