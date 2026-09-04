# Validate a Dataset JSON Compressed (DSJC) file

Decompresses the zLib stream and validates the Dataset NDJSON content it
holds, as
[`validate_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_ndjson.md)
does: the metadata object on line 1 is checked against the Dataset
NDJSON v1.1.0 schema, and each subsequent line must be a JSON array
carrying one value per declared column.

## Usage

``` r
validate_dataset_dsjc(x)
```

## Arguments

- x:

  File path or URL of a DSJC file, or a raw vector holding the
  compressed bytes

## Value

A data frame of errors, empty when the file is valid

## Examples

``` r
validate_dataset_dsjc(datasetjson_example("dm.dsjc"))
#> File is valid per the Dataset NDJSON v1.1.0 schema
#> [1] line    message
#> <0 rows> (or 0-length row.names)
```
