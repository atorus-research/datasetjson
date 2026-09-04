# Validate a Dataset NDJSON file

Checks a Dataset NDJSON file in two parts, matching how the format is
structured: the metadata object on line 1 is validated against the
Dataset NDJSON v1.1.0 schema, and each subsequent line is checked to be
a JSON array carrying one value per declared column.

## Usage

``` r
validate_dataset_ndjson(x)
```

## Arguments

- x:

  File path or URL of a Dataset NDJSON file, or a character vector
  holding the NDJSON text

## Value

A data frame of errors, empty when the file is valid

## Examples

``` r
# Validate a file on disk
validate_dataset_ndjson(datasetjson_example("dm.ndjson"))
#> File is valid per the Dataset NDJSON v1.1.0 schema
#> [1] line    message
#> <0 rows> (or 0-length row.names)

ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)

validate_dataset_ndjson(write_dataset_ndjson(ds_json))
#> File is valid per the Dataset NDJSON v1.1.0 schema
#> [1] line    message
#> <0 rows> (or 0-length row.names)
```
