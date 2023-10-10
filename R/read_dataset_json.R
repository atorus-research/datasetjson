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

  if (path_is_url(file)) {
    # Url?
    file_contents <- read_from_url(file)
  } else if (file.exists(file)) {
    # File on disk?
    file_contents <- readLines(file)
  } else {
    # Direct file contents?
    file_contents <- file
  }

  # Validate the input file against the schema
  valid <- jsonvalidate::json_validate(file_contents, schema = schema_1_0_0, engine="ajv")

  if (!valid) {
    stop(paste0(c("Dataset JSON file is invalid per the JSON schema. ",
                "Run datasetjson::validate_dataset_json(",substitute(file),") to see details")),
      call.=FALSE)
  }

  # Read the file and convert to datasetjson object
  ds_json <- jsonlite::fromJSON(file_contents)

  # Pull the object out with a lot of assumptions because the format has already
  # been validated
  dtype <- ifelse("clinicalData" %in% names(ds_json), "clinicalData", "referenceData")
  d <- as.data.frame(ds_json[[dtype]]$itemGroupData[[1]]$itemData)
  items <- ds_json[[dtype]]$itemGroupData[[1]]$items

  # Start setting attributes
  colnames(d) <- items$name

  # Process type conversions
  tt <- items$type
  int_cols <- tt == "integer"
  dbl_cols <- tt %in% c("float", "double", "decimal")
  bool_cols <- tt == "boolean"
  d[int_cols] <- lapply(d[int_cols], as.integer)
  d[dbl_cols] <- lapply(d[dbl_cols], as.double)
  d[bool_cols] <- lapply(d[bool_cols], as.logical)

  # Grab date and datetime column info
  fmts <- items$displayFormat
  date_cols <- fmts %in% sas_date_formats
  datetime_cols <- fmts %in% sas_datetime_formats
  d[date_cols] <- lapply(d[date_cols], as.Date, origin="1960-01-01")
  d[datetime_cols] <- lapply(d[datetime_cols], as.POSIXct, origin="1960-01-01")

  # Apply variable labels
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'label', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'OID', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'length', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'type', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'keySequence', items)
  d[names(d)] <- lapply(items$name, set_col_attr, d, 'displayFormat', items)

  d <- d[,-1] # get rid of ITEMGROUPDATASEQ column

  # Apply file and data level attributes
  attr(d, 'creationDateTime') <- ds_json$creationDateTime
  attr(d, 'datasetJSONVersion') <- ds_json$datasetJSONVersion
  attr(d, 'fileOID') <- ds_json$fileOID
  attr(d, 'asOfDateTime') <- ds_json$asOfDateTime
  attr(d, 'originator') <- ds_json$originator
  attr(d, 'sourceSystem') <- ds_json$sourceSystem
  attr(d, 'sourceSystemVersion') <- ds_json$sourceSystemVersion
  attr(d, 'name') <-ds_json[[dtype]]$itemGroupData[[1]]$name
  attr(d, 'records') <-ds_json[[dtype]]$itemGroupData[[1]]$records
  attr(d, 'label') <-ds_json[[dtype]]$itemGroupData[[1]]$label

  # Still save the name of the element storing the dataset metadata
  ds_json[[dtype]]$itemGroupData <- names(ds_json[[dtype]]$itemGroupData)

  # Store the data metadata still within it's own list
  attr(d, dtype) <- ds_json[[dtype]]
  d
}
