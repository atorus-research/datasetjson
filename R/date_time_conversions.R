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

#' Convert a Date object in R to a SAS date origin
#'
#' R uses POSIX date origins, and SAS uses a date origin of 1960-01-01, so to
#' convert you need to add 10 years (plus three leap year days) in days
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
convert_to_sas_datenum <- function(x) {
  col_names <- names(get_date_cols(x))
  # Add 10 years in days (including 3 leap year days)
  x[col_names] <- lapply(get_date_cols(x) + (365 * 10) + 3, as.numeric)
  x
}

#' Convert a POSIXct object in R to a SAS date origin
#'
#' R uses POSIX date origins, and SAS uses a date origin of 1960-01-01, so to
#' convert you need to add 10 years (plus three leap year days) in seconds
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
convert_to_sas_datetimenum <- function(x) {
  col_names <- names(get_datetime_cols(x))
  # Add 10 years in seconds (including 3 leap year days)
  x[col_names] <- lapply(get_datetime_cols(x) + (365 * 24 * 60 * 60 * 10) + (3 * 24 * 60 * 60), as.numeric)

  x
}
