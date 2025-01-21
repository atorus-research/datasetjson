#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting
#'
#' @return NULL when file written to disk, otherwise character string
#' @export
#'
#' @examples
#' # Write to character object
#' ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
#' js <- write_dataset_json(ds_json, iris_items)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_json(ds_json, "path/to/file.json")
#' }
write_dataset_json <- function(x, file, pretty=FALSE) {
  stopifnot_datasetjson(x)

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
    "label",
    "columns")
    ]

  # add ITEMGROUPDATASEQ to data
  x <- cbind(ITEMGROUPDATASEQ = 1:records, x)

  # add data rows
  temp$rows <- unname(x)

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

  if (!missing(file)) {
    # Write file to disk
    yyjsonr::write_json_file(
      temp,
      filename = file,
      opts = json_opts
    )
  } else {
    # Print to console
    yyjsonr::write_json_str(
      temp,
      opts = json_opts
    )
  }
}
