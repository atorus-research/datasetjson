#' Write out a Dataset JSON file
#'
#' @param x datasetjson object
#' @param file File path to save Dataset JSON file
#' @param pretty If TRUE, write with readable formatting. *Note: The Dataset
#'   JSON standard prefers compressed formatting without line feeds. It is not
#'   recommended you use pretty printing for submission purposes.*
#' @param float_as_decimals If TRUE, Convert float variables to "decimal" data
#'   type in the JSON output. This will manually convert the numeric values
#'   using the `format()` function using the number of digits specified in
#'   `digits`, bypassing the `yyjsonr` handling of float values and writing the
#'   numbers out as JSON character strings. See the [Dataset JSON user
#'   guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding) for more
#'   information. Defaults to FALSE
#' @param digits When using `float_as_decimals`, the number of digits to use
#'   when writing out floats. Going higher than 16 may start writing otherwise
#'   sufficiently precise decimals (i.e. .2) to long strings.
#'
#' @return NULL when file written to disk, otherwise character string
#' @export
#'
#' @examples
#' # Write to character object
#' ds_json <- dataset_json(
#'   iris,
#'   item_oid = "IG.IRIS",
#'   name = "IRIS",
#'   dataset_label = "Iris",
#'   columns = iris_items
#' )
#' js <- write_dataset_json(ds_json)
#'
#' # Write to disk
#' \dontrun{
#'   write_dataset_json(ds_json, "path/to/file.json")
#' }
write_dataset_json <- function(x, file, pretty=FALSE, float_as_decimals=FALSE, digits=16) {

  prepared <- prepare_dataset_for_write(x, float_as_decimals, digits)
  temp <- prepared$meta

  # add data rows
  temp$rows <- unname(prepared$data)

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

stop_write_error <- function(varname, msg){
  stop(
    sprintf(paste(
      "Please check the variable %s.",
      msg,
      sep="\n  "),
      varname)
  )
}
