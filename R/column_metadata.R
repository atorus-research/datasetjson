#' Verify that the item metadata supplied is the appropriate format
#'
#' This function does the following checks and consolidates to a single error message:
#'   - Columns missing that must be present
#'   - Columns present that are not permissible
#'   - Columns with NAs that must be fully populated
#'   - Columns columns that should be character or integer but aren't
#'   - Within the dataType column, if the values are within the permissible list per
#'     the schema
#'   - Within the targetDataType column, if the values are within the permissible list per
#'     the schema
#' @param items
#'
#' @return Error Check
#' @noRd
validate_dataset_columns <- function(items) {
  required_cols <- c("itemOID", "name", "label", "dataType")
  all_cols <- c("itemOID", "name", "label", "dataType", "targetDataType", "length", "displayFormat", "keySequence")

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
  char_cols <- intersect(c("itemOID", "name", "label", "dataType", "targetDataType", "displayFormat"), names(items))
  are_char_cols <- vapply(items[char_cols], is.character, FUN.VALUE=TRUE)
  not_char_cols <- names(are_char_cols)[!are_char_cols]
  err_char_cols <- sprintf("Column `%s` must be of type character", not_char_cols)

  # Check columns that should be integers
  int_cols <- intersect(c("length", "keySequence"), names(items))
  are_int_cols <- vapply(items[int_cols], is.integer, FUN.VALUE=TRUE)
  not_int_cols <- names(are_int_cols)[!are_int_cols]
  err_int_cols <- sprintf("Column `%s` must be of type integer", not_int_cols)

  # Check that dataType values are within the permissible list
  err_dataType_vars <- character()
  if ('dataType' %in% names(items)) {
    bad_dataType <- !(items$dataType %in% c("string", "integer", "float", "double", "decimal", "boolean",
                                     "datetime", "date", "time", "URI"))
    bad_dataType_vars <- items$name[bad_dataType]
    bad_dataType_vals <- items$dataType[bad_dataType]
    err_dataType_vars <- sprintf(
      paste("Variable %s has an invalid dataType value of %s.",
            "Must be one of string, integer, float, double, decimal, boolean, datetime, date, time, URI"),
      bad_dataType_vars, bad_dataType_vals
    )
  }

  # Check that targetDataType values are within the permissible list, which includes NA
  # since this is optional
  err_targetDataType_vars <- character()
  if ('targetDataType' %in% names(items)) {
    bad_targetDataType <- !(items$targetDataType %in% c("integer", "decimal", NA))
    bad_targetDataType_vars <- items$name[bad_targetDataType]
    bad_targetDataType_vals <- items$targetDataType[bad_targetDataType]
    err_targetDataType_vars <- sprintf(
      paste("Variable %s has an invalid targetDataType value of %s.",
            "Must be integer or decimal"),
      bad_targetDataType_vars, bad_targetDataType_vals
    )
  }

  all_errs <- c(err_missing_cols, err_additional_cols, err_nas, err_char_cols,
                err_int_cols, err_dataType_vars, err_targetDataType_vars)

  if (length(all_errs) > 0) {
    msg_prep <- paste0("\n\t", all_errs)
    err_msg <- paste0(c("Error: Issues found in items data:", msg_prep))
    stop(err_msg, call.=FALSE)
  }
}


set_column_metadata <- function(columns) {
  # Check items before moving any further
  validate_dataset_columns(columns)

  # Attach in the variable metadata
  if (!("ITEMGROUPDATASEQ" %in% columns$itemOID)) {
    igds_row <- data.frame(
      itemOID = "ITEMGROUPDATASEQ",
      name = "ITEMGROUPDATASEQ",
      label = "Record Identifier",
      dataType = "integer"
    )

    # Match up columns and fill
    igds_row[setdiff(names(columns), names(igds_row))] <- NA
    columns[setdiff(names(igds_row), names(columns))] <- NA

    columns <- rbind(igds_row, columns)
  }

  columns_converted <- df_to_list_rows(columns)
}
