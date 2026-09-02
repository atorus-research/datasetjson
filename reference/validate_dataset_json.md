# Validate a Dataset JSON file

This function calls
[`jsonvalidate::json_validate()`](https://docs.ropensci.org/jsonvalidate/reference/json_validate.html)
directly, with the parameters necessary to retrieve the error
information of an invalid JSON file per the Dataset JSON schema.

## Usage

``` r
validate_dataset_json(x)
```

## Arguments

- x:

  File path or URL of a Dataset JSON file, or a character vector holding
  JSON text

## Value

A data frame

## Examples

``` r

if (FALSE) { # \dontrun{
  validate_dataset_json('path/to/file.json')
  validate_dataset_json('https://www.somesite.com/file.json')


ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
js <- write_dataset_json(ds_json)

validate_dataset_json(js)
} # }
```
