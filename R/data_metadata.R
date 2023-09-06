#' Create the data metadata container for a Dataset JSON object
#'
#' @param data_type Type of data being written. clinicalData for subject level
#'   data, and referenceData for non-subject level data (i.e. TDMs, Associated
#'   Persons)
#'
#' @return
#' @export
#'
#' @examples
data_metadata <- function(data_type = c('clinicalData', 'referenceData')) {
  data_type = match.arg(data_type)

  x <- list(
    studyOID = NULL,
    metaDataVersionOID = NULL,
    metaDataRef = NULL,
    itemGroupData = NULL
  )

  names(x) <- data_type
}

# Build up the clinicalData or referenceData elements
set_study_oid <- function() {}

set_metadata_version <- function() {}

set_metadata_ref <- function () {}
