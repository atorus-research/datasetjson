#' Create the data metadata container for a Dataset JSON object
#'
#' @param data_type Type of data being written. clinicalData for subject level
#'   data, and referenceData for non-subject level data (i.e. TDMs, Associated
#'   Persons)
#'
#' @return data_metadata object
#' @export
#'
#' @examples
#' # TODO:
data_metadata <- function(study, metadata_version, metadata_ref) {

  x <- list(
    studyOID = "NA",
    metaDataVersionOID = "NA",
    metaDataRef = "NA",
    itemGroupData = NULL
  )

  structure(
    x,
    class = c("data_metadata", "list")
  )
}

#' Set data metadata parameters
#'
#' This set of functions
#' @param x data metadata or datasetjson object
#' @param study Study OID value
#' @param ...
#'
#' @return A datasetjson or data_metadata object
#' @export
#'
#' @family Data metadata setters
#' @rdname data_metadata_setters
#'
#' @examples
#' # TODO:
set_study_oid <- function(x, study, ...) {
  UseMethod("set_study_oid")
}

#' @family Data metadata setters
#' @rdname data_metadata_setters
#' @export
set_study_oid.data_metadata <- function(x, study) {
  stopifnot_data_metadata(x)
  x[['studyOID']] <- study
  x
}

#' @param metadata_version Metadata version OID value
#' @family Data metadata setters
#' @rdname data_metadata_setters
#' @export
set_metadata_version <- function(x, metadata_version, ...) {
  UseMethod("set_metadata_version")
}

#' @export
#' @noRd
set_metadata_version.data_metadata <- function(x, metadata_version) {
  stopifnot_data_metadata(x)
  x[['metaDataVersionOID']] <- metadata_version
  x
}

#' @param metadata_ref Metadata reference (i.e. path to Define.xml)
#' @family Data metadata setters
#' @rdname data_metadata_setters
#' @export
set_metadata_ref <- function(x, metadata_ref) {
  UseMethod("set_metadata_ref")
}

#' @export
#' @noRd
set_metadata_ref.data_metadata <- function(x, metadata_ref) {
  stopifnot_data_metadata(x)
  x[['metaDataRef']] <- metadata_ref
  x
}
