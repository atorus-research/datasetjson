#' Generate an individual element that fills the itemGroupData field
#'
#' @param item_id Data Object ID for item in Dataset JSON object, corresponding to
#'   ItemGroupDef/@OID in Define-XML.
#' @param name Dataset name
#' @param label Dataset Label
#' @param items Variable metadata
#' @param .data Dataframe to be written to Dataset JSON file
#'
#' @return dataset_metadata object
#' @export
#' @examples
#' dataset_meta <- dataset_metadata(
#'   item_id = "IG.IRIS",
#'   name = "IRIS",
#'   label = "Iris",
#'   items = iris_items
#' )
dataset_metadata <- function(item_id, name, label, items, .data) {

  # Check items before moving any further
  validate_dataset_items(items)

  # Attach in the variable metadata
  if (!("ITEMGROUPDATASEQ" %in% items$OID)) {
    igds_row <- data.frame(
      OID = "ITEMGROUPDATASEQ",
      name = "ITEMGROUPDATASEQ",
      label = "Record Identifier",
      type = "integer"
    )

    # Match up columns and fill
    igds_row[setdiff(names(items), names(igds_row))] <- NA
    items[setdiff(names(igds_row), names(items))] <- NA

    items <- rbind(igds_row, items)
  }

  items_converted <- df_to_list_rows(items)

  # Create the container with proper elements
  x <- list(
    list(
      "records" = NULL,
      "name" = name,
      "label" = label,
      "items" = items_converted,
      "itemData" = NULL
    )
  )

  # Set the Object ID
  names(x) <- item_id

  x <- structure(
    x,
    class = c('dataset_metadata', 'list')
  )

  # Set data if it's provided
  if (!missing(.data)) {
    set_item_data(x, .data)
  }

  x
}

#' Apply dataframe to itemData attribute
#'
#' This function will set the itemData attribute within a datasetjson or
#' dataset_metadata object. It additionally sets the records parameter with the
#' proper number of rows in .data.
#'
#' @param x Object to set itemData
#' @param .data Dataframe to be written to Dataset JSON file
#' @param ... Additional params
#'
#' @return Input object with itemData applied
#' @noRd
set_item_data <- function(x, .data, ...) {
  stopifnot_dataset_metadata(x)

  if (!inherits(.data, "data.frame")) {
    stop(".data must be a data.frame", call.=FALSE)
  }

  records <- nrow(.data)
  # Derive ITEMGROUPDATASEQ and insert it up front in the dataframe
  item_data <- cbind(ITEMGROUPDATASEQ = 1:records, .data)

  # Convert data and date times
  item_data <- convert_to_sas_datenum(item_data)
  item_data <- convert_to_sas_datetimenum(item_data)

  # Insert into object in proper spots
  x[[1]][['records']] <- records
  x[[1]][['itemData']] <- item_data
  x
}

#' Verify that the item metadata supplied is the appropriate format
#'
#' This function does the following checks and consolidates to a single error message:
#'   - Columns missing that must be present
#'   - Columns present that are not permissible
#'   - Columns with NAs that must be fully populated
#'   - Columns columns that should be character or integer but aren't
#'   - Within the type column, if the values are within the permissible list per
#'     the schema
#' @param items
#'
#' @return Error Check
#' @noRd
validate_dataset_items <- function(items) {
  required_cols <- c("OID", "name", "label", "type")
  all_cols <- c("OID", "name", "label", "type", "displayFormat", "length", "keySequence")

  # Check for missing or extraneous columns
  missing_cols <- setdiff(required_cols, names(items))
  err_missing_cols <- sprintf("Column `%s` is missing and must be present", missing_cols)
  additional_cols <- setdiff(names(items), all_cols)
  err_additional_cols <- sprintf("Column `%s` is not a permissible column", additional_cols)

  # Check for for NAs in required columns
  any_nas <- vapply(items[intersect(required_cols, names(items))], function(X) any(is.na(X)), FUN.VALUE = TRUE)
  has_nas <- names(any_nas)[any_nas]
  err_nas <- sprintf("Column `%s` must not have NA values", has_nas)

  # Check columns that should be character
  char_cols <- intersect(c("OID", "name", "label", "type", "displayFormat"), names(items))
  are_char_cols <- vapply(items[char_cols], is.character, FUN.VALUE=TRUE)
  not_char_cols <- names(are_char_cols)[!are_char_cols]
  err_char_cols <- sprintf("Column `%s` must be of type character", not_char_cols)

  # Check columns that should be integers
  int_cols <- intersect(c("length", "keySequence"), names(items))
  are_int_cols <- vapply(items[int_cols], is.integer, FUN.VALUE=TRUE)
  not_int_cols <- names(are_int_cols)[!are_int_cols]
  err_int_cols <- sprintf("Column `%s` must be of type integer", not_int_cols)

  # Check that type values are within the permissible list
  err_type_vars <- character()
  if ('type' %in% names(items)) {
    bad_types <- !(items$type %in% c("string", "integer", "float", "double", "decimal", "boolean"))
    bad_type_vars <- items$name[bad_types]
    bad_type_vals <- items$type[bad_types]
    err_type_vars <- sprintf(
      paste("Variable %s has an invalid type value of %s.",
            "Must be one of string, integer, float, double, decimal, boolean"),
      bad_type_vars, bad_type_vals
    )
  }

  all_errs <- c(err_missing_cols, err_additional_cols, err_nas, err_char_cols, err_int_cols, err_type_vars)

  if (length(all_errs) > 0) {
    msg_prep <- paste0("\n\t", all_errs)
    err_msg <- paste0(c("Error: Issues found in items data:", msg_prep))
    stop(err_msg, call.=FALSE)
  }
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
