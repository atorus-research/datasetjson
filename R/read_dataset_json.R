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
  tt <- items$dataType
  tdt <- items$targetDataType
  int_cols <- tt == "integer"
  dbl_cols <- tt %in% c("float", "double", "decimal")
  bool_cols <- tt == "boolean"
  d[int_cols] <- lapply(d[int_cols], as.integer)
  d[dbl_cols] <- lapply(d[dbl_cols], as.double)
  d[bool_cols] <- lapply(d[bool_cols], as.logical)

  date_cols <- tt %in% c("date") & tdt %in% "integer"
  datetime_cols <- tt %in% c("datetime", "time") & tdt %in% "integer"
  d[date_cols] <- lapply(d[date_cols], as.Date)
  d[datetime_cols] <- lapply(d[datetime_cols], as.POSIXct)

  # Apply variable attributes
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'itemOID', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'length', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'dataType', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'targetDataType', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'keySequence', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'displayFormat', items)

  d <- d[,-1] # get rid of ITEMGROUPDATASEQ column

  # Apply file and data level attributes
  attr(d, 'datasetJSONCreationDateTime') <- ds_json$creationDateTime
  attr(d, 'datasetJSONVersion') <- ds_json$datasetJSONVersion
  attr(d, 'fileOID') <- ds_json$fileOID
  attr(d, 'dbLastModifiedDateTime') <- ds_json$asOfDateTime
  attr(d, 'originator') <- ds_json$originator
  attr(d, 'sourceSystem') <- ds_json$sourceSystem
  attr(d, 'name') <- ds_json[["name"]]
  attr(d, 'records') <- ds_json[["records"]]
  attr(d, 'label') <- ds_json[["label"]]

  d
}
