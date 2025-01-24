#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting. *Note: The Dataset
#'   JSON standard prefers compressed formatting without line feeds. It is not
#'   recommended you use pretty printing for submission purposes.*
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
write_dataset_json <- function(x, file, pretty=FALSE) {
  stopifnot_datasetjson(x)

  # Find all date, datetime and time columns and convert to character
  for (y in attr(x,'columns')) {

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
        if (!inherits(x[[y$name]], "POSIXlt") || !("UTC" %in% attr(x[[y$name]], 'tzone'))){
          stop_write_error(y$name, "Date time variable must be provided as POSIXlt type with timezone set to UTC.")
        }
        x[y$name] <- strftime(x[[y$name]], "%Y-%m-%dT%H:%M:%S", tz='UTC')
      }

      # Convert time
      if (y$dataType == "time") {
        if (y$dataType == "time" & !inherits(x[[y$name]], "Period")) {
          stop_write_error(
            y$name,
            "If dataType is time and targetDataType is integer, the input variable type must be a lubridate Period object"
          )
        }
        x[y$name] <- strftime(as.numeric(x[[y$name]]), "%H:%M:%S", tz='UTC')
      }
    }
  }

  # Populate the creation datetime
  attr(x, 'datasetJSONCreationDateTime') <- get_datetime()

  # Store number of records
  records <- nrow(x)
  attr(x, 'records') <- records

  # Pull attributes into a list and order
  temp <- attributes(x)[c(
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
