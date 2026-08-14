# Dates, Times, and Datetimes

Dataset JSON Version 1.1 provides a significant improvement of the
handling of dates and times. In version 1.0, there wasn’t a clear
instruction around anchoring the origin of numeric dates and date times,
and given that SAS uses 1960-01-01 and R uses the POSIX date of
1970-01-01, this created a slightly complex discrepancy. Version 1.1
instead opts to use ISO8601 formatted dates, times, and date times, and
the target data type is clearly stated within the column metadata. This
makes the true date value unambiguous.

Starting in **{datasetjson}** v0.3.0 we’ve introduce support for Dataset
JSON v1.1.0. As such, we automatically handle date, time, and date time
conversions. There are a few considerations you need to make when
dealing with these types to make things work properly.

## Metadata Settings

Version 5 SAS Transport Files didn’t have a notion of a “date”, “time”
or “datetime” type. Instead, using the SAS convention these were just
Integer values with a display format attached. Dataset JSON Version 1.1
explicitly clarifies numeric date types using the `dataType` and
`targetDataType` fields in the columns metadata. Consider these
variables.

| itemOID | name | label | dataType | length | targetDataType | displayFormat | keySequence |
|:---|:---|:---|:---|---:|:---|:---|---:|
| IT.DF.CHARDT | CHARDT | Character Date | date | 8 | NA | NA | NA |
| IT.DF.CHARTM | CHARTM | Character Time | time | 10 | NA | NA | NA |
| IT.DF.CHARDTM | CHARDTM | Character Datetime | datetime | 19 | NA | NA | NA |
| IT.DF.NUMDT | NUMDT | Numeric date | time | NA | integer | TIME8 | NA |
| IT.DF.NUMTM | NUMTM | Numeric time | time | NA | integer | TIME8 | NA |
| IT.DF.NUMDTM | NUMDTM | Numeric datetime | datetime | NA | integer | E8601DT | NA |

In the table above, we have the metadata for both character and numeric
dates, times, and date times. Both sets of variables have the same
values within `dataType`. The difference is the optional field of
`targetDataType`, where the value for the numeric variables is set to
`integer`. Both
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
and
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
rely on these fields and as such they must be set properly. This comes
with a few assumption and requirements.

- Numeric dates will be converted into the type of `Date` (see
  [`help("Date", package="base")`](https://rdrr.io/r/base/Dates.html))
- Numeric times will be converted to the **{hms}** type of `hms`
- R doesn’t have a specific built in type of time. We decided to take on
  **{hms}** as a dependency given that this is the type using by the
  **{haven}** package when reading SAS Version 5 Transport files. As
  such, similar behavior can be expected when importing an XPT or a
  Dataset JSON file.
- Numeric date times will be converted to the base R type of `POSIXct`
  and anchored to the UTC timezone.
- CDISC dates are generally not timezone qualified, though for character
  dates, this is optional. Unless a timezone is explicitly specified
  systems may default to the user’s current timezone. To decrease
  ambiguity, we’ve introduced a hard requirement that datetimes are
  anchored to UTC. If the datetime variable is found to be using a
  different timezone, an error will be thrown.

If any of these assumption don’t work for your purpose or if you find
other situations we need to handle, please leave an issue on Github as
we want to make sure we support the community as best we can.
