#' Read a Dataset JSON to datasetjson object
#'
#' This function validates a dataset JSON file against the Dataset JSON schema,
#' and if valid returns a datasetjson object. The Dataset JSON file can be
#' either a file path on disk of a URL which contains the Dataset JSON file.
#'
#' @param file File path or URL of a Dataset JSON file
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#' # Read from disk
#' \dontrun{
#'   dat <- read_dataset_json("path/to/file.json")
#'  # Read file from URL
#'   dat <- dataset_json('https://www.somesite.com/file.json')
#' }
#'
#' # Read from an already imported character vector
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
#' js <- write_dataset_json(ds_json)
#' dat <- read_dataset_json(js)
read_dataset_json <- function(file) {

  json_opts <- yyjsonr::opts_read_json(
    promote_num_to_string = TRUE
  )

  if (path_is_url(file)) {
    # Url?
    file_contents <- read_from_url(file)
    ds_json <- yyjsonr::read_json_str(
      file_contents,
      opts = json_opts
    )
  } else if (file.exists(file)) {
    # File on disk?
    ds_json <- yyjsonr::read_json_file(
      file,
      opts = json_opts
    )
  } else {
    # Direct file contents?
    ds_json <- yyjsonr::read_json_str(
      file,
      opts = json_opts
    )
  }

  # Pull the data and items
  d <- as.data.frame(ds_json$rows)
  items <- ds_json$columns

  # Start setting attributes
  colnames(d) <- items$name

  # Process type conversions
  dt <- items$dataType
  tdt <- items$targetDataType
  int_cols <- dt == "integer"
  dbl_cols <- dt %in% c("float", "double", "decimal")
  bool_cols <- dt == "boolean"
  d[int_cols] <- lapply(d[int_cols], as.integer)
  d[dbl_cols] <- lapply(d[dbl_cols], as.double)
  d[bool_cols] <- lapply(d[bool_cols], as.logical)

  d <- date_time_conversions(d, dt, tdt)

  # Apply variable labels
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)

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
  if(ds_json$records != nrow(d)) {
    warning("The number of rows in the data does not match the number of records recorded in the metadata.")
  }

  attr(ds_attr, 'records') <- ds_json$records
  attr(ds_attr, 'datasetJSONCreationDateTime') <- ds_json$datasetJSONCreationDateTime

  ds_attr
}
