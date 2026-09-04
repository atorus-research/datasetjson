# Numeric Precision

Numeric precision and issues with floating point decimals are a common
problem when working with data. Dataset JSON is not immune to these
issues. Instead of writing out direct binary representations of floating
point numbers, which vary depending on the system being used and the
standard followed, Dataset JSON writes out character representations of
these numbers. Whenever a number is serialized to text and parsed back,
precision can be lost.

**{datasetjson}** parses and serializes numbers in C, using the
[yyjson](https://github.com/ibireme/yyjson) library that ships with the
package. Numbers are written using the shortest text that reads back as
the same value, and read straight into a double without passing through
R’s [`as.double()`](https://rdrr.io/r/base/double.html). The practical
effect is that a value survives a write and read unchanged:

``` r

library(datasetjson)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

test_df <- head(iris, 5)
test_df['float_col'] <- c(
  143.66666666666699825,
  2/3,
  1/3,
  165/37,
  6/7
)

test_items <- iris_items |> bind_rows(
  data.frame(
    itemOID = "IT.IR.float_col",
    name = "float_col",
    label = "Test column long decimal",
    dataType = "float"
  )
)

dsjson <- dataset_json(
  test_df, 
  item_oid = "test_df",
  name = "test_df",
  dataset_label = "test_df",
  columns = test_items
)

json_out <-write_dataset_json(dsjson)

out <- read_dataset_json(json_out)

test_df$float_col - out$float_col
#> [1] 0 0 0 0 0
#> attr(,"label")
#> [1] "Test column long decimal"
```

Every difference is exactly zero: the values that came back are
bit-for-bit the values that went in, and that holds across the full
range of double precision, from `1e-300` to `1e+300`.

This has not always been true. Before version 0.4.0 the numbers were
converted to text by the JSON library in use at the time, at a fixed six
decimal places. Values were rounded at around the seventh decimal, and
anything smaller than roughly `5e-7` was read back as exactly `0`. If
you have files written by an earlier version of the package, the data in
them is fine - the loss happened on read, so re-reading them with this
version recovers the original values.

## The decimal data type

The Dataset JSON standard also offers a “decimal” type. From the [user
guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding):

> ## Decimal Data Type
>
> Although the pilot findings on precision and rounding did not point to
> a problem with Dataset-JSON, the Dataset-JSON Team opted to add the
> Decimal datatype. The Decimal datatype has been available in ODM for
> many years. The basic premise for this datatype is to represent the
> number in Dataset-JSON as a string (a quoted set of numeric
> characters) to prevent JSON libraries from interpreting the number as
> a float before the software application gets access to it.
>
> To use decimal in Dataset-JSON, set the dataType to decimal and the
> targetDataType to decimal. This instructs conversion software to
> convert the number it reads from a native dataset into a string in
> Dataset-JSON. It also instructs the receiver to convert the number as
> a string into the decimal datatype or closest approximation available
> in the receiving technology. Note that not all technologies support an
> explicit decimal datatype.

[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
supports this through `float_as_decimals`. When set, float columns are
written as `decimal`/`decimal` and the values are quoted, and
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
converts them back to numeric on read per the specification.

Because this is no longer needed to protect precision, setting it warns:

``` r

json_out <- write_dataset_json(dsjson, float_as_decimals = TRUE)
#> Warning: As of datasetjson 0.4.0 numbers are written and read at full
#> precision, so `float_as_decimals = TRUE` is no longer needed to protect against
#> rounding and `FALSE` is preferred. Set it only when the receiving system
#> requires the `decimal` data type.

out <- read_dataset_json(json_out)

test_df$float_col - out$float_col
#> [1] 0 0 0 0 0
#> attr(,"label")
#> [1] "Test column long decimal"
```

The result is the same, because both paths are exact.
**`float_as_decimals` is an interoperability choice, not a precision
workaround.** Reach for it when the system receiving your file needs
numbers presented as strings; leave it off otherwise. It remains off by
default for two reasons:

- Writing the `decimal` type is an extra step the consuming system has
  to be aware of, and Dataset JSON is still a young standard
- Quoted numbers make for larger files with no gain in fidelity

## A note on `digits`

`digits` is deprecated and ignored. Decimals are written at whatever
precision reads back as the same value, so there is nothing left for it
to control, and supplying it warns.

``` r

cat(write_dataset_json(dsjson, float_as_decimals = TRUE, pretty = TRUE))
#> {
#>     "datasetJSONCreationDateTime": "2026-09-04T00:56:08",
#>     "datasetJSONVersion": "1.1.0",
#>     "itemGroupOID": "test_df",
#>     "records": 5,
#>     "name": "test_df",
#>     "label": "test_df",
#>     "columns": [
#>         {
#>             "itemOID": "IT.IR.Sepal.Length",
#>             "name": "Sepal.Length",
#>             "label": "Sepal Length",
#>             "dataType": "decimal",
#>             "keySequence": 2,
#>             "targetDataType": "decimal"
#>         },
#>         {
#>             "itemOID": "IT.IR.Sepal.Width",
#>             "name": "Sepal.Width",
#>             "label": "Sepal Width",
#>             "dataType": "decimal",
#>             "targetDataType": "decimal"
#>         },
#>         {
#>             "itemOID": "IT.IR.Petal.Length",
#>             "name": "Petal.Length",
#>             "label": "Petal Length",
#>             "dataType": "decimal",
#>             "keySequence": 3,
#>             "targetDataType": "decimal"
#>         },
#>         {
#>             "itemOID": "IT.IR.Petal.Width",
#>             "name": "Petal.Width",
#>             "label": "Petal Width",
#>             "dataType": "decimal",
#>             "targetDataType": "decimal"
#>         },
#>         {
#>             "itemOID": "IT.IR.Species",
#>             "name": "Species",
#>             "label": "Flower Species",
#>             "dataType": "string",
#>             "length": 10,
#>             "keySequence": 1
#>         },
#>         {
#>             "itemOID": "IT.IR.float_col",
#>             "name": "float_col",
#>             "label": "Test column long decimal",
#>             "dataType": "decimal",
#>             "targetDataType": "decimal"
#>         }
#>     ],
#>     "rows": [
#>         [
#>             "5.1",
#>             "3.5",
#>             "1.4",
#>             "0.2",
#>             "setosa",
#>             "143.666666666667"
#>         ],
#>         [
#>             "4.9",
#>             "3",
#>             "1.4",
#>             "0.2",
#>             "setosa",
#>             "0.6666666666666666"
#>         ],
#>         [
#>             "4.7",
#>             "3.2",
#>             "1.3",
#>             "0.2",
#>             "setosa",
#>             "0.3333333333333333"
#>         ],
#>         [
#>             "4.6",
#>             "3.1",
#>             "1.5",
#>             "0.2",
#>             "setosa",
#>             "4.45945945945946"
#>         ],
#>         [
#>             "5",
#>             "3.6",
#>             "1.4",
#>             "0.2",
#>             "setosa",
#>             "0.8571428571428571"
#>         ]
#>     ]
#> }
```

If you need values at a fixed precision - to match another system’s
output, say - format the column to character yourself and declare it as
`decimal`/`decimal` in the column metadata. The writer passes such
columns through verbatim:

``` r

fixed <- test_df
fixed$float_col <- format(fixed$float_col, digits = 8, trim = TRUE)

fixed_items <- test_items
fixed_items$dataType[fixed_items$name == "float_col"] <- "decimal"
fixed_items$targetDataType <- ifelse(fixed_items$name == "float_col",
                                     "decimal", NA_character_)

fixed_json <- write_dataset_json(
  dataset_json(fixed, item_oid = "test_df", name = "test_df",
               dataset_label = "test_df", columns = fixed_items)
)

read_dataset_json(fixed_json)$float_col
#> [1] 143.6666667   0.6666667   0.3333333   4.4594595   0.8571429
#> attr(,"label")
#> [1] "Test column long decimal"
```
