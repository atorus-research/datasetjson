# Extract column metadata to data frame

This function pulls out the column metadata from the `datasetjson`
object attributes into a more user-friendly data.frame.

## Usage

``` r
get_column_metadata(x)
```

## Arguments

- x:

  A datasetjson object

## Value

A data frame containing the columns metadata

## Examples

``` r

ds_json <- dataset_json(
  iris,
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)

get_column_metadata(ds_json)
#>              itemOID         name          label dataType keySequence
#> 1 IT.IR.Sepal.Length Sepal.Length   Sepal Length    float           2
#> 2  IT.IR.Sepal.Width  Sepal.Width    Sepal Width    float          NA
#> 3 IT.IR.Petal.Length Petal.Length   Petal Length    float           3
#> 4  IT.IR.Petal.Width  Petal.Width    Petal Width    float          NA
#> 5      IT.IR.Species      Species Flower Species   string           1
#>   targetDataType length displayFormat
#> 1           <NA>     NA          <NA>
#> 2           <NA>     NA          <NA>
#> 3           <NA>     NA          <NA>
#> 4           <NA>     NA          <NA>
#> 5           <NA>     10          <NA>
```
