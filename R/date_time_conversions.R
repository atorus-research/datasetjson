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
#' convert you need to subtract 10 years in days
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
convert_to_sas_datenum <- function(x) {
  col_names <- names(get_date_cols(x))
  # Subtract 10 years in days
  x[col_names] <- lapply(get_date_cols(x) - (365 * 10), as.numeric)
  x
}

#' Convert a POSIXct object in R to a SAS date origin
#'
#' R uses POSIX date origins, and SAS uses a date origin of 1960-01-01, so to
#' convert you need to subtract 10 years in seconds
#'
#' @param x A data.frame
#'
#' @return A data.frame
#' @noRd
convert_to_sas_datetimenum <- function(x) {
  col_names <- names(get_datetime_cols(x))
  # Subtract 10 years in seconds
  x[col_names] <- lapply(get_datetime_cols(x) - (365 * 24 * 60 * 60 * 10), as.numeric)
  x
}

#' Check if a list has an element named displayFormat with a desired value
#'
#' This function checks if a list has the element displayFormat, and if the
#' value of that element is within a list of specific values provided in a
#' character array. This is intended to work with the datasetjson package arrays
#' `sas_date_formats`, `sas_datetime_formats`, and `sas_time_formats`.
#'
#' @param x The items element list of a Dataset JSON file
#' @param formats A character array
#'
#' @return Boolean vector
#' @noRd
has_format <- function(x, formats) {
  !is.null(x$displayFormat) && x$displayFormat %in% formats
}

#' Get the names of columns from a dataset that have specific formats
#'
#' This function will take the items element of a Dataset JSON file and return
#' then names of columns that have a value within the specified character array
#' of values.
#'
#' @param x The items element list of a Dataset JSON file
#' @param formats A character array
#'
#' @return A character vector
#' @noRd
get_format_cols <- function(x, formats) {
  # Filter the provided list to elements that have the specified array
  # of displayFormat values, then extract the name columns from
  # that subset list
  vapply(Filter(function(X) has_format(X, formats), x), function(X) X$name, "")
}
