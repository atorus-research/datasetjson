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
validate_dataset_columns <- function(items) {
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


set_column_metadata <- function(x, columns) {
  # Check items before moving any further
  validate_dataset_columns(columns)

  # Attach in the variable metadata
  if (!("ITEMGROUPDATASEQ" %in% columns$OID)) {
    igds_row <- data.frame(
      OID = "ITEMGROUPDATASEQ",
      name = "ITEMGROUPDATASEQ",
      label = "Record Identifier",
      type = "integer"
    )

    # Match up columns and fill
    igds_row[setdiff(names(columns), names(igds_row))] <- NA
    columns[setdiff(names(igds_row), names(columns))] <- NA

    columns <- rbind(igds_row, columns)
  }

  columns_converted <- df_to_list_rows(columns)
}