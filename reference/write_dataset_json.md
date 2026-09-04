# Write out a Dataset JSON file

Write out a Dataset JSON file

## Usage

``` r
write_dataset_json(
  x,
  file,
  pretty = FALSE,
  float_as_decimals = FALSE,
  digits = NULL
)
```

## Arguments

- x:

  datasetjson object

- file:

  File path to save Dataset JSON file

- pretty:

  If TRUE, write with readable formatting. *Note: The Dataset JSON
  standard prefers compressed formatting without line feeds. It is not
  recommended you use pretty printing for submission purposes.*

- float_as_decimals:

  If TRUE, write float variables as the "decimal" data type, quoting the
  numbers as JSON strings rather than writing them as JSON numbers. This
  is an interoperability choice for systems that expect the decimal
  type; it is not needed for precision, as numbers are written at full
  precision either way, and setting it raises a warning to that effect.
  See the [Dataset JSON user
  guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding) for
  more information. Defaults to FALSE

- digits:

  Deprecated and ignored. Decimals are written at whatever precision
  reads back as the same value, so there is no precision for this
  argument to control. It is ignored, and supplying it warns. If you
  need values rendered at a fixed precision, format the column to
  character yourself and declare it as `decimal`/`decimal` in the column
  metadata; the writer passes such columns through verbatim.

## Value

NULL when file written to disk, otherwise character string

## Examples

``` r
# Write to character object
ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
js <- write_dataset_json(ds_json)

# Write to disk
write_dataset_json(ds_json, tempfile(fileext = ".json"))
#> NULL

# float_as_decimals writes floats as the "decimal" type, quoting the numbers.
# It is an interoperability choice for systems that require that type - it is
# not needed for precision, and setting it warns to say so.
js <- suppressWarnings(write_dataset_json(ds_json, float_as_decimals = TRUE))

# `digits` is deprecated and ignored; decimals are written at whatever
# precision reads back as the same value
js <- suppressWarnings(write_dataset_json(ds_json, digits = 16))
```
