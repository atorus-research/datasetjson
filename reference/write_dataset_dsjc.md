# Write out a Dataset JSON Compressed (DSJC) file

Writes the compressed representation of Dataset JSON: the Dataset NDJSON
content of the dataset, compressed as a zLib stream. The format carries
no wrapper of its own - the file is the zLib stream and nothing else -
and uses the `.dsjc` extension.

## Usage

``` r
write_dataset_dsjc(
  x,
  file,
  float_as_decimals = FALSE,
  level = 9L,
  digits = NULL
)
```

## Arguments

- x:

  datasetjson object

- file:

  File path to save the DSJC file. If not provided, the compressed bytes
  are returned as a raw vector.

- float_as_decimals:

  If TRUE, write float variables as "decimal" data types. This is an
  interoperability choice; it is not needed for precision, as numbers
  are written at full precision either way, and setting it raises a
  warning to that effect.

- level:

  zLib compression level, 0 (none) to 9 (maximum). Defaults to 9, which
  the specification recommends for data exchange. Lower levels compress
  faster and less.

- digits:

  Deprecated and ignored. See
  [`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md).

## Value

NULL when writing to a file, otherwise a raw vector

## Details

Rows are compressed as they are serialized, so writing a large dataset
never holds its uncompressed NDJSON in memory.

The default `level = 9` follows the specification's recommendation for
data exchange. Note that the top of the range buys little: on a 26 MB
dataset, level 1 wrote in a fifth of the time for a file only 4% larger.
If write time matters more than the last few percent, a lower level is a
reasonable choice. Read time is unaffected by the level used to write.

## Examples

``` r
ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
bytes <- write_dataset_dsjc(ds_json)

# Write to disk
write_dataset_dsjc(ds_json, tempfile(fileext = ".dsjc"))
#> NULL
```
