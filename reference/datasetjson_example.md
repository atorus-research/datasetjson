# Get path to a datasetjson example file

datasetjson comes bundled with sample files in its `inst/extdata`
directory. This function makes them easy to access.

## Usage

``` r
datasetjson_example(file = NULL)
```

## Arguments

- file:

  Name of file. If `NULL`, the example files will be listed.

## Value

A file path string, or a character vector of available files if `file`
is `NULL`.

## Examples

``` r
datasetjson_example()
#> [1] "dm.dsjc"   "dm.json"   "dm.ndjson"
datasetjson_example("dm.json")
#> [1] "/home/runner/work/_temp/Library/datasetjson/extdata/dm.json"
```
