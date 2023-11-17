
# **datasetjson** <img src="man/figures/logo.svg" align="right" alt="" width="120" />

<!-- badges: start -->

[<img src="https://img.shields.io/codecov/c/github/atorus-research/datasetjson">](https://app.codecov.io/gh/atorus-research/datasetjson)
[<img src="https://img.shields.io/badge/License-APACHE2-blue.svg">](https://github.com/atorus-research/datasetjson/blob/main/LICENSE.md)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Welcome to **datasetjson**. **datasetjson** is an R package built to
read and write [CDISC Dataset JSON](https://www.cdisc.org/dataset-json)
formatted datasets.

As always, we welcome your feedback. If you spot a bug, would like to
see a new feature, or if any documentation is unclear - submit an issue
through GitHub right
[here](https://github.com/atorus-research/datasetjson/issues).

# Installation

You can install **datasetjson** with:

``` r
# Install from CRAN:
install.packages("datasetjson")

# Or install the development version:
devtools::install_github("https://github.com/atorus-research/datasetjson.git", ref="dev")
```

# Using **datasetjson**

**datasetjson** works by allowing you to take a data frame and apply the
necessary attributes required for the CDISC Dataset JSON. The goal is to
make this experience simple. Before you can write a Dataset JSON file to
disk, you first need to build the Dataset JSON object. An example call
looks like this:

``` r
ds_json <- dataset_json(iris[1:5, ], "IG.IRIS", "IRIS", "Iris", iris_items)
```

To attach necessary metadata (that can’t be inferred by the input
dataframe) to the `datasetjson` object, you can use a variety of setter
functions:

``` r
ds_updated <- ds_json |>
  set_data_type("referenceData") |>
  set_file_oid("/some/path") |>
  set_metadata_ref("some/define.xml") |>
  set_metadata_version("MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7") |>
  set_originator("Some Org") |>
  set_source_system("source system", "1.0") |>
  set_study_oid("SOMESTUDY")
```

If these settings are not provided, `dataset_json()` will default the
fields to “NA” so a compliant file can still be generated.

Once the `datasetjson` object is prepared with the necessary metadata,
you can use `write_dataset_json()` to write the file to disk.

``` r
write_dataset_json(ds_updated, file = "./iris.json")
```

Or if you don’t provide a file path, the JSON text will return directly.

``` r
js_text <- write_dataset_json(ds_updated, pretty=TRUE)
cat(js_text)
```

    ## {
    ##   "creationDateTime": "2023-11-17T13:23:08",
    ##   "datasetJSONVersion": "1.0.0",
    ##   "fileOID": "/some/path",
    ##   "originator": "Some Org",
    ##   "sourceSystem": "source system",
    ##   "sourceSystemVersion": "1.0",
    ##   "referenceData": {
    ##     "studyOID": "SOMESTUDY",
    ##     "metaDataVersionOID": "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    ##     "metaDataRef": "some/define.xml",
    ##     "itemGroupData": {
    ##       "IG.IRIS": {
    ##         "records": 5,
    ##         "name": "IRIS",
    ##         "label": "Iris",
    ##         "items": [
    ##           {
    ##             "OID": "ITEMGROUPDATASEQ",
    ##             "name": "ITEMGROUPDATASEQ",
    ##             "label": "Record Identifier",
    ##             "type": "integer"
    ##           },
    ##           {
    ##             "OID": "IT.IR.Sepal.Length",
    ##             "name": "Sepal.Length",
    ##             "label": "Sepal Length",
    ##             "type": "float",
    ##             "keySequence": 2
    ##           },
    ##           {
    ##             "OID": "IT.IR.Sepal.Width",
    ##             "name": "Sepal.Width",
    ##             "label": "Sepal Width",
    ##             "type": "float"
    ##           },
    ##           {
    ##             "OID": "IT.IR.Petal.Length",
    ##             "name": "Petal.Length",
    ##             "label": "Petal Length",
    ##             "type": "float",
    ##             "keySequence": 3
    ##           },
    ##           {
    ##             "OID": "IT.IR.Petal.Width",
    ##             "name": "Petal.Width",
    ##             "label": "Petal Width",
    ##             "type": "float"
    ##           },
    ##           {
    ##             "OID": "IT.IR.Species",
    ##             "name": "Species",
    ##             "label": "Flower Species",
    ##             "type": "string",
    ##             "length": 10,
    ##             "keySequence": 1
    ##           }
    ##         ],
    ##         "itemData": [
    ##           [1, 5.1, 3.5, 1.4, 0.2, "setosa"],
    ##           [2, 4.9, 3, 1.4, 0.2, "setosa"],
    ##           [3, 4.7, 3.2, 1.3, 0.2, "setosa"],
    ##           [4, 4.6, 3.1, 1.5, 0.2, "setosa"],
    ##           [5, 5, 3.6, 1.4, 0.2, "setosa"]
    ##         ]
    ##       }
    ##     }
    ##   }
    ## }

To read a Dataset JSON file, you can use `read_dataset_json()`. You can
either provide the path to a JSON file, or if you already have the JSON
text loaded into a character string, you can provide that directly.

``` r
dat <- read_dataset_json(js_text)
dat
```

    ##   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
    ## 1          5.1         3.5          1.4         0.2  setosa
    ## 2          4.9         3.0          1.4         0.2  setosa
    ## 3          4.7         3.2          1.3         0.2  setosa
    ## 4          4.6         3.1          1.5         0.2  setosa
    ## 5          5.0         3.6          1.4         0.2  setosa

The data frame that’s returned is enriched with attributes available in
the Dataset JSON format. For example, opening the dataframe within the
RStudio IDE will present the variable labels. The other variable is
attached as attributes on individual columns, and file level metadata is
attached as attributes on the data frame itself:

``` r
print(attr(dat, "creationDateTime"))
```

    ## [1] "2023-11-17T13:23:08"

``` r
print(attr(dat$Sepal.Length, "OID"))
```

    ## [1] "IT.IR.Sepal.Length"

``` r
print(attr(dat$Sepal.Width, "type"))
```

    ## [1] "float"

Note that Dataset JSON is an early CDISC standard and is still subject
to change, as as such this package will be updated. Backwards
compatibility will be enforced once the standard itself is more stable.
Until then, it is not recommended to use this package within production
activities.

# [<img src="man/figures/cdisc.png" alt="" width="120" />](https://www.cdisc.org/)

## Acknowledgements

Thank you to Ben Straub and Eric Simms (GSK) for help and input during
the original CDISC Dataset JSON hackathon that motivated this work.
