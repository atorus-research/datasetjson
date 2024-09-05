#' Dataset Metadata Setters
#'
#' Set information about the file, source system, study, and dataset used to generate the Dataset
#' JSON object.
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
#' @param name Dataset name
#' @param dataset_label Dataset Label
#'
#' @return datasetjson object
#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
#'
#' @examples
#' ds_json <- dataset_json(iris)
#' 
#' ds_json <- set_dataset_metadata(
#'   iris, 
#'   file_oid = "/some/path"
#'   originator = "Some Org", 
#'   sys = "source system", 
#'   sys_version = "1.0", 
#'   study = "SOMESTUDY",
#'   metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
#'   metadata_ref = "some/define.xml",
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris"
#' )
#'
#' # Individual Elements
#' ds_json <- dataset_json(iris)
#' ds_json <- set_file_oid(ds_json, "/some/path")
#' ds_json <- set_study_oid(ds_json, "SOMESTUDY")
#' ds_json <- set_originator(ds_json, "Some Org")
#' ds_json <- set_source_system(ds_json, "source system", "1.0")
#' ds_json <- set_metadata_ref(ds_json, "some/define.xml")
#' ds_json <- set_metadata_version(ds_json, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' ds_json <- set_item_oid(ds_json, "IG.IRIS")
#' ds_json <- set_dataset_name(ds_json, "IRIS")
#' ds_json <- set_dataseT_label(ds_json, "Iris")
set_dataset_metadata <- function(x, file_oid = NULL, originator=NULL, sys = NULL, 
                                 sys_version = NULL, study=NULL, metadata_version=NULL,
                                 metadata_ref=NULL, item_oid=NULL, name = NULL, 
                                 dataset_label=NULL) {
  stopifnot_datasetjson(x)

  if (!is.null(sys) && !is.null(sys_version)) {
    attr(x, 'sourceSystem') <- list(
      "name" = sys,
      "version" = sys_version
    )
  }

  attr(x, 'fileOID') <- file_oid
  attr(x, 'originator') <- originator
  attr(x, 'studyOID') <- study
  attr(x, 'metaDataVersionOID') <- metadata_version
  attr(x, 'metaDataRef') <- metadata_ref
  attr(x, "itemGroupOID") <- item_oid
  attr(x, 'records') <- nrow(x)
  attr(x, 'name') <- name
  attr(x, 'label') <- dataset_label
  attr('isReferenceData') <- FALSE
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_source_system <- function(x, sys, sys_version) {
  stopifnot_datasetjson(x)
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
  attr(x, 'originator') <- originator
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_file_oid <- function(x, file_oid) {
  stopifnot_datasetjson(x)
  attr(x, 'fileOID') <- file_oid
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_study_oid <- function(x, study) {
  stopifnot_datasetjson(x)
  attr(x, 'studyOID') <- study
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_metadata_version <- function(x, metadata_version) {
  stopifnot_datasetjson(x)
  attr(x, 'metaDataVersionOID') <- metadata_version
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_metadata_ref <- function(x, metadata_ref) {
  stopifnot_datasetjson(x)
  attr(x, 'metaDataRef') <- metadata_ref
  x
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_item_oid <- function(x, item_oid) {
  stopifnot_datasetjson(x)
  attr(x, "itemGroupOID") <- item_oid
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_dataset_name <- function(x, name) {
  stopifnot_datasetjson(x)
  attr(x, 'name') <- name
}

#' @export
#' @family Dataset Metadata Setters
#' @rdname dataset_metadata_setters
set_dataset_label <- function(x, dataset_label) {
  stopifnot_datasetjson(x)
  attr(x, 'label') <- dataset_label
}

#' Declare as reference data
#' 
#' Sets DatasetJSON file to have the isReferenceData attribute set to TRUE
#' 
#' @param x datasetjson object
#' 
#' @return datasetjson object
#' @export
#' 
#' @examples
#' ds_json <- dataset_json(iris)
#' ds_json <- set_as_reference_data(ds_json)
set_as_reference_data <- function(x) {
  stopifnot_datasetjson(x)
  attr(x, 'isReferenceData') <- TRUE
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
