#' Create a Dataset JSON Object
#'
#' Create the base object used to write a Dataset JSON file.
#'
#' @details
#' 
#' Note that DatasetJSON is on version 1.1.0. Based off findings from the pilot, 
#' version 1.1.0 reflects feedback from the user community. Support for 1.0.0 has 
#' been deprecated.
#' 
#' @param .data Input data to contain within the Dataset JSON file. Written to
#'   the itemData parameter.
#' @param sys sourceSystem parameter, defined as "The computer system or
#'   database management system that is the source of the information in this
#'   file."
#' @param sys_version sourceSystemVersion, defined as "The version of the
#'   sourceSystem"
#' @param originator originator parameter, defined as "The organization that
#'   generated the Dataset-JSON file."
#' @param file_oid fileOID parameter, defined as "A unique identifier for this
#'   file."
#' @param study Study OID value
#' @param metadata_version Metadata version OID value
#' @param metadata_ref Metadata reference (i.e. path to Define.xml)
#' @param item_oid ID used to label dataset with the itemGroupData parameter.
#'   Defined as "Object of Datasets. Key value is a unique identifier for
#'   Dataset, corresponding to ItemGroupDef/@OID in Define-XML."
#' @param ref_data Boolean value that is set to "true" when the dataset contains 
#'   reference data (not subject data). The default value is "false". 
#' @param version The DatasetJSON version to use. Currently only 1.1.0 is supported.
#' @param columns Variable level metadata for the Dataset JSON object
#'
#' @return dataset_json object pertaining to the specific Dataset JSON version
#'   specific
#' @export
#'
#' @examples
#' # Create a basic object
#' ds_json <- dataset_json(
#'   iris, 
#'   file_oid = "/some/path",
#'   last_modified = "2023-02-15T10:23:15",
#'   originator = "Some Org", 
#'   sys = "source system", 
#'   sys_version = "1.0", 
#'   study = "SOMESTUDY",
#'   metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
#'   metadata_ref = "some/define.xml",
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#'
#' # Attach attributes directly
#' ds_json_updated <- set_data_type(ds_json, "referenceData")
#' ds_json_updated <- set_file_oid(ds_json_updated, "/some/path")
#' ds_json_updates <- set_last_modified(ds_json_updates, "2023-02-15T10:23:15")
#' ds_json_updated <- set_metadata_ref(ds_json_updated, "some/define.xml")
#' ds_json_updated <- set_metadata_version(ds_json_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' ds_json_updated <- set_originator(ds_json_updated, "Some Org")
#' ds_json_updated <- set_source_system(ds_json_updated, "source system", "1.0")
#' ds_json_updated <- set_study_oid(ds_json_updated, "SOMESTUDY")
#' ds_json_updated <- set_item_oid(ds_json_updated, "IG.IRIS")
#' ds_json_updated <- set_dataset_name(ds_json_updated, "IRIS")
#' ds_json_updated <- set_dataset_label(ds_json_updated, "Iris")
#' ds_json_updates <- set_columns(ds_json_updated, iris_items)
dataset_json <- function(.data, file_oid=NULL, last_modified=NULL, 
                          originator=NULL, sys=NULL, sys_version = NULL, 
                          study=NULL, metadata_version=NULL,metadata_ref=NULL, 
                          item_oid=NULL, name=NULL, dataset_label=NULL, ref_data=FALSE, 
                          columns=NULL, version="1.1.0") {
  new_dataset_json(.data, file_oid, last_modified, originator, sys, sys_version, study, 
                   metadata_version, metadata_ref, item_oid, name, dataset_label, ref_data, 
                   columns, version)
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
new_dataset_json <- function(.data, file_oid, last_modified, originator, sys, sys_version, study, 
                             metadata_version, metadata_ref, item_oid, name, dataset_label,
                             ref_data, columns, version) {

  if (!(version %in% c("1.1.0"))) {
    stop("Unsupported version specified - currently only version 1.1.0 is supported", call.=FALSE)
  }

  # List of version specific generators
  funcs <- list(
    "1.1.0" = new_dataset_json_v1_1_0
  )

  # Extract the function and call it to return the base structure
  funcs[[version]](.data, file_oid, last_modified, originator, sys, sys_version, study, 
                   metadata_version, metadata_ref, item_oid, name, dataset_label,
                   ref_data, columns)
}

#' Dataset JSON v1.1.0 Generator
#'
#' @return datasetjson_v1_1_0 object
#' @noRd
new_dataset_json_v1_1_0 <- function(.data, file_oid, last_modified, originator, sys, sys_version, 
                                    study, metadata_version, metadata_ref, item_oid, name, 
                                    dataset_label, ref_data, columns) {

  if (!inherits(.data, 'data.frame')) {
    stop("datasetjson objects must inherit from a data.frame", call.=FALSE)
  }

  if (!is.null(sys) && !is.null(sys_version)) {
    attr(.data, 'sourceSystem') <- list(
      "name" = sys,
      "version" = sys_version
    )
  }

  attr(.data, 'datasetJSONVersion') <- "1.1.0"
  attr(.data, 'fileOID') <- file_oid
  attr(.data, 'dbLastModifiedDateTime') <- last_modified
  attr(.data, 'originator') <- originator
  attr(.data, 'studyOID') <- study
  attr(.data, 'metaDataVersionOID') <- metadata_version
  attr(.data, 'metaDataRef') <- metadata_ref
  attr(.data, "itemGroupOID") <- item_oid
  attr(.data, 'name') <- name
  attr(.data, 'label') <- dataset_label
  attr(.data, 'isReferenceData') <- ref_data
  if (!is.null(columns)) {
    validate_dataset_columns(columns)
  }
  attr(.data, 'columns') <- columns
  
  structure(
    .data,
    class = c("datasetjson_v1_1_0", "datasetjson", "data.frame")
  )
}
