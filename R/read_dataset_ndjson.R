#' Read a Dataset NDJSON file to datasetjson object
#'
#' This function reads a newline-delimited JSON (NDJSON) file following the
#' Dataset JSON v1.1.0 specification and returns a datasetjson object. Line 1
#' of the file contains the dataset metadata and each subsequent line contains
#' a single data row as a JSON array.
#'
#' @details
#'
#' The resulting dataframe contains the additional metadata available on the
#' Dataset JSON file within the attributes to make this accessible to the user.
#' Note that these attributes are only populated if available.
#'  - **sourceSystem**: The information system from which the content of this
#' dataset was source, including system name and version.
#'  - **datasetJSONVersion**: The version of the Dataset-JSON standard used to
#' create the dataset.
#'  - **fileOID**: A unique identifier for this dataset.
#'  - **dbLastModifiedDateTime**: The date/time the source database was last
#' modified before creating the Dataset-JSON file.
#'  - **originator**: The organization that generated the Dataset-JSON dataset.
#'  - **studyOID**: Unique identifier for the study that may also function as a
#' foreign key to a Study/@OID in an associated Define-XML document, or to any
#' studyOID references that are used as keys in other documents;
#'  - **metaDataVersionOID**: Unique identifier for the metadata version that may
#' also function as a foreign key to a MetaDataVersion/@OID in an associated
#' Define-XML file
#'  - **metaDataRef**: URI for the metadata file describing the dataset (e.g.,
#' a Define-XML file).
#'  - **itemGroupOID**: Unique identifier for the dataset that may also function
#' as a foreign key to an ItemGroupDef/@OID in an associated Define-XML file.
#'  - **name**: The human-readable name for the dataset.
#'  - **label**: A short description of the dataset.
#'  - **columns**: An array of metadata objects that describe the dataset
#' variables. See `dataset_json()` for further information on the contents of
#' these fields.
#'
#' @param file File path or URL of a Dataset NDJSON file, or a character string
#'   containing NDJSON content
#' @param decimals_as_floats Convert variables of "decimal" type to float
#'
#' @return A dataframe with additional attributes attached containing the
#'   DatasetJSON metadata.
#' @export
#'
#' @examples
#' # Read from disk
#' \dontrun{
#'   dat <- read_dataset_ndjson("path/to/file.ndjson")
#' }
#'
#' # Read from an already imported character vector
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", columns=iris_items)
#' ndjson <- write_dataset_ndjson(ds_json)
#' dat <- read_dataset_ndjson(ndjson)
read_dataset_ndjson <- function(file, decimals_as_floats=FALSE) {

  json_opts <- yyjsonr::opts_read_json(
    promote_num_to_string = TRUE
  )

  # Read all lines from source
  if (path_is_url(file)) {
    lines <- read_from_url(file)
  } else if (file.exists(file)) {
    lines <- readLines(file, warn = FALSE)
  } else {
    # Direct string contents
    lines <- strsplit(file, "\n")[[1]]
  }

  # Remove empty trailing lines
  lines <- lines[nzchar(trimws(lines))]

  # Line 1: metadata
  ds_json <- yyjsonr::read_json_str(lines[1], opts = json_opts)

  # Lines 2+: data rows (JSON arrays)
  data_lines <- lines[-1]

  # Reconstruct as a JSON array of arrays so yyjsonr parses it
  # the same way it handles the "rows" element in standard Dataset JSON
  rows_json <- paste0("[", paste(data_lines, collapse = ","), "]")
  ds_json$rows <- yyjsonr::read_json_str(rows_json, opts = json_opts)

  # Pull the data
  d <- as.data.frame(ds_json$rows)

  build_datasetjson_from_parsed(ds_json, d, decimals_as_floats)
}
