#' Create the data metadata container for a Dataset JSON object
#'
#' @param study Study OID value
#' @param metadata_version Metadata version OID value
#' @param metadata_ref Metadata reference (i.e. path to Define.xml)
#'
#' @return data_metadata object
#' @export
#'
#' @examples
#' # Create object directly
#' data_meta <- data_metadata(
#'   study = "SOMESTUDY",
#'   metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
#'   metadata_ref = "some/define.xml"
#' )
#'
#' # Use setter functions
#' data_meta <- data_metadata()
#' data_meta_updated <- set_metadata_ref(data_meta, "some/define.xml")
#' data_meta_updated <- set_metadata_version(data_meta_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' data_meta_updated <- set_study_oid(data_meta_updated, "SOMESTUDY")
#'
data_metadata <- function(study = NULL, metadata_version = NULL, metadata_ref = NULL) {

  x <- list(
    studyOID = study,
    metaDataVersionOID = metadata_version,
    metaDataRef = metadata_ref,
    itemGroupData = NULL
  )

  structure(
    x,
    class = c("data_metadata", "list")
  )
}

#' Set data metadata parameters
#'
#' This set of functions
#' @param x data metadata or datasetjson object
#' @param study Study OID value
#' @param ... Additional parameters
#'
#' @return A datasetjson or data_metadata object
#' @export
#'
#' @family Data metadata setters
#' @rdname data_metadata_setters
#'
#' @examples
#' data_meta <- data_metadata()
#' data_meta_updated <- set_metadata_ref(data_meta, "some/define.xml")
#' data_meta_updated <- set_metadata_version(data_meta_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
#' data_meta_updated <- set_study_oid(data_meta_updated, "SOMESTUDY")
set_study_oid <- function(x, study, ...) {
  UseMethod("set_study_oid")
}

#' @export
#' @noRd
set_study_oid.data_metadata <- function(x, study, ...) {
  x[['studyOID']] <- study
  x
}

#' @export
#' @noRd
set_study_oid.datasetjson <- function(x, study, ...) {
  data_type <- get_data_type(x)
  x[[data_type]][['studyOID']] <- study
  x
}

#' @export
#' @noRd
set_study_oid.default <- function(x, study, ...) {
  stopifnot_data_metadata(x)
}

#' @param metadata_version Metadata version OID value
#' @family Data metadata setters
#' @rdname data_metadata_setters
#' @export
set_metadata_version <- function(x, metadata_version, ...) {
  UseMethod("set_metadata_version")
}

#' @export
#' @noRd
set_metadata_version.data_metadata <- function(x, metadata_version, ...) {
  x[['metaDataVersionOID']] <- metadata_version
  x
}

#' @export
#' @noRd
set_metadata_version.datasetjson <- function(x, metadata_version, ...) {
  data_type <- get_data_type(x)
  x[[data_type]][['metaDataVersionOID']] <- metadata_version
  x
}

#' @export
#' @noRd
set_metadata_version.default <- function(x, metadata_version, ...) {
  stopifnot_data_metadata(x)
}

#' @param metadata_ref Metadata reference (i.e. path to Define.xml)
#' @family Data metadata setters
#' @rdname data_metadata_setters
#' @export
set_metadata_ref <- function(x, metadata_ref) {
  UseMethod("set_metadata_ref")
}

#' @export
#' @noRd
set_metadata_ref.data_metadata <- function(x, metadata_ref) {
  x[['metaDataRef']] <- metadata_ref
  x
}

#' @export
#' @noRd
set_metadata_ref.datasetjson <- function(x, metadata_ref) {
  data_type <- get_data_type(x)
  x[[data_type]][['metaDataRef']] <- metadata_ref
  x
}

#' @export
#' @noRd
set_metadata_ref.default <- function(x, metadata_ref) {
  stopifnot_data_metadata(x)
}
