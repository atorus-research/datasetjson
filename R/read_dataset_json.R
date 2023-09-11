
#' Convert a loaded JSON file to a Dataset JSON object
#'
#' @param x List generated from a loaded JSON file
#'
#' @return datasetjson object
#' @noRd
to_datasetjson <- function(x) {
  attr(x[[7]], "class") <- c("data_metadata", "list")
  attr(x[[7]][['itemGroupData']], "class") <- c("dataset_metadata", "list")
  attr(x, 'class') <- c("datasetjson_v1_0_0", "datasetjson", "list")
  x
}


#' Read a Dataset JSON to datasetjson object
#'
#' This function validated a dataset JSON file on disk against the Dataset JSON schema, and if valid
#' returns a datasetjson object
#'
#' @param file File path on disk
#' @param version Dataset JSON schema version to validate against
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#'
#' # TODO:
load_dataset_json <- function(file, version) {
  # Validate the input file against the schema
  jsonvalidate::json_validate(file, schema_1_0_0, engine="ajv")
  # Read the file and convert to datasetjson object
  ds_json <- jsonlite::fromJSON(file)
  ds_json <- to_datasetjson(ds_json)

  browser()
  dtype <- get_data_type(ds_json)
}


# Read in a dataset_json file
# Code provided by Tilo Blenk on 2022-11-28

#' Read dataset-json file with data of one SDTM/ADaM domain into data frame
#'
#' Read dataset-json file with data of one SDTM/ADaM domain into data frame.
#'
#' @param path path to dataset-json file
#' @return data frame with data of dataset-json file
#' @export
#' @import jsonlite
#' @examples
#' \dontrun{
#' dm <- read_dataset_json("path/to/dm.json")
#' }
read_dataset_json <- function(path, version) {
  browser()

  ds_json <- jsonlite::fromJSON(path)

  dtype <- get_data_type(ds_json)
  x <- names(j$clinicalData$itemGroupData)

  # re-create data frame with correct data types
  # length is ignored at the moment but could be used for rounding
  # of numerical values and padding of string values
  d <- as.data.frame(j$clinicalData$itemGroupData[[x]]$itemData)
  colnames(d) <- j$clinicalData$itemGroupData[[x]]$items$name
  tt <- j$clinicalData$itemGroupData[[x]]$items$type
  for (i in seq_along(tt)) {
    if (tolower(tt[i]) %in% c("integer", "int")) {
      d[,i] <- as.integer(d[,i])
    } else if (tolower(tt[i]) %in% c("float", "numeric", "num", "double", "double precision")) {
      d[,i] <- as.double(d[,i])
    }
    # everything not being integer, double, or numeric is considered as character
  }
  d[,-1] # get rid of ITEMGROUPDATASEQ column
}
