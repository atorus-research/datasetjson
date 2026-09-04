# Read a Dataset JSON Compressed (DSJC) file to a datasetjson object

Reads the compressed representation of Dataset JSON: a zLib stream
holding Dataset NDJSON content. The object returned is the same one
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
and
[`read_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_ndjson.md)
return for the equivalent uncompressed file, metadata attributes
included.

## Usage

``` r
read_dataset_dsjc(file)
```

## Arguments

- file:

  File path or URL of a DSJC file, or a raw vector holding the
  compressed bytes

## Value

A dataframe with additional attributes attached containing the
DatasetJSON metadata.

## Examples

``` r
# Read one of the example files shipped with the package
dm <- read_dataset_dsjc(datasetjson_example("dm.dsjc"))

# Or from bytes held in memory
ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
dat <- read_dataset_dsjc(write_dataset_dsjc(ds_json))
```
