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
| targetDataType | Required | Type of the variable. Allowed values: “integer”, “decimal”. Indicates the data type into which the receiving system must transform the associated Dataset-JSON variable. |
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
#>   "datasetJSONCreationDateTime": "2026-08-14T19:59:33",
#>   "datasetJSONVersion": "1.1.0",
#>   "itemGroupOID": "IG.IRIS",
#>   "records": 5,
#>   "name": "IRIS",
#>   "label": "Iris",
#>   "columns": [
#>     {
#>       "itemOID": "IT.IR.Sepal.Length",
#>       "name": "Sepal.Length",
#>       "label": "Sepal Length",
#>       "dataType": "float",
#>       "keySequence": 2
#>     },
#>     {
#>       "itemOID": "IT.IR.Sepal.Width",
#>       "name": "Sepal.Width",
#>       "label": "Sepal Width",
#>       "dataType": "float"
#>     },
#>     {
#>       "itemOID": "IT.IR.Petal.Length",
#>       "name": "Petal.Length",
#>       "label": "Petal Length",
#>       "dataType": "float",
#>       "keySequence": 3
#>     },
#>     {
#>       "itemOID": "IT.IR.Petal.Width",
#>       "name": "Petal.Width",
#>       "label": "Petal Width",
#>       "dataType": "float"
#>     },
#>     {
#>       "itemOID": "IT.IR.Species",
#>       "name": "Species",
#>       "label": "Flower Species",
#>       "dataType": "string",
#>       "length": 10,
#>       "keySequence": 1
#>     }
#>   ],
#>   "rows": [
#>     [
#>       5.1,
#>       3.5,
#>       1.4,
#>       0.2,
#>       "setosa"
#>     ],
#>     [
#>       4.9,
#>       3.0,
#>       1.4,
#>       0.2,
#>       "setosa"
#>     ],
#>     [
#>       4.7,
#>       3.2,
#>       1.3,
#>       0.2,
#>       "setosa"
#>     ],
#>     [
#>       4.6,
#>       3.1,
#>       1.5,
#>       0.2,
#>       "setosa"
#>     ],
#>     [
#>       5.0,
#>       3.6,
#>       1.4,
#>       0.2,
#>       "setosa"
#>     ]
#>   ]
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

The data frame that’s read in is itself a `datasetjson` object and
carries a number of attributes. For example, opening the dataframe
within the RStudio IDE will present the variable labels. Additionally,
the extra metadata provided in a Dataset JSON file is available. The
attributes provided follow the naming convention of the Dataset JSON
standard.

We’ve provided some helper functions to leverage this data further. If
you’d like to grab the column metadata from the `columns` element, you
can use the function
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
#> $keySequence
#> [1] 1
#> 
#> $length
#> [1] 10
```
