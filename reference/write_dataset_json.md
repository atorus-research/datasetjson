# Write out a Dataset JSON file

Write out a Dataset JSON file

## Usage

``` r
write_dataset_json(
  x,
  file,
  pretty = FALSE,
  float_as_decimals = FALSE,
  digits = 16
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

  If TRUE, Convert float variables to "decimal" data type in the JSON
  output. This will manually convert the numeric values using the
  [`format()`](https://rdrr.io/r/base/format.html) function using the
  number of digits specified in `digits`, bypassing the `yyjsonr`
  handling of float values and writing the numbers out as JSON character
  strings. See the [Dataset JSON user
  guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding) for
  more information. Defaults to FALSE

- digits:

  When using `float_as_decimals`, the number of digits to use when
  writing out floats. Going higher than 16 may start writing otherwise
  sufficiently precise decimals (i.e. .2) to long strings.

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
if (FALSE) { # \dontrun{
  write_dataset_json(ds_json, "path/to/file.json")
} # }
```
