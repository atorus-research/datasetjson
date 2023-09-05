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
#' @param dsjson datasetjson object
#' @param sys sourceSystem parameter, defined as "The computer system or
#'   database management system that is the source of the information in this
#'   file."
#' @param sys_version sourceSystemVersion, defined as "The version of the
#'   sourceSystem"
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#' # TODO:
set_source_system <- function(dsjson, sys, sys_version) {
  stopifnot_datasetjson(dsjson)
  dsjson[['sourceSystem']] <- sys
  dsjson[['sourceSystemVersion']] <- sys_version
  dsjson
}

#' Set originator
#'
#' Set the originator metadata for a Dataset JSON object
#'
#' @param dsjson datasetjson object
#' @param originator originator parameter, defined as "The organization that
#'   generated the Dataset-JSON file."
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#' # TODO:
set_originator <- function(dsjson, originator) {
  stopifnot_datasetjson(dsjson)
  dsjson[['originator']] <- originator
  dsjson
}

#' Set the fileOID parameter
#'
#' Set the fileOID parameter for a Dataset JSON object. This is automated during
#' `write_dataset_json()` using the file path unless the parameter has been set
#' manually.
#'
#' @param dsjson datasetjson object
#' @param file_oid fileOID parameter, defined as "A unique identifier for this
#'   file."
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#' # TODO:
set_file_oid <- function(dsjson, file_oid) {
  stopifnot_datasetjson(dsjson)
  dsjson[['fileOID']] <- file_oid
  dsjson
}
