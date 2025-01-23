#' Dataset Metadata Setters
#'
#' Set information about the file, source system, study, and dataset used to
#' generate the Dataset JSON object.
#'
#' @details
#'
#' The fileOID parameter should be structured following description outlined in
#' the ODM V2.0 specification. "FileOIDs should be universally unique if at all
#' possible. One way to ensure this is to prefix every FileOID with an internet
#' domain name owned by the creator of the ODM file or database (followed by a
#' forward slash, "/"). For example,
#' FileOID="BestPharmaceuticals.com/Study5894/1" might be a good way to denote
#' the first file in a series for study 5894 from Best Pharmaceuticals."
#'
#' @param x datasetjson object
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
#'
#' @return datasetjson object
#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
#'
#' @examples
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
set_source_system <- function(x, sys, sys_version) {
  stopifnot_datasetjson(x)
  if (!is.character(sys)) {
    stop("`sys` must be a character")
  }
  if (!is.character(sys_version)) {
    stop("`sys_version` must be a character")
  }
  attr(x, 'sourceSystem') <- list(
    "name" = sys,
    "version" = sys_version
  )
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_originator <- function(x, originator) {
  stopifnot_datasetjson(x)
  if (!is.character(originator)) {
    stop("`originator` must be a character")
  }
  attr(x, 'originator') <- originator
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_file_oid <- function(x, file_oid) {
  stopifnot_datasetjson(x)
  if (!is.character(file_oid)) {
    stop("`file_oid` must be a character")
  }
  attr(x, 'fileOID') <- file_oid
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_study_oid <- function(x, study) {
  stopifnot_datasetjson(x)
  if (!is.character(study)) {
    stop("`study` must be a character")
  }
  attr(x, 'studyOID') <- study
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_metadata_version <- function(x, metadata_version) {
  stopifnot_datasetjson(x)
  if (!is.character(metadata_version)) {
    stop("`metadata_version` must be a character")
  }
  attr(x, 'metaDataVersionOID') <- metadata_version
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_metadata_ref <- function(x, metadata_ref) {
  stopifnot_datasetjson(x)
  if (!is.character(metadata_ref)) {
    stop("`metadata_ref` must be a character")
  }
  attr(x, 'metaDataRef') <- metadata_ref
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_item_oid <- function(x, item_oid) {
  stopifnot_datasetjson(x)
  if (!is.character(item_oid)) {
    stop("`item_oid` must be a character")
  }
  attr(x, "itemGroupOID") <- item_oid
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_dataset_name <- function(x, name) {
  stopifnot_datasetjson(x)
  if (!is.character(name)) {
    stop("`name` must be a character")
  }
  attr(x, 'name') <- name
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_dataset_label <- function(x, dataset_label) {
  stopifnot_datasetjson(x)
  if (!is.character(dataset_label)) {
    stop("`dataset_label` must be a character")
  }
  attr(x, 'label') <- dataset_label
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_last_modified <- function(x, last_modified) {
  stopifnot_datasetjson(x)
  if (!is.character(last_modified)) {
    stop("`last_modified` must be a character")
  }
  attr(x, 'dbLastModifiedDateTime') <- last_modified
  x
}

#' Create an ISO8601 formatted datetime of the current time
#'
#' This is used to create the creationDateTime and asOfDateTime attributes of
#' the Dataset JSON object, called at the appropriate time for each attribute
#'
#' @return ISO8601 formatted datetime
#' @noRd
get_datetime <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
}
