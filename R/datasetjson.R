#' Create a Dataset JSON Object
#'
#' Create the base object used to write a Dataset JSON file.
#'
#' @details
#'
#' The `columns` parameter should be provided as a dataframe based off the
#' Dataset JSON Specification:
#' - **itemOID**: *string, required*: Unique identifier for the variable that may also
#' function as a foreign key to an ItemDef/@OID in an associated Define-XML
#' file. See the [ODM
#' specification](https://wiki.cdisc.org/display/PUB/Element+Identifiers+and+References)
#' for OID considerations.
#' - **name**: *string, required*: Variable name
#' - **label**: *string, required*: Variable label
#' - **dataType**: *string, required*: Logical data type of the variable. The dataType
#' attribute represents the planned specificity of the data. See the [ODM Data
#' Formats specification](https://wiki.cdisc.org/display/PUB/Data+Formats) for
#' details.
#' -**targetDataType**: *string, optional*: Indicates the data type into which
#' the receiving system must transform the associated Dataset-JSON variable. The
#' variable with the data type attribute of dataType must be converted into the
#' targetDataType when transforming the Dataset-JSON dataset into a format for
#' operational use (e.g., SAS dataset, R dataframe, loading into a system's data
#' store). Only specify targetDataType when it is different from the dataType
#' attribute or the JSON data type and the data needs to be transformed by the
#' receiving system. See the Supported Column Data Type Combinations table for
#' details on usage. See the User's Guide for additional information.
#' - **length**: *integer, optional*: Specifies the number of characters
#' allowed for the variable value when it is represented as a text.
#' - **displayFormat**: *string, optional: A SAS display format value used for
#' data visualization of numeric float and date values.
#' - **keySequence**: *integer, optional*: Indicates that this item is a key
#' variable in the dataset structure. It also provides an ordering for the keys.
#'
#' Note that DatasetJSON is on version 1.1.0. Based off findings from the pilot,
#' version 1.1.0 reflects feedback from the user community. Support for 1.0.0
#' has been deprecated.
#'
#' @param .data Input data to contain within the Dataset JSON file. Written to
#'   the itemData parameter.
#' @param file_oid fileOID parameter, defined as "A unique identifier for this
#'   file." (optional)
#' @param last_modified The date/time the source database was last modified
#'   before creating the Dataset-JSON file (optional)
#' @param originator originator parameter, defined as "The organization that
#'   generated the Dataset-JSON file." (optional)
#' @param sys sourceSystem.name parameter, defined as "The computer system or
#'   database management system that is the source of the information in this
#'   file." (Optional, required if coupled with sys_version)
#' @param sys_version sourceSystem.Version, defined as "The version of the
#'   sourceSystem" (Optional, required if coupled with sys)
#' @param study Study OID value (optional)
#' @param metadata_version Metadata version OID value (optional)
#' @param metadata_ref Metadata reference (i.e. path to Define.xml) (optional)
#' @param item_oid ID used to label dataset with the itemGroupData parameter.
#'   Defined as "Object of Datasets. Key value is a unique identifier for
#'   Dataset, corresponding to ItemGroupDef/@OID in Define-XML."
#' @param name Dataset name
#' @param dataset_label Dataset Label
#' @param version The DatasetJSON version to use. Currently only 1.1.0 is
#'   supported.
#' @param columns Variable level metadata for the Dataset JSON object. See
#'   details for format requirements.
#'
#' @return dataset_json object pertaining to the specific Dataset JSON version
#'   specific
#' @export
#' @md
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
#' ds_json <- dataset_json(iris, columns = iris_items)
#' ds_json <- set_file_oid(ds_json, "/some/path")
#' ds_json <- set_last_modified(ds_json, "2025-01-21T13:34:50")
#' ds_json <- set_originator(ds_json, "Some Org")
#' ds_json <- set_source_system(ds_json, "source system", "1.0")
#' ds_json <- set_study_oid(ds_json, "SOMESTUDY")
#' ds_json <- set_metadata_ref(ds_json, "some/define.xml")
#' ds_json <- set_metadata_version(ds_json, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' ds_json <- set_item_oid(ds_json, "IG.IRIS")
#' ds_json <- set_dataset_name(ds_json, "Iris")
#' ds_json <- set_dataset_label(ds_json, "The Iris Dataset")
dataset_json <- function(.data, file_oid=NULL, last_modified=NULL,
                          originator=NULL, sys=NULL, sys_version = NULL,
                          study=NULL, metadata_version=NULL,metadata_ref=NULL,
                          item_oid=NULL, name=NULL, dataset_label=NULL,
                          columns=NULL, version="1.1.0") {
  new_dataset_json(.data, file_oid, last_modified, originator, sys, sys_version, study,
                   metadata_version, metadata_ref, item_oid, name, dataset_label,
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
                             columns, version) {

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
                   columns)
}

#' Dataset JSON v1.1.0 Generator
#'
#' @return datasetjson_v1_1_0 object
#' @noRd
new_dataset_json_v1_1_0 <- function(.data, file_oid, last_modified, originator, sys, sys_version,
                                    study, metadata_version, metadata_ref, item_oid, name,
                                    dataset_label, columns) {

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
  if (!is.null(columns)) {
    validate_dataset_columns(columns)
  }
  attr(.data, 'columns') <- set_column_metadata(columns)

  structure(
    .data,
    class = c("datasetjson_v1_1_0", "datasetjson", "data.frame")
  )
}
