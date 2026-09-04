# Getting Started

``` r

library(datasetjson)
```

## Using **datasetjson**

**datasetjson** works by allowing you to take a data frame and apply the
necessary attributes required for the CDISC Dataset JSON. The goal is to
make this experience simple. Before you can write a Dataset JSON file to
disk, you first need to build the Dataset JSON object. An example call
looks like this:

``` r

ds_json <- dataset_json(head(iris, 5), 
                        item_oid = "IG.IRIS", 
                        name = "IRIS", 
                        dataset_label = "Iris", 
                        columns = iris_items)
```

This is the minimum information required to provide to create a
`datasetjson` object.

The parameters here can be described as follows:

- The input data frame `iris`
- The `item_oid`, which can be described as the “Object of Dataset”,
  which is a key value is a unique identifier for the dataset,
  corresponding to <ItemGroupDef/@OID> in Define-XML.
- `name`, which is the dataset name
- `dataset_label`, which is the dataset label, and finally
- `columns`, which is the variable level metadata for your dataset.

The `columns` parameter is special here, in that you provide a data
frame with the necessary variable metadata. Take a look at the
`iris_items` data frame.

``` r

iris_items
#>              itemOID         name          label dataType length keySequence
#> 1 IT.IR.Sepal.Length Sepal.Length   Sepal Length    float     NA           2
#> 2  IT.IR.Sepal.Width  Sepal.Width    Sepal Width    float     NA          NA
#> 3 IT.IR.Petal.Length Petal.Length   Petal Length    float     NA           3
#> 4  IT.IR.Petal.Width  Petal.Width    Petal Width    float     NA          NA
#> 5      IT.IR.Species      Species Flower Species   string     10           1
```

This data frame has 7 columns, 4 of which are strictly required. This is
defined by the [CDISC Dataset JSON
Specification](https://www.cdisc.org/standards/data-exchange/dataset-json).

| **Attribute** | **Requirement** | **Description** |
|----|----|----|
| itemOID | Required | OID of a variable (must correspond to the variable OID in the Define-XML file) |
| name | Required | Variable name |
| label | Required | Variable description |
| dataType | Required | Type of the variable. Allowed values: “string”, “integer”, “decimal”, “float”, “double”, “boolean”, “datetime”, “date”, “time”, “URI”. See ODM types for details. |
| targetDataType | Optional | Allowed values: “integer”, “decimal”. Indicates the data type into which the receiving system must transform the variable. Only specify it when it differs from `dataType` and the data needs transforming - for example `integer` for the numeric dates and times used in ADaM, or `decimal` where a number is carried as a string. |
| length | Optional | Variable length |
| displayFormat | Optional | Display format supports data visualization of numeric float and date values. |
| keySequence | Optional | Indicates that this item is a key variable in the dataset structure. It also provides an ordering for the keys. |

The data within this dataframe ultimately populates the `columns`
element of the Dataset JSON file. The itemOID, name, label, and dataType
columns are all required and must be populated for each variable. Note
that the dataType column has a list of allowable values:

- `string`
- `integer`
- `float`
- `double`
- `decimal`
- `boolean`
- `datetime`
- `date`
- `time`
- `URI`

This information must be provided directly by the user. Note that no
type conversions of your data are performed by the `datasetjson`
package. The displayFormat column inherently refers to display formats
used within SAS.

### Writing and Reading

The `datasetjson` object allows you to collect the information needed to
generate a Dataset JSON file, but to write the dataset out need to use
the
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
file. Once the Dataset JSON object is available, all you need is that
object name and a file path.

``` r

write_dataset_json(ds_json, file="iris.json")
```

The
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
also has the option to return the JSON output as a character string.

``` r

js <- write_dataset_json(ds_json, pretty=TRUE)
cat(js)
#> {
#>     "datasetJSONCreationDateTime": "2026-09-04T00:56:05",
#>     "datasetJSONVersion": "1.1.0",
#>     "itemGroupOID": "IG.IRIS",
#>     "records": 5,
#>     "name": "IRIS",
#>     "label": "Iris",
#>     "columns": [
#>         {
#>             "itemOID": "IT.IR.Sepal.Length",
#>             "name": "Sepal.Length",
#>             "label": "Sepal Length",
#>             "dataType": "float",
#>             "keySequence": 2
#>         },
#>         {
#>             "itemOID": "IT.IR.Sepal.Width",
#>             "name": "Sepal.Width",
#>             "label": "Sepal Width",
#>             "dataType": "float"
#>         },
#>         {
#>             "itemOID": "IT.IR.Petal.Length",
#>             "name": "Petal.Length",
#>             "label": "Petal Length",
#>             "dataType": "float",
#>             "keySequence": 3
#>         },
#>         {
#>             "itemOID": "IT.IR.Petal.Width",
#>             "name": "Petal.Width",
#>             "label": "Petal Width",
#>             "dataType": "float"
#>         },
#>         {
#>             "itemOID": "IT.IR.Species",
#>             "name": "Species",
#>             "label": "Flower Species",
#>             "dataType": "string",
#>             "length": 10,
#>             "keySequence": 1
#>         }
#>     ],
#>     "rows": [
#>         [
#>             5.1,
#>             3.5,
#>             1.4,
#>             0.2,
#>             "setosa"
#>         ],
#>         [
#>             4.9,
#>             3.0,
#>             1.4,
#>             0.2,
#>             "setosa"
#>         ],
#>         [
#>             4.7,
#>             3.2,
#>             1.3,
#>             0.2,
#>             "setosa"
#>         ],
#>         [
#>             4.6,
#>             3.1,
#>             1.5,
#>             0.2,
#>             "setosa"
#>         ],
#>         [
#>             5.0,
#>             3.6,
#>             1.4,
#>             0.2,
#>             "setosa"
#>         ]
#>     ]
#> }
```

Similarly, to read a Dataset JSON object, you can use the function
[`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md).
This function will return a dataframe to you, ready to use. To read,
provide a file path.

``` r

read_dataset_json("path/to/file")
```

You can also provide single element character vector of the JSON text
already read in.

``` r

dat <- read_dataset_json(js)
```

### NDJSON

Dataset JSON also has a newline-delimited representation, which carries
exactly the same content with different framing: the dataset metadata as
a single JSON object on line 1, then one JSON array per data row. This
makes a dataset straightforward to read or write a row at a time rather
than loading the whole file.

[`write_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_ndjson.md)
and
[`read_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_ndjson.md)
mirror their JSON counterparts, and
[`validate_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_ndjson.md)
checks a file against the Dataset NDJSON schema.

``` r

write_dataset_ndjson(ds_json, file = "iris.ndjson")

dat <- read_dataset_ndjson("iris.ndjson")
```

As with
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md),
leaving out `file` returns the content instead, which shows the shape of
the format - the metadata object first, then one array per row:

