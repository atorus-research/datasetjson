
# **datasetjson** <img src="man/figures/logo.svg" align="right" alt="" width="120" />

<!-- badges: start -->

[<img src="https://img.shields.io/codecov/c/github/atorus-research/datasetjson">](https://app.codecov.io/gh/atorus-research/datasetjson)
[<img src="https://img.shields.io/badge/License-APACHE2-blue.svg">](https://github.com/atorus-research/datasetjson/blob/main/LICENSE.md)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Welcome to **datasetjson**. **datasetjson** is an R package built to
read and write [CDISC Dataset
JSON](https://www.cdisc.org/standards/data-exchange/dataset-json)
formatted datasets.

If you’re stumbling into the world of Dataset JSON, you might be
wondering “Why JSON?”, as many have asked this question. We highly
recommend you take a pit stop to read [this blog
post](https://swhume.github.io/why-json-for-datasets) by Sam Hume one of
the creators of the Dataset JSON standard.

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
ds_json <- dataset_json(
  head(iris, 5),
  file_oid = "/some/path",
  last_modified = "2023-02-15T10:23:15",
  originator = "Some Org",
  sys = "source system",
  sys_version = "1.0",
  study = "SOMESTUDY",
  metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
  metadata_ref = "some/define.xml",
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)
```

To attach necessary metadata (that can’t be inferred by the input
dataframe or at time of write) to the `datasetjson` object, you can use
a variety of setter functions:

``` r
ds_json <- dataset_json(
    head(iris, 5),
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  ) |>
  set_file_oid("/some/path") |>
  set_last_modified("2025-01-21T13:34:50") |>
  set_originator("Some Org") |>
  set_source_system("source system", "1.0") |>
  set_study_oid("SOMESTUDY") |>
  set_metadata_ref("some/define.xml") |>
  set_metadata_version("MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
```

Once the `datasetjson` object is prepared with the necessary metadata,
you can use `write_dataset_json()` to write the file to disk.

``` r
write_dataset_json(ds_json, file = "./iris.json")
```

Or if you don’t provide a file path, the JSON text will return directly.

``` r
js_text <- write_dataset_json(ds_json, pretty=TRUE)
cat(js_text)
```

    ## {
    ##   "datasetJSONCreationDateTime": "2025-01-27T16:45:36",
    ##   "datasetJSONVersion": "1.1.0",
    ##   "fileOID": "/some/path",
    ##   "dbLastModifiedDateTime": "2025-01-21T13:34:50",
    ##   "originator": "Some Org",
    ##   "sourceSystem": {
    ##     "name": "source system",
    ##     "version": "1.0"
    ##   },
    ##   "studyOID": "SOMESTUDY",
    ##   "metaDataVersionOID": "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    ##   "metaDataRef": "some/define.xml",
    ##   "itemGroupOID": "IG.IRIS",
    ##   "records": 5,
    ##   "name": "IRIS",
    ##   "label": "Iris",
    ##   "columns": [
    ##     {
    ##       "itemOID": "IT.IR.Sepal.Length",
    ##       "name": "Sepal.Length",
    ##       "label": "Sepal Length",
    ##       "dataType": "float",
    ##       "keySequence": 2
    ##     },
    ##     {
    ##       "itemOID": "IT.IR.Sepal.Width",
    ##       "name": "Sepal.Width",
    ##       "label": "Sepal Width",
    ##       "dataType": "float"
    ##     },
    ##     {
    ##       "itemOID": "IT.IR.Petal.Length",
    ##       "name": "Petal.Length",
    ##       "label": "Petal Length",
    ##       "dataType": "float",
    ##       "keySequence": 3
    ##     },
    ##     {
    ##       "itemOID": "IT.IR.Petal.Width",
    ##       "name": "Petal.Width",
    ##       "label": "Petal Width",
    ##       "dataType": "float"
    ##     },
    ##     {
    ##       "itemOID": "IT.IR.Species",
    ##       "name": "Species",
    ##       "label": "Flower Species",
    ##       "dataType": "string",
    ##       "length": 10,
    ##       "keySequence": 1
    ##     }
    ##   ],
    ##   "rows": [
    ##     [
    ##       5.1,
    ##       3.5,
    ##       1.4,
    ##       0.2,
    ##       "setosa"
    ##     ],
    ##     [
    ##       4.9,
    ##       3.0,
    ##       1.4,
    ##       0.2,
    ##       "setosa"
    ##     ],
    ##     [
    ##       4.7,
    ##       3.2,
    ##       1.3,
    ##       0.2,
    ##       "setosa"
    ##     ],
    ##     [
    ##       4.6,
    ##       3.1,
    ##       1.5,
    ##       0.2,
    ##       "setosa"
    ##     ],
    ##     [
    ##       5.0,
    ##       3.6,
    ##       1.4,
    ##       0.2,
    ##       "setosa"
    ##     ]
    ##   ]
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
RStudio IDE will present the variable labels. All the other metadata
contained within the Dataset JSON file is attached as attributes to the
resulting dataframe.

``` r
print(attr(dat, 'dbLastModifiedDateTime'))
```

    ## [1] "2025-01-21T13:34:50"

``` r
print(attr(dat, 'fileOID'))
```

    ## [1] "/some/path"

This package currently supports Dataset JSON Version 1.1.0. Support for
Version 1.0.0 has been dropped, as version 1.1.0 is intended to be the
first stable version of the standard.

# [<img src="man/figures/cdisc.png" alt="" width="120" />](https://www.cdisc.org/)

## Acknowledgements

Thank you to Ben Straub and Eric Simms (GSK) for help and input during
the original CDISC Dataset JSON hackathon that motivated this work.
