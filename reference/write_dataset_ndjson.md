# Write out a Dataset NDJSON file

Writes the newline-delimited JSON representation of Dataset JSON: the
dataset metadata as a single JSON object on line 1, then one JSON array
per data row. The content is identical to what
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
produces; only the framing differs, which is what makes NDJSON
straightforward to stream a row at a time.

## Usage

``` r
write_dataset_ndjson(x, file, float_as_decimals = FALSE, digits = NULL)
```

## Arguments

- x:

  datasetjson object

- file:

  File path to save the Dataset NDJSON file. If not provided, the NDJSON
  is returned as a character string.

- float_as_decimals:

  If TRUE, write float variables as "decimal" data types, serialized as
  JSON strings rather than numbers. This is an interoperability choice;
  it is not needed for precision, as numbers are written at full
  precision either way, and setting it raises a warning to that effect.

- digits:

  Deprecated and ignored. Decimals are written at whatever precision
  reads back as the same value, so there is no precision for this
  argument to control. It is ignored, and supplying it warns.

## Value

NULL when writing to a file, otherwise a character string

## Examples

``` r
ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
nd <- write_dataset_ndjson(ds_json)

# Write to disk
write_dataset_ndjson(ds_json, tempfile(fileext = ".ndjson"))
#> NULL

# float_as_decimals writes floats as the "decimal" type, quoting the numbers.
# It is an interoperability choice for systems that require that type - it is
# not needed for precision, and setting it warns to say so.
nd <- suppressWarnings(write_dataset_ndjson(ds_json, float_as_decimals = TRUE))
```
