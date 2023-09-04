# Code provided by Tilo Blenk on 2022-11-28


#' Read dataset-json file with data of one SDTM/ADaM domain into data frame
#'
#' Read dataset-json file with data of one SDTM/ADaM domain into data frame.
#'
#' @param path path to dataset-json file
#' @return data frame with data of dataset-json file
#' @export
#' @import jsonlite
#' @examples
#' \dontrun{
#' dm <- read_dataset_json("path/to/dm.json")
#' }
read_dataset_json <- function(path) {
  j <- fromJSON(path)
  x <- names(j$clinicalData$itemGroupData)

  # re-create data frame with correct data types
  # length is ignored at the moment but could be used for rounding
  # of numerical values and padding of string values
  d <- as.data.frame(j$clinicalData$itemGroupData[[x]]$itemData)
  colnames(d) <- j$clinicalData$itemGroupData[[x]]$items$name
  tt <- j$clinicalData$itemGroupData[[x]]$items$type
  for (i in seq_along(tt)) {
    if (tolower(tt[i]) %in% c("integer", "int")) {
      d[,i] <- as.integer(d[,i])
    } else if (tolower(tt[i]) %in% c("float", "numeric", "num", "double", "double precision")) {
      d[,i] <- as.double(d[,i])
    }
    # everything not being integer, double, or numeric is considered as character
  }
  d[,-1] # get rid of ITEMGROUPDATASEQ column
}


#' Write data frame with data of one SDTM/ADaM domain into dataset-json file
#'
#' Write data frame with data of one SDTM/ADaM domain into dataset-json file.
#'
#' @param d data frame with data of one SDTM/ADaM domain
#' @param path path to dataset-json file to write data to
#' @export
#' @import jsonlite
#' @examples
#' \dontrun{
#' write_dataset_json(dm, "path/to/dm.json")
#' }
write_dataset_json <- function(d, path) {
  studyid <- d[1, "STUDYID", drop = TRUE]
  domain <- d[1, "DOMAIN", drop = TRUE]

  # insert sequence number, ie ITEMGROUPDATASEQ, as first column
  x <- colnames(d)
  d$ITEMGROUPDATASEQ <- seq_len(nrow(d))
  d <- d[, c("ITEMGROUPDATASEQ", x)]

  # get metadata, in particular the data type, from the data themselves
  m <- data.frame(
    name = colnames(d),
    type = unname(sapply(d, class))
  )

  # assemble variable description as list for correct formatting with toJSON()
  # the actual domain data can be formatted easily in the right way with
  # toJSON(..., dataframe = "values", ...) but then the variable description
  # need to be assembled as a list for correct formatting
  l <- lapply(seq_len(nrow(m)), function(i) {
    list(
      OID = if (m$name[i] == "ITEMGROUPDATASEQ") m$name[i]
      else paste("IT", m$name[i], sep = "."),
      name = m$name[i],
      # label ???, could come from define-xml
      type = m$type[i])
    # length ???, could come from define-xml
  })

  # assemble data for later formatting to json with toJSON()
  j <- list(
    clinicalData = list(
      studyOID = studyid,
      metaDataVersionOID = "3.1.2",
      itemGroupData = list()
    )
  )
  # needs to be added in a separate step because of dynamic name IT.DOMAIN
  j[["clinicalData"]][["itemGroupData"]][[paste("IT", domain, sep = ".")]] <- list(
    records = nrow(d),
    name = domain,
    # label ???, could come from define-xml
    items = l,
    itemData = d
  )

  # convert data to json by toJSON() and write to file
  cat(toJSON(j, dataframe = "values", na = "null", auto_unbox = TRUE, pretty = TRUE), "\n", file = path)
}
