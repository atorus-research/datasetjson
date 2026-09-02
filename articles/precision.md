# Numeric Precision

Numeric precision and issues with floating point decimals is a common
problem to come across when working with data. Dataset JSON is not
immune to these issues. Instead of writing out direct binary
representations of the floating point numbers, which will vary depending
on the system being used and the standard followed, Dataset JSON writes
out character representations of these numbers. As such, when the
numbers are serialized from numeric to character, and then read back
into numeric format, you may come across precision issues.

Consider the following example:

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
#> [1] -3.333330e-07 -3.333333e-07  3.333333e-07  4.594595e-07 -1.428571e-07
#> attr(,"label")
#> [1] "Test column long decimal"
```

In this case, we start seeing differences at the 7th decimal point. To
look at a specific value, the input of `143.66666666666699825` is
written out in the JSON file as `143.666666666667`. This issue isn’t
unique to R either. If you’re ever converted numeric to character and
back to numeric in SAS, you’ll likely have encountered a similar
problem.

In the **{datasetjson}** package, the **{yyjsonr}** package is doing the
heavy lifting of serializing the R numeric value into a character
string. The underlying C library has some [recent
updates](https://github.com/ibireme/yyjson/commit/6d416047822d86d53a3a0b45a6a5abf28383a1dc)
to work on improving read output number precision which we hope will
improve the handling.

Another way to handle numeric precision issues is to use the “decimal”
types that’s available in the Dataset JSON standard. From the [user
guide](https://wiki.cdisc.org/display/PUB/Precision+and+Rounding), this
can be described as follows:

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

In order to address this problem, we’ve added the options
`float_as_decimals` and `digits` to
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md).
When `float_as_decimals = TRUE`, the columns are written as
`decimal`/`decimal` in the JSON, and
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
will automatically convert them back to numeric on read per the Dataset
JSON v1.1 specification.

Considering the example before, here’s how these options can help.

``` r

json_out <- write_dataset_json(dsjson, float_as_decimals = TRUE)

out <- read_dataset_json(json_out)

test_df$float_col - out$float_col
#> [1] 0 0 0 0 0
#> attr(,"label")
#> [1] "Test column long decimal"
```

By manually handling how the decimal precision is rendered, the values
were able to serialize and re-import more effectively.

There are a few reasons we’ve chosen to NOT make `float_as_decimals`
default behavior:

- This inherently adds overhead, because we convert the values prior to
  letting `yyjsonr` serialize them
- We’re changing the way the metadata is writing to use the `decimal`
  type. While the standard supports the use of the `decimal` type, it’s
  an extra step that that the consuming system needs to be aware of, and
  Dataset JSON is still a young standard.
- Our hope is that the `yyjson` C package grows to make this extra step
  less necessary

As one last note, we default our choice of decimal precision to use 16
digits. The reason we’ve chosen to do this is as follows:

``` r

print(format(.2, digits=16))
#> [1] "0.2"
print(format(.2, digits=17))
#> [1] "0.20000000000000001"
```

After a certain point, displaying extra digits is just going to show the
where floating point values start to break down. 16 digits balances
preserving the precision of output without turning low precision numbers
into overly precise ones.
