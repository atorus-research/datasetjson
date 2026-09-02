#'Read a Dataset JSON to datasetjson object
#'
#'This function validates a dataset JSON file against the Dataset JSON schema,
#'and if valid returns a datasetjson object. The Dataset JSON file can be either
#'a file path on disk of a URL which contains the Dataset JSON file.
#'
#'@details
#'
#'The resulting dataframe contains the additional metadata available on the
#'Dataset JSON file within the attributes to make this accessible to the user.
#'Note that these attributes are only populated if available.
#' - **sourceSystem**: The information system from which the content of this
#'dataset was source, including system name and version.
#' - **datasetJSONVersion**: The version of the Dataset-JSON standard used to
#'create the dataset.
#' - **fileOID**: A unique identifier for this dataset.
#' - **dbLastModifiedDateTime**: The date/time the source database was last
#'modified before creating the Dataset-JSON file.
#' - **originator**: The organization that generated the Dataset-JSON dataset.
#' - **studyOID**: Unique identifier for the study that may also function as a
#'foreign key to a Study/@OID in an associated Define-XML document, or to any
#'studyOID references that are used as keys in other documents;
#' - **metaDataVersionOID**: Unique identifier for the metadata version that may
#'also function as a foreign key to a MetaDataVersion/@OID in an associated
#'Define-XML file
#' - **metaDataRef**: URI for the metadata file describing the dataset (e.g.,
#'a Define-XML file).
#' - **itemGroupOID**: Unique identifier for the dataset that may also function
#'as a foreign key to an ItemGroupDef/@OID in an associated Define-XML file.
#' - **name**: The human-readable name for the dataset.
#' - **label**: A short description of the dataset.
#' - **columns**: An array of metadata objects that describe the dataset
#'variables. See `dataset_json()` for further information on the contents of
#'these fields.
#'
#'@param file File path or URL of a Dataset JSON file
#'
#'@return A dataframe with additional attributes attached containing the
#'  DatasetJSON metadata.
#'@export
#'
#' @examples
#' # Read from disk
#' dat <- read_dataset_json(datasetjson_example("dm.json"))
#'
#' # Read from a URL
#' \dontrun{
#'   dat <- read_dataset_json('https://www.somesite.com/file.json')
#' }
#'
#' # Read from an already imported character vector
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", columns=iris_items)
#' js <- write_dataset_json(ds_json)
#' dat <- read_dataset_json(js)
read_dataset_json <- function(file) {

  if (path_is_url(file)) {
    # Url?
    parsed <- .Call(C_read_dsjson_str, read_from_url(file))
  } else if (file.exists(file)) {
    # File on disk?
    parsed <- .Call(C_read_dsjson_file, file)
  } else {
    # Direct file contents?
    parsed <- .Call(C_read_dsjson_str, file)
  }

  build_datasetjson(parsed)
}

#' Assemble a datasetjson object from the native parser output
#'
#' Shared by the JSON and NDJSON readers - both hand back the same list of
#' metadata, column definitions and already-typed data columns.
#'
#' @param parsed The list returned by the C reader
#'
#' @return A datasetjson object
#' @noRd
build_datasetjson <- function(parsed) {
  ds_json <- parsed
  # C returns column metadata as a list of equal-length vectors
  ds_json$columns <- as.data.frame(ds_json$columns, stringsAsFactors = FALSE)
  items <- ds_json$columns

  # Columns arrive from C already typed from the `columns` metadata - integers
  # as integer, float/double/decimal as double parsed in C. Numbers never pass
  # through as.double(), which is not correctly rounded (see #97).
  d <- ds_json$data
  attr(d, "row.names") <- .set_row_names(length(d[[1L]]))
  class(d) <- "data.frame"

  # Date/time class construction stays in R; C delivers the primitive type
  dt <- items$dataType
  tdt <- items$targetDataType
  d <- date_time_conversions(d, dt, tdt)

  # Apply variable labels
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)

  # Apply SAS format from displayFormat
  if (!is.null(items$displayFormat)) {
    # Iterate only over columns that have a displayFormat value
    for (nm in items$name[!is.na(items$displayFormat)]) {
      # Set format.sas directly from items metadata (recognized by haven and
      # SAS-aware tools)
      attr(d[[nm]], 'format.sas') <- items$displayFormat[items$name == nm]
    }
  }

  ds_attr <- dataset_json(
    d,
    file_oid = ds_json$fileOID,
    originator = ds_json$originator,
    sys = ds_json$sourceSystem$name,
    sys_version = ds_json$sourceSystem$version,
    study = ds_json$studyOID,
    metadata_version = ds_json$metaDataVersionOID,
    metadata_ref = ds_json$metaDataRef,
    item_oid = ds_json$itemGroupOID,
    name = ds_json$name,
    dataset_label = ds_json$label,
    last_modified = ds_json$dbLastModifiedDateTime,
    version = ds_json$datasetJSONVersion,
    columns = ds_json$columns
  )

  # Apply records and column attribute
  if (is.null(ds_json$records)) {
    # `records` is required by the Dataset JSON standard, so its absence means
    # the source file is incomplete. Fall back to the row count, but say so -
    # without it there is nothing to check the data against.
    warning(
      "The source file does not contain a `records` value, which the Dataset ",
      "JSON standard requires. It has been set to the number of rows read (",
      nrow(d), "), so the row count could not be verified against the file ",
      "metadata.",
      call. = FALSE
    )
    ds_json$records <- nrow(d)
  }
  if (ds_json$records != nrow(d)) {
    warning(
      "The number of rows in the data does not match the number of records ",
      "recorded in the metadata."
    )
  }

  attr(ds_attr, 'records') <- ds_json$records
  attr(ds_attr, 'datasetJSONCreationDateTime') <- ds_json$datasetJSONCreationDateTime

  ds_attr
}
