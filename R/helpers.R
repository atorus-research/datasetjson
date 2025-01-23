#' Extract column metadata to data frame
#'
#' This function pulls out the column metadata from the `datasetjson` object
#' attributes into a more user-friendly data.frame.
#'
#' @param x A datasetjson object
#'
#' @returns A data frame containing the columns metadata
#' @export
#'
#' @examples
#'
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#'
#' get_column_metadata(ds_json)
get_column_metadata <- function(x) {
  stopifnot_datasetjson(x)

  cols <- attributes(x)$columns

  do.call(rbind, lapply(cols, cols_list_to_df))
}

#' Convert list input from Dataset JSON columns element to a dataframe.
#'
#' @param clist Dataset JSON columns element, provided as a named list
#'
#' @returns List converted to dataframe
#' @noRd
cols_list_to_df <- function(clist) {
  x <- list(
    itemOID = NULL,
    name = NULL,
    label = NULL,
    dataType = NULL,
    targetDataType = NA_character_,
    length = NA_integer_,
    displayFormat = NA_character_,
    keySequence = NA_integer_
  )

  # Fill in the blanks
  missing_names <- setdiff(names(x), names(clist))
  for (n in missing_names) {
    clist[n] <- x[n]
  }

  as.data.frame(clist)
}

#' Assign Dataset JSON attributes to data frame columns
#'
#' Using the `columns` element of the Dataset JSON file, assign the available
#' metadata to individual columns
#'
#' @param x A datasetjson object
#'
#' @returns A datasetjson object with attributes assigned to individual
#'   variables
#' @export
#'
#' @examples
#'
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#'
#' ds_json <- set_variable_attributes(ds_json)
set_variable_attributes <- function(x) {
  stopifnot_datasetjson(x)
  cols <- attributes(x)$columns

  for (l in cols) {
    # Pop the name
    n <- l$name
    l$name <- NULL

    # Loop and set the attrs
    for (a in names(l)) {
      attr(x[[n]], a) <- l[[a]]
    }

  }
  x
}
