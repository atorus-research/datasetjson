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
  if (!(inherits(x, "datasetjson") | inherits(x, "dataset_metadata"))) {
    stop("Input must be a datasetjson or dataset_metadata object", call.=FALSE)
  }
}

stopifnot_data_metadata <- function(x) {
  if (!(inherits(x, "datasetjson") | inherits(x, "data_metadata"))) {
    stop("Input must be a datasetjson or data_metadata object", call.=FALSE)
  }
}

stopifnot_file_metadata <- function(x) {
  if (!(inherits(x, "datasetjson") | inherits(x, "file_metadata"))) {
    stop("Input must be a datasetjson object or file_metadata object", call.=FALSE)
  }
}

#' Retrieve the data type of a datasetjson object
#'
#' @param x A datasetjson object
#'
#' @return A character string containing the Datset JSON data type
#' @noRd
get_data_type <- function(x) {
  stopifnot_datasetjson(x)
  tail(names(x), 1)
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
