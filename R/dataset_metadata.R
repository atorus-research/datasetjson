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
#' @examples
#' # TODO:
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

  if (!missing(.data)) {
    records <- nrow(.data)
    # Derive ITEMGROUPDATASEQ and insert it up front in the dataframe
    item_data <- cbind(ITEMGROUPDATASEQ = 1:records, .data)
  } else {
    records <- NULL
    item_data <- NULL
  }

  # Create the container with proper elements
  x <- list(
    list(
      "records" = records,
      "name" = name,
      "label" = label,
      "items" = items,
      "itemData" = item_data
    )
  )

  # Set the Object ID
  names(x) <- item_id

  structure(
    x,
    class = c('dataset_metadata', 'list')
  )
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
#' @export
#'
#' @examples
#' # TODO:
set_item_data <- function(x, .data, ...) {
  UseMethod("set_item_data")
}

#' @noRd
#' @export
#' @method set_item_data dataset_metadata
set_item_data.dataset_metadata <- function(x, .data) {
  stopifnot_dataset_metadata(x)

  if (!inherits(.data, "data.frame")) {
    stop(".data must be a data.frame", call.=FALSE)
  }

  records <- nrow(.data)
  # Derive ITEMGROUPDATASEQ and insert it up front in the dataframe
  item_data <- cbind(ITEMGROUPDATASEQ = 1:records, .data)

  # Insert into object in proper spots
  x[[1]][['records']] <- records
  x[[1]][['itemData']] <- item_data
  x
}

#' Verify that the item metadata supplied is the appropriate format
#'
#' @param items
#'
#' @return Error Check
validate_dataset_items <- function(items) {
  # Variables for item metadata
  #
  # OID           "Unique identifier for Variable. Must correspond to ItemDef/@OID in Define-XML."
  # displayFormat "Display format supports data visualization of numeric float and date values."
  # keySequence   "Indicates that this item is a key variable in the dataset structure. It also provides an ordering for the keys."
  # label         "Label for Variable"
  # length        "Length for Variable"
  # name          "Name for Variable"
  # type          "Data type for Variable"
  #
  # Possible types:
  # "string",
  # "integer",
  # "float",
  # "double",
  # "decimal",
  # "boolean"
  TRUE
}

#' Apply JSON metadata to dataframe as attributes
#'
#' This function takes supplied metadata and applies it to a dataframe as
#' corresponding attributes
#'
#' @param .data A Dataframe
#' @param metadata A list containing Dataset JSON dataset object metadata
#'
#' @return dataframe
#' @examples
#' # TODO:
#' @noRd
apply_dataset_metadata <- function(.data, metadata) {
  # TODO: Set records, name, and label to the dataframe as a whole

  # TODO: Set OID, name, label, type, length, and format, and keySequence as
  # necessary to each variable
  TRUE
}

#' Gather Dataset JSON metadata from a dataframe which has Dataset JSON metadata
#' applied
#'
#' This function will gather the attributes from a data frame which has Dataset
#' JSON metadata applied.
#'
#' @param .data A dataframe with Dataset JSON attributes applied
#'
#' @return A list of Dataset dataset object JSON metadata
#' @noRd
gather_dataset_metadata <- function(.data) {

  # Retrieve the necessary metadata off of a data frame that pertains to a dataset JSON object
  TRUE
}
