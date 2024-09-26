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

#' Get the index of nulls in a list
#'
#' @param x A list
#'
#' @return Integer vector of indices
#' @noRd
get_null_inds <- function(x) {
  which(vapply(x, is.null, FUN.VALUE = TRUE))
}



#' Check if given path is a URL
#'
#' @param path character string
#'
#' @return Boolean
#' @noRd
path_is_url <- function(path) {
  grepl("^((http|ftp)s?|sftp|file)://", path)
}

#' Read data from a URL
#'
#' This function will let you pull data that's provided from a simple curl of a
#' URL
#'
#' @param path valid URL string
#'
#' @return Contents of URL
#' @noRd
read_from_url <- function(path) {
  con <- url(path, method = "libcurl")
  x <- readLines(con, warn=FALSE) # the EOL warning shouldn't be a problem for readers
  close(con)
  x
}

#' Convert an dataframe into a named list of rows without NAs
#'
#' The variable attributes are stored as named lists within the output
#' JSON file, so to write them out the dataframe needs to be a named
#' list of rows
#'
#' @param x A data.frame
#'
#' @return List of named lists with single elements
#' @noRd
df_to_list_rows <- function(x) {
  # Split the dataframe rows into individual rows
  rows <- unname(split(x, seq(nrow(x))))
  # Convert each row into a named list while removing NAs
  lapply(rows, function(X) {
    y <- as.list(X)
    y[!is.na(y)]
  })
}

