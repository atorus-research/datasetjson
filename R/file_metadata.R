#' Create a file metadata object
#'
#' @param originator originator parameter, defined as "The organization that
#'   generated the Dataset-JSON file."
#' @param sys sourceSystem parameter, defined as "The computer system or
#'   database management system that is the source of the information in this
#'   file."
#' @param sys_version sourceSystemVersion, defined as "The version of the
#'   sourceSystem"
#' @param version Dataset JSON schema version being used
#'
#' @return file_metadata object
#' @export
#'
#' @examples
#' # Create using parameters
#' file_meta <- file_metadata(
#'     originator = "Some Org",
#'     sys = "source system",
#'     sys_version = "1.0"
#'   )
#'
#' # Set parameters after
#' file_meta <- file_metadata()
#'
#' file_meta_updated <- set_file_oid(file_meta, "/some/path")
#' file_meta_updated <- set_originator(file_meta_updated, "Some Org")
#' file_meta_updated <- set_source_system(file_meta_updated, "source system", "1.0")
file_metadata <- function(originator="NA", sys = "NA", sys_version = "NA", version = "1.0.0") {

  if (!(version %in% c("1.0.0"))) {
    stop("Unsupported version specified - currently only version 1.0.0 is supported", call.=FALSE)
  }

  x <- list(
    "creationDateTime"= get_datetime(),
    "datasetJSONVersion"= version,
    "fileOID" = character(),
    "asOfDateTime" = character(),
    "originator" = originator,
    "sourceSystem" = sys,
    "sourceSystemVersion" = sys_version
  )

  structure(
    x,
    class = c("file_metadata", "list")
  )
}

#' Create an ISO8601 formatted datetime of the current time
#'
#' This is used to create the creationDateTime and asOfDateTime attributes of
#' the Dataset JSON object, called at the appropriate time for each attribute
#'
#' @return ISO8601 formatted datetime
#' @noRd
get_datetime <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
}

#' Set source system information
#'
#' Set information about the source system used to generate the Dataset JSON
#' object.
#'
#' @param x datasetjson object
#' @param sys sourceSystem parameter, defined as "The computer system or
#'   database management system that is the source of the information in this
#'   file."
#' @param sys_version sourceSystemVersion, defined as "The version of the
#'   sourceSystem"
#' @param originator originator parameter, defined as "The organization that
#'   generated the Dataset-JSON file."
#' @param file_oid fileOID parameter, defined as "A unique identifier for this
#'   file."
#' @param data_type Type of data being written. clinicalData for subject level
#'   data, and referenceData for non-subject level data (i.e. TDMs, Associated
#'   Persons)
#'
#' @return datasetjson or file_metadata object
#' @export
#' @family File Metadata Setters
#' @rdname file_metadata_setters
#'
#' @examples
#' file_meta <- file_metadata()
#'
#' file_meta_updated <- set_file_oid(file_meta, "/some/path")
#' file_meta_updated <- set_originator(file_meta_updated, "Some Org")
#' file_meta_updated <- set_source_system(file_meta_updated, "source system", "1.0")
set_source_system <- function(x, sys, sys_version) {
  stopifnot_file_metadata(x)
  x[['sourceSystem']] <- sys
  x[['sourceSystemVersion']] <- sys_version
  x
}

#' @export
#' @family File Metadata Setters
#' @rdname file_metadata_setters
set_originator <- function(x, originator) {
  stopifnot_file_metadata(x)
  x[['originator']] <- originator
  x
}

#' @export
#' @family File Metadata Setters
#' @rdname file_metadata_setters
set_file_oid <- function(x, file_oid) {
  stopifnot_file_metadata(x)
  x[['fileOID']] <- file_oid
  x
}

#' @export
#' @family File Metadata Setters
#' @rdname file_metadata_setters
set_data_type <- function(x, data_type = c('clinicalData', 'referenceData')) {
  stopifnot_datasetjson(x)
  data_type = match.arg(data_type)

  # For the clinicalData or referenceData, set the parameter correctly
  names(x) <- c(names(x[1:7]), data_type)
  x
}