``` r

nd <- write_dataset_ndjson(ds_json)
cat(nd)
#> {"datasetJSONCreationDateTime":"2026-09-04T00:56:05","datasetJSONVersion":"1.1.0","itemGroupOID":"IG.IRIS","records":5,"name":"IRIS","label":"Iris","columns":[{"itemOID":"IT.IR.Sepal.Length","name":"Sepal.Length","label":"Sepal Length","dataType":"float","keySequence":2},{"itemOID":"IT.IR.Sepal.Width","name":"Sepal.Width","label":"Sepal Width","dataType":"float"},{"itemOID":"IT.IR.Petal.Length","name":"Petal.Length","label":"Petal Length","dataType":"float","keySequence":3},{"itemOID":"IT.IR.Petal.Width","name":"Petal.Width","label":"Petal Width","dataType":"float"},{"itemOID":"IT.IR.Species","name":"Species","label":"Flower Species","dataType":"string","length":10,"keySequence":1}]}
#> [5.1,3.5,1.4,0.2,"setosa"]
#> [4.9,3.0,1.4,0.2,"setosa"]
#> [4.7,3.2,1.3,0.2,"setosa"]
#> [4.6,3.1,1.5,0.2,"setosa"]
#> [5.0,3.6,1.4,0.2,"setosa"]
```

The two formats are interchangeable - reading `iris.json` and
`iris.ndjson` written from the same object gives you the same dataframe,
with the same attributes.

### Compressed files

Dataset JSON files are text, and text of this shape compresses very
well. The standard defines a compressed representation, DSJC, which is
simply the NDJSON content of a dataset as a zLib stream - no header, no
wrapper, nothing but the compressed bytes. Files use the `.dsjc`
extension.

[`write_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_dsjc.md),
[`read_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_dsjc.md)
and
[`validate_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_dsjc.md)
mirror the other two sets of functions:

``` r

write_dataset_dsjc(ds_json, file = "iris.dsjc")

dat <- read_dataset_dsjc("iris.dsjc")
```

Because a DSJC file is a plain zLib stream, any zLib implementation can
read it, and a stream produced by another tool reads here. The example
files shipped with the package show the size difference on a small
dataset:

``` r

sizes <- vapply(
  c("dm.json", "dm.ndjson", "dm.dsjc"),
  function(f) file.size(datasetjson_example(f)),
  numeric(1)
)

sizes
#>   dm.json dm.ndjson   dm.dsjc 
#>      7984      7976      1644
```

The saving grows with the dataset. On a 300,000 row file the NDJSON is
26 MB and the DSJC around 11 MB.

`level` controls the compression, from 0 (none) to 9. It defaults to 9,
which the standard recommends for data exchange, but the top of the
range earns little: on that same 26 MB dataset, level 1 wrote in a fifth
of the time for a file only 4% larger. Reading is unaffected by the
level a file was written at.

With no `file` argument,
[`write_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_dsjc.md)
returns a raw vector rather than a character string, since the format is
binary:

``` r

bytes <- write_dataset_dsjc(ds_json)

head(bytes)
#> [1] 78 da 95 92 d1 4e
```

Rows are compressed as they are written, so producing a large file never
holds the whole uncompressed dataset in memory.

The data frame that’s read in is itself a `datasetjson` object and
carries a number of attributes. For example, opening the dataframe
within the RStudio IDE will present the variable labels. Additionally,
the extra metadata provided in a Dataset JSON file is available. The
attributes provided follow the naming convention of the Dataset JSON
standard.

### Working with the metadata

Everything above is what you need to read and write Dataset JSON files.
The two functions in this section are optional conveniences for working
with the column metadata once a file is read, and can be skipped on a
first pass.

If you’d like to grab the column metadata from the `columns` element,
you can use the function
[`get_column_metadata()`](https://atorus-research.github.io/datasetjson/reference/get_column_metadata.md)

``` r

get_column_metadata(dat)
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

With this column metadata available, you can additionally use the
function
[`set_variable_attributes()`](https://atorus-research.github.io/datasetjson/reference/set_variable_attributes.md)
to apply the `columns` metadata to the individual variables within the
data frame.

``` r

dat <- set_variable_attributes(dat)
attributes(dat$Species)
#> $label
#> [1] "Flower Species"
#> 
#> $itemOID
#> [1] "IT.IR.Species"
#> 
#> $dataType
#> [1] "string"
#> 
#> $length
#> [1] 10
#> 
#> $keySequence
#> [1] 1
```
