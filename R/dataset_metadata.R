#' Title
#'
#' @param uid Data Object ID for item in Dataset JSON object
#'
#' @return List of dataset metadata
#' TODO: This is completely untested and hasn't been run yet.
dataset_metadata <- function(.data, uid, name, label, items) {

  # Check items before moving any further
  validate_dataset_items(items)

  records <- nrow(.data)

  # Create the container with proper elements
  x <- list(
    list(
      "records" = records,
      "name" = name,
      "label" = label,
      "items" = NULL,
      "itemData" = NULL
    )
  )

  # Set the Object ID
  names(x) <- uid

  # Attach in the variable metadata
  if (!("ITEMGROUPDATASEQ" %in% names(items))) {
    igds_row <- data.frame(
      OID = "ITEMGROUPDATASEQ",
      name = "ITEMGROUPDATASEQ",
      label = "Record Identifier",
      type = "integer"
    )

    items <- rbind(igds_row, items)
  }
  x['items'] <- items

  # Derive ITEMGROUPDATASEQ and insert it up front in the dataframe
  .data <- cbind(ITEMGROUPDATASEQ = 1:records, .data)
  x['itemData'] <- .data

  structure(
    x,
    class = c('dataset_metadata', 'list')
  )
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
#' @export
#'
#' @examples
#' # TODO:
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
#' @export
#'
#' @examples
#' TODO:
gather_dataset_metadata <- function(.data) {

  # Retrieve the necessary metadata off of a data frame that pertains to a dataset JSON object
  TRUE
}
