% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_dataset_json.R
\name{read_dataset_json}
\alias{read_dataset_json}
\title{Read a Dataset JSON to datasetjson object}
\usage{
read_dataset_json(file, decimals_as_floats = FALSE)
}
\arguments{
\item{file}{File path or URL of a Dataset JSON file}

\item{decimals_as_floats}{Convert variables of "decimal" type to float}
}
\value{
A dataframe with additional attributes attached containing the
DatasetJSON metadata.
}
\description{
This function validates a dataset JSON file against the Dataset JSON schema,
and if valid returns a datasetjson object. The Dataset JSON file can be either
a file path on disk of a URL which contains the Dataset JSON file.
}
\details{
The resulting dataframe contains the additional metadata available on the
Dataset JSON file within the attributes to make this accessible to the user.
Note that these attributes are only populated if available.
\itemize{
\item \strong{sourceSystem}: The information system from which the content of this
dataset was source, including system name and version.
\item \strong{datasetJSONVersion}: The version of the Dataset-JSON standard used to
create the dataset.
\item \strong{fileOID}: A unique identifier for this dataset.
\item \strong{dbLastModifiedDateTime}: The date/time the source database was last
modified before creating the Dataset-JSON file.
\item \strong{originator}: The organization that generated the Dataset-JSON dataset.
\item \strong{studyOID}: Unique identifier for the study that may also function as a
foreign key to a Study/@OID in an associated Define-XML document, or to any
studyOID references that are used as keys in other documents;
\item \strong{metaDataVersionOID}: Unique identifier for the metadata version that may
also function as a foreign key to a MetaDataVersion/@OID in an associated
Define-XML file
\item \strong{metaDataRef}: URI for the metadata file describing the dataset (e.g.,
a Define-XML file).
\item \strong{itemGroupOID}: Unique identifier for the dataset that may also function
as a foreign key to an ItemGroupDef/@OID in an associated Define-XML file.
\item \strong{name}: The human-readable name for the dataset.
\item \strong{label}: A short description of the dataset.
\item \strong{columns}: An array of metadata objects that describe the dataset
variables. See \code{dataset_json()} for further information on the contents of
these fields.
}
}
\examples{
# Read from disk
\dontrun{
  dat <- read_dataset_json("path/to/file.json")
 # Read file from URL
  dat <- dataset_json('https://www.somesite.com/file.json')
}

# Read from an already imported character vector
ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", columns=iris_items)
js <- write_dataset_json(ds_json)
dat <- read_dataset_json(js)
}
