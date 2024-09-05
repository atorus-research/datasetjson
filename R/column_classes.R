# This file contains several helpers for reading and writing date / datetime
# columns from a Dataset JSON file

#' Get the column classes off a data frame
#'
#' @param x A data.frame
#'
#' @return Named character vector of columns and types
#' @noRd
get_column_classes <- function(x) {
  vapply(x, function(X) class(X)[1], FUN.VALUE=character(1))
}

#' Get the columns with a class of Date from a data.frame
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
get_date_cols <- function(x) {
  x[get_column_classes(x) == "Date"]
}

#' Get the columns with a class of POSIXct from a data.frame
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
get_datetime_cols <- function(x) {
  x[get_column_classes(x) == "POSIXct"]
}
