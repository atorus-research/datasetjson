% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/file_metadata.R
\name{set_source_system}
\alias{set_source_system}
\alias{set_originator}
\alias{set_file_oid}
\alias{set_study_oid}
\alias{set_metadata_version}
\alias{set_metadata_ref}
\alias{set_item_oid}
\alias{set_dataset_name}
\alias{set_dataset_label}
\alias{set_last_modified}
\title{Dataset Metadata Setters}
\usage{
set_source_system(x, sys, sys_version)

set_originator(x, originator)

set_file_oid(x, file_oid)

set_study_oid(x, study)

set_metadata_version(x, metadata_version)

set_metadata_ref(x, metadata_ref)

set_item_oid(x, item_oid)

set_dataset_name(x, name)

set_dataset_label(x, dataset_label)

set_last_modified(x, last_modified)
}
\arguments{
\item{x}{datasetjson object}

\item{sys}{sourceSystem.name parameter, defined as "The computer system or
database management system that is the source of the information in this
file." (Optional, required if coupled with sys_version)}

\item{sys_version}{sourceSystem.Version, defined as "The version of the
sourceSystem" (Optional, required if coupled with sys)}

\item{originator}{originator parameter, defined as "The organization that
generated the Dataset-JSON file." (optional)}

\item{file_oid}{fileOID parameter, defined as "A unique identifier for this
file." (optional)}

\item{study}{Study OID value (optional)}

\item{metadata_version}{Metadata version OID value (optional)}

\item{metadata_ref}{Metadata reference (i.e. path to Define.xml) (optional)}

\item{item_oid}{ID used to label dataset with the itemGroupData parameter.
Defined as "Object of Datasets. Key value is a unique identifier for
Dataset, corresponding to ItemGroupDef/@OID in Define-XML."}

\item{name}{Dataset name}

\item{dataset_label}{Dataset Label}

\item{last_modified}{The date/time the source database was last modified
before creating the Dataset-JSON file (optional)}
}
\value{
datasetjson object
}
\description{
Set information about the file, source system, study, and dataset used to
generate the Dataset JSON object.
}
\details{
The fileOID parameter should be structured following description outlined in
the ODM V2.0 specification. "FileOIDs should be universally unique if at all
possible. One way to ensure this is to prefix every FileOID with an internet
domain name owned by the creator of the ODM file or database (followed by a
forward slash, "/"). For example,
FileOID="BestPharmaceuticals.com/Study5894/1" might be a good way to denote
the first file in a series for study 5894 from Best Pharmaceuticals."
}
\examples{
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
\concept{Dataset Metadata Setters}
