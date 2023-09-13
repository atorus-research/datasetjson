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
#'   \item{displayFormat}{Display format supports data visualization of numeric float and date values.}
#'   \item{keySequence}{Indicates that this item is a key variable in the dataset structure. It also provides an ordering for the keys.}
#' }
"iris_items"

#' A List of valid SAS(c) date formats
#'
#' Valid SAS(c) date formats pulled from
#' https://documentation.sas.com/doc/en/vdmmlcdc/8.1/ds2pg/p0bz5detpfj01qn1kz2in7xymkdl.htm
#'
#' @format ## `sas_date_formats`
#' \describe{
#'   A character vector with 45 elements
#' }
"sas_date_formats"

#' A List of valid SAS(c) datetime formats
#'
#' Valid SAS(c) datetime formats pulled from
#' https://documentation.sas.com/doc/en/vdmmlcdc/8.1/ds2pg/p0bz5detpfj01qn1kz2in7xymkdl.htm
#'
#' @format ## `sas_datetime_formats`
#' \describe{
#'   A character vector with 7 elements
#' }
"sas_datetime_formats"

#' A List of valid SAS(c) time formats
#'
#' Valid SAS(c) time formats pulled from
#' https://documentation.sas.com/doc/en/vdmmlcdc/8.1/ds2pg/p0bz5detpfj01qn1kz2in7xymkdl.htm
#'
#' @format ## `sas_time_formats`
#' \describe{
#'   A character vector with 4 elements
#' }
"sas_time_formats"

#' Dataset JSON Schema Version 1.0.0
#'
#' This object is a character vector holding the schema for Dataset JSON Version 1.0.0
#'
#' @format ## `schema_1_0_0`
#' \describe{
#'   A character vector with 1 element
#' }
"schema_1_0_0"
