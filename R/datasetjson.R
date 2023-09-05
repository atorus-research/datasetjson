#' Create a Dataset JSON Object
#'
#' Create the base object used to write a Dataset JSON file.
#'
#' @param .data Input data to contain within the Dataset JSON file. Written to
#'   the itemData parameter.
#' @param item_id ID used to label dataset with the itemGroupData parameter.
#'   Defined as "Object of Datasets. Key value is a unique identifier for
#'   Dataset, corresponding to ItemGroupDef/@OID in Define-XML."
#' @param dataset_metadata Metadata pertaining to the .data parameter. Written
#'   to the itemGroupData parameter
#' @param version Version of Dataset JSON schema to follow.
#' @return dataset_json object pertaining to the specific Dataset JSON version specific
#' @export
#'
#' @examples
#' # TODO:
dataset_json <- function(.data, item_id, dataset_metadata, version="1.0.0") {
  new_dataset_json(version, item_id)
}

#' Create a base Dataset JSON Container
#'
#' Returns the base datasetjson object following a specific version of the
#' schema
#'
#' @return datasetjson object
#' @noRd
new_dataset_json <- function(version, item_id) {
  # List of version specific generators
  funcs <- list(
    "1.0.0" = new_dataset_json_v1_0_0
  )

  # Extract the function and call it to return the base structure
  funcs[[version]](item_id)
}

#' Dataset JSON v1.0.0 Generator
#'
#' @return datasetjson_v1_0_0 object
#' @noRd
new_dataset_json_v1_0_0 <- function(item_id) {

  x <- list(
    "creationDateTime"= get_datetime(),
    "datasetJSONVersion"= "1.0.0",
    "fileOID" = character(),
    "asOfDateTime" = character(),
    "originator" = "NA",
    "sourceSystem" = "NA",
    "sourceSystemVersion" = "NA",
    "clinicalData" = list(
      "studyOID" = "NA",
      "metaDataVersionOID" = "NA",
      "metaDataRef" = "NA",
      "itemGroupData"= list(
        list(
          "items" = data.frame(),
          "itemData" = data.frame()
        )
      )
    )
  )

  names(x$clinicalData$itemGroupData) <- item_id

  structure(
    x,
    class = c("datasetjson_v1_0_0", "datasetjson", "list")
  )
}
