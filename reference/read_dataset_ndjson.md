# Read a Dataset NDJSON file to a datasetjson object

Reads a newline-delimited JSON (NDJSON) file following the Dataset JSON
v1.1.0 specification. Line 1 of the file holds the dataset metadata and
each subsequent line holds one data row as a JSON array.

## Usage

``` r
read_dataset_ndjson(file)
```

## Arguments

- file:

  File path or URL of a Dataset NDJSON file, or a character string
  containing the NDJSON content itself

## Value

A dataframe with additional attributes attached containing the
DatasetJSON metadata.

## Details

NDJSON and JSON representations of Dataset JSON carry the same content,
so the object returned here is the same as the one
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
returns for the equivalent `.json` file, including all of the metadata
attached as attributes. See
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
for the full list.

## Examples

``` r
# Read one of the example files shipped with the package
dm <- read_dataset_ndjson(datasetjson_example("dm.ndjson"))

# Or from NDJSON text held in memory
ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
dat <- read_dataset_ndjson(write_dataset_ndjson(ds_json))
```
