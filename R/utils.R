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

stopifnot_dataset_metadata <- function(x) {
  if (!inherits(x, "dataset_metadata")) {
    stop("Input must be a dataset_metadata object", call.=FALSE)
  }
}

stopifnot_data_metadata <- function(x) {
  if (!inherits(x, "data_metadata")) {
    stop("Input must be a data_metadata object", call.=FALSE)
  }
}

stopifnot_file_metadata <- function(x) {
  if (!inherits(x, "file_metadata")) {
    stop("Input must be a file_metadata object", call.=FALSE)
  }
}
