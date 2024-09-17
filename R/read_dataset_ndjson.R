#' Read a Dataset NDJSON to datasetjson object
#'
#' This function reads a dataset NDJSON file andreturns a datasetjson object.
#' The Dataset NDJSON file can be either a file path on disk of a URL which
#' contains the Dataset NDJSON file.
#'
#' @param file File path or URL of a Dataset NDJSON file
#'
#' @return datasetjson object
#' @export
#'
#' @examples
#' # Read from disk
#' \dontrun{
#'   dat <- read_dataset_ndjson("path/to/file.ndjson")
#'  # Read file from URL
#'   dat <- read_dataset_ndjson('https://www.somesite.com/file.ndjson')
#' }
#'
#' # Read from an already imported character vector
#' ds_ndjson <- dataset_json(
#'   iris[1:5, ],
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
#'   dataset_label = "Iris"
#' )
#' js <- write_dataset_ndjson(ds_ndjson, item = iris_items)
#' dat <- read_dataset_ndjson(js)
read_dataset_ndjson <- function(file) {

  json_opts <- yyjsonr::opts_read_json(
    promote_num_to_string = TRUE
  )

  if (path_is_url(file)) {
    # Url?
    file_contents <- read_from_url(file)
    d <- yyjsonr::read_ndjson_str(
      file_contents,
      nskip = 1,
      opts = json_opts
    )
    d_meta <- yyjsonr::read_ndjson_str(
      file_contents,
      nread = 1,
      nprobe = 1,
      opts = json_opts
    )
  } else if (file.exists(file)) {
    # File on disk?
    d <- yyjsonr::read_ndjson_file(
      file,
      nskip = 1,
      opts = json_opts
    )
    d_meta <- yyjsonr::read_ndjson_file(
      file,
      nread = 1,
      nprobe = 1,
      opts = json_opts
    )
  } else {
    # Direct file contents?
    d <- yyjsonr::read_ndjson_str(
      file,
      nskip = 1,
      opts = json_opts
    )
    d_meta <- yyjsonr::read_ndjson_str(
      file,
      nread = 1,
      nprobe = 1,
      opts = json_opts
    )
  }


  # Pull the data and items
  # d <- as.data.frame(do.call(rbind, ds_ndjson_list))
  items <- d_meta$columns[[1]]

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

  # Apply variable labels
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)

  d <- d[,-1] # get rid of ITEMGROUPDATASEQ column

  ds_attr <- dataset_json(
    d,
    file_oid = d_meta$fileOID,
    originator = d_meta$originator,
    sys = d_meta$sourceSystem$name,
    sys_version = d_meta$sourceSystem$version,
    study = d_meta$studyOID,
    metadata_version = d_meta$metaDataVersionOID,
    metadata_ref = d_meta$metaDataRef,
    item_oid = d_meta$itemGroupOID,
    name = d_meta$name,
    dataset_label = d_meta$label,
    ref_data = d_meta$isReferenceData,
    last_modified = d_meta$dbLastModifiedDateTime,
    version = d_meta$datasetJSONVersion
  )

  # Apply records and column attribute
  if(d_meta$records != nrow(d)) {
    warning("The number of rows in the data does not match the number of records recorded in the metadata.")
  }

  attr(ds_attr, 'records') <- d_meta$records
  attr(ds_attr, 'columns') <- d_meta$columns

  ds_attr
}
