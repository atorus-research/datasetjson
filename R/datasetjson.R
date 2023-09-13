#' Create a Dataset JSON Object
#'
#' Create the base object used to write a Dataset JSON file.
#'
#' @param .data Input data to contain within the Dataset JSON file. Written to
#'   the itemData parameter.
#' @param item_id ID used to label dataset with the itemGroupData parameter.
#'   Defined as "Object of Datasets. Key value is a unique identifier for
#'   Dataset, corresponding to ItemGroupDef/@OID in Define-XML."
#' @param name Dataset name
#' @param label Dataset Label
#' @param items Variable metadata
#' @param dataset_meta A dataset_metadata object holding pre-specified
#'   dataset metadata.
#' @param version Version of Dataset JSON schema to follow.
#' @param data_type Type of data being written. clinicalData for subject level
#'   data, and referenceData for non-subject level data (i.e. TDMs, Associated
#'   Persons)
#' @param file_meta A file_metadata object holding pre-specified file
#'   metadata
#' @param data_meta A data_metadata object holding pre-specified data
#'   metadata
#'
#' @return dataset_json object pertaining to the specific Dataset JSON version
#'   specific
#' @export
#'
#' @examples
#' # Create a basic object
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
#'
#' # Attach attributes directly
#' ds_json_updated <- set_data_type(ds_json, "referenceData")
#' ds_json_updated <- set_file_oid(ds_json_updated, "/some/path")
#' ds_json_updated <- set_metadata_ref(ds_json_updated, "some/define.xml")
#' ds_json_updated <- set_metadata_version(ds_json_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' ds_json_updated <- set_originator(ds_json_updated, "Some Org")
#' ds_json_updated <- set_source_system(ds_json_updated, "source system", "1.0")
#' ds_json_updated <- set_study_oid(ds_json_updated, "SOMESTUDY")
#'
#' # Create independent objects for metadata sections first
#' file_meta <- file_metadata(
#'   originator = "Some Org",
#'   sys = "source system",
#'   sys_version = "1.0"
#' )
#'
#' data_meta <- data_metadata(
#'   study = "SOMESTUDY",
#'   metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
#'   metadata_ref = "some/define.xml"
#' )
#'
#' dataset_meta <- dataset_metadata(
#'   item_id = "IG.IRIS",
#'   name = "IRIS",
#'   label = "Iris",
#'   items = iris_items
#' )
#'
#' ds_json_from_meta <- dataset_json(
#'   iris,
#'   dataset_meta = dataset_meta,
#'   file_meta = file_meta,
#'   data_meta = data_meta
#'   )
dataset_json <- function(.data, item_id, name, label, items, dataset_meta,
                         version="1.0.0", data_type = c('clinicalData', 'referenceData'),
                         file_meta = file_metadata(),
                         data_meta = data_metadata()
                         ) {
  data_type = match.arg(data_type)
  new_dataset_json(version, item_id, data_type, name, label, items, dataset_meta, file_meta, data_meta, .data)
}

#' Create a base Dataset JSON Container
#'
#' Returns the base datasetjson object following a specific version of the
#' schema. Note - the purpose of this is just to lay a framework for how
#' versioning might be handled later on. Only one version is handled.
#'
#' @return datasetjson object
#'
#' @noRd
new_dataset_json <- function(version, item_id, data_type, name, label, items,
                             dataset_meta, file_meta, data_meta, .data) {

  if (!(version %in% c("1.0.0"))) {
    stop("Unsupported version specified - currently only version 1.0.0 is supported", call.=FALSE)
  }

  # List of version specific generators
  funcs <- list(
    "1.0.0" = new_dataset_json_v1_0_0
  )

  # Extract the function and call it to return the base structure
  funcs[[version]](item_id, data_type, name, label, items, dataset_meta, file_meta, data_meta, .data)
}

#' Dataset JSON v1.0.0 Generator
#'
#' @return datasetjson_v1_0_0 object
#' @noRd
new_dataset_json_v1_0_0 <- function(item_id, data_type, name, label, items, dataset_meta, file_meta, data_meta, .data) {

  if (missing(dataset_meta)) {
    if (any(missing(item_id), missing(name), missing(label), missing(items))) {
      stop("If dataset_meta is not provided, then name, label, and items must be provided", call.=FALSE)
    }

    # Create the dataset metadata with provided info
    dataset_meta <- dataset_metadata(item_id, name, label, items)
  }

  # Attach .data into dataset_meta
  dataset_meta <- set_item_data(dataset_meta, .data)

  # Combine file_meta, data_meta, and dataset_meta together
  ds_json <- file_meta
  ds_json[[data_type]] <- data_meta
  ds_json[[data_type]][['itemGroupData']] <- dataset_meta

  structure(
    ds_json,
    class = c("datasetjson_v1_0_0", "datasetjson", "list")
  )
}
