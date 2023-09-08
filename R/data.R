#' Example Variable Metadata for Iris
#'
#' Example of the necessary variable metadata included in a Dataset JSON file
#' based on the Iris data frame.
#'
#' @format ## `iris_items` A data frame with 5 rows and 6 columns:
#' \describe{
#'   \item{OID}{Unique identifier for Variable. Must correspond to ItemDef/@OID in Define-XML.}
#'   \item{name}{Display format supports data visualization of numeric float and date values.}
#'   \item{label}{Label for Variable}
#'   \item{type}{Data type for Variable}
#'   \item{length}{Length for Variable}
#'   \item{keySequence}{Indicates that this item is a key variable in the dataset structure. It also provides an ordering for the keys.}
#'   \item{displayFormat}{Display format supports data visualization of numeric float and date values.}
#' }
"iris_items"
