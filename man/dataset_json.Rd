% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasetjson.R
\name{dataset_json}
\alias{dataset_json}
\title{Create a Dataset JSON Object}
\usage{
dataset_json(
  .data,
  file_oid = NULL,
  last_modified = NULL,
  originator = NULL,
  sys = NULL,
  sys_version = NULL,
  study = NULL,
  metadata_version = NULL,
  metadata_ref = NULL,
  item_oid = NULL,
  name = NULL,
  dataset_label = NULL,
  columns = NULL,
  version = "1.1.0"
)
}
\arguments{
\item{.data}{Input data to contain within the Dataset JSON file. Written to
the itemData parameter.}

\item{file_oid}{fileOID parameter, defined as "A unique identifier for this
file." (optional)}

\item{last_modified}{The date/time the source database was last modified
before creating the Dataset-JSON file (optional)}

\item{originator}{originator parameter, defined as "The organization that
generated the Dataset-JSON file." (optional)}

\item{sys}{sourceSystem.name parameter, defined as "The computer system or
database management system that is the source of the information in this
file." (Optional, required if coupled with sys_version)}

\item{sys_version}{sourceSystem.Version, defined as "The version of the
sourceSystem" (Optional, required if coupled with sys)}

\item{study}{Study OID value (optional)}

\item{metadata_version}{Metadata version OID value (optional)}

\item{metadata_ref}{Metadata reference (i.e. path to Define.xml) (optional)}

\item{item_oid}{ID used to label dataset with the itemGroupData parameter.
Defined as "Object of Datasets. Key value is a unique identifier for
Dataset, corresponding to ItemGroupDef/@OID in Define-XML."}

\item{name}{Dataset name}

\item{dataset_label}{Dataset Label}

\item{columns}{Variable level metadata for the Dataset JSON object. See
details for format requirements.}

\item{version}{The DatasetJSON version to use. Currently only 1.1.0 is
supported.}
}
\value{
dataset_json object pertaining to the specific Dataset JSON version
specific
}
\description{
Create the base object used to write a Dataset JSON file.
}
\details{
The \code{columns} parameter should be provided as a dataframe based off the
Dataset JSON Specification:
\itemize{
\item \strong{itemOID}: \emph{string, required}: Unique identifier for the variable that may also
function as a foreign key to an ItemDef/@OID in an associated Define-XML
file. See the \href{https://wiki.cdisc.org/display/PUB/Element+Identifiers+and+References}{ODM specification}
for OID considerations.
\item \strong{name}: \emph{string, required}: Variable name
\item \strong{label}: \emph{string, required}: Variable label
\item \strong{dataType}: \emph{string, required}: Logical data type of the variable. The dataType
attribute represents the planned specificity of the data. See the \href{https://wiki.cdisc.org/display/PUB/Data+Formats}{ODM Data Formats specification} for
details.
-\strong{targetDataType}: \emph{string, optional}: Indicates the data type into which
the receiving system must transform the associated Dataset-JSON variable. The
variable with the data type attribute of dataType must be converted into the
targetDataType when transforming the Dataset-JSON dataset into a format for
operational use (e.g., SAS dataset, R dataframe, loading into a system's data
store). Only specify targetDataType when it is different from the dataType
attribute or the JSON data type and the data needs to be transformed by the
receiving system. See the Supported Column Data Type Combinations table for
details on usage. See the User's Guide for additional information.
\item \strong{length}: \emph{integer, optional}: Specifies the number of characters
allowed for the variable value when it is represented as a text.
\item \strong{displayFormat}: *string, optional: A SAS display format value used for
data visualization of numeric float and date values.
\item \strong{keySequence}: \emph{integer, optional}: Indicates that this item is a key
variable in the dataset structure. It also provides an ordering for the keys.
}

Note that DatasetJSON is on version 1.1.0. Based off findings from the pilot,
version 1.1.0 reflects feedback from the user community. Support for 1.0.0
has been deprecated.
}
\examples{
# Create a basic object
ds_json <- dataset_json(
  iris,
  file_oid = "/some/path",
  last_modified = "2023-02-15T10:23:15",
  originator = "Some Org",
  sys = "source system",
  sys_version = "1.0",
  study = "SOMESTUDY",
  metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
  metadata_ref = "some/define.xml",
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)

# Attach attributes directly
ds_json <- dataset_json(iris, columns = iris_items)
ds_json <- set_file_oid(ds_json, "/some/path")
ds_json <- set_last_modified(ds_json, "2025-01-21T13:34:50")
ds_json <- set_originator(ds_json, "Some Org")
ds_json <- set_source_system(ds_json, "source system", "1.0")
ds_json <- set_study_oid(ds_json, "SOMESTUDY")
ds_json <- set_metadata_ref(ds_json, "some/define.xml")
ds_json <- set_metadata_version(ds_json, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
ds_json <- set_item_oid(ds_json, "IG.IRIS")
ds_json <- set_dataset_name(ds_json, "Iris")
ds_json <- set_dataset_label(ds_json, "The Iris Dataset")
}
