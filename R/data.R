#' Example Variable Metadata for Iris
#'
#' Example of the necessary variable metadata included in a Dataset JSON file
#' based on the Iris data frame.
#'
#' @format ## `iris_items` A data frame with 5 rows and 6 columns:
#' \describe{
#'   \item{itemOID}{Unique identifier for Variable. Must correspond to ItemDef/@OID in Define-XML.}
#'   \item{name}{Display format supports data visualization of numeric float and date values.}
#'   \item{label}{Label for Variable}
#'   \item{dataType}{Data type for Variable}
#'   \item{length}{Length for Variable}
#'   \item{keySequence}{Indicates that this item is a key variable in the dataset structure. It also provides an ordering for the keys.}
#' }
"iris_items"

#' Dataset JSON Schema Version 1.1.0
#'
#' This object is a character vector holding the schema for Dataset JSON Version 1.1.0
#'
#' @format ## `schema_1_1_0`
#' \describe{
#'   A character vector with 1 element
#' }
"schema_1_1_0"
