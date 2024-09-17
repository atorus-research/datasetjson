#' Write out a Dataset NDJSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset NDJSON file
#' @param pretty If TRUE, write with readable formatting
#' @param items Variable metadata
#'
#' @return NULL when file written to disk, otherwise character string
#' @export
#'
#' @examples
#' # Write to character object
#' ds_json <- dataset_json(
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
#' js <- write_dataset_ndjson(ds_json, items=iris_items)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_ndjson(ds_json, file = "path/to/file.ndjson", items=iris_items)
#' }
write_dataset_ndjson <- function(x, file, pretty=FALSE, items) {

  stopifnot_datasetjson(x)

  if (!missing(file)) {
    # Make sure the output path exists
    if(!dir.exists(dirname(file))) {
      stop("Folder supplied to `file` does not exist", call.=FALSE)
    }
  }

  # Create the JSON text
  json_opts <- yyjsonr::opts_write_json(
    pretty = pretty,
    auto_unbox = TRUE,
  )

  # Populate the creation datetime
  attr(x, 'datasetJSONCreationDateTime') <- get_datetime()

  # Store number of records
  records <- nrow(x)
  attr(x, 'records') <- records

  # Pull attributes into a list and order
  temp <- attributes(x)[c(
    "datasetJSONCreationDateTime",
    "datasetJSONVersion",
    "fileOID",
    "dbLastModifiedDateTime",
    "originator",
    "sourceSystem",
    "studyOID",
    "metaDataVersionOID",
    "metaDataRef",
    "itemGroupOID",
    "isReferenceData",
    "records",
    "name",
    "label")
    ]

  # add column metadata
  temp2 <- list(c(temp, columns = list(variable_metadata(items))))

  # ndjson string for metadata
  metadata_ndjson <- yyjsonr::write_ndjson_str(
    temp2,
    opts = json_opts
  )

  # add ITEMGROUPDATASEQ to data
  x <- cbind(ITEMGROUPDATASEQ = 1:records, x)

  # ndjson string for data
  data_ndjson <- yyjsonr::write_ndjson_str(
    x,
    opts = json_opts
  )

  if (!missing(file)) {
    # Write file to disk
    cat(metadata_ndjson, data_ndjson, file = file, sep = "\n")
  } else {
    # Return string
    y = capture.output(cat(metadata_ndjson, data_ndjson, sep = "\n"))
    paste0(y, collapse = '\n')
  }
}
