# Assign Dataset JSON attributes to data frame columns

Using the `columns` element of the Dataset JSON file, assign the
available metadata to individual columns

## Usage

``` r
set_variable_attributes(x)
```

## Arguments

- x:

  A datasetjson object

## Value

A datasetjson object with attributes assigned to individual variables

## Examples

``` r

ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)

ds_json <- set_variable_attributes(ds_json)
```
