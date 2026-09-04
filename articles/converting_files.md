# Converting from XPT

``` r

library(datasetjson)
```

Some users may be interested in converting SAS Version 5 Transport files
into XPT, or converting from other file types such as SAS7BDAT. There
may be some existing processes in place to do this in SAS, such as a
post-processing conversion step where files are converted in bulk. This
vignette offers some guidance and best practice for doing this process
in R.

## Converting from XPT

Ideally if you’re converting from an XPT file or a SAS7BDAT file, the
appropriate metadata would be maintained separate from the dataset
itself. Inevitably some information will get lost while being exchanged
because of differences of what information was applied or how R
interprets SAS datasets. This is one reason why **{datasetjson}**
improves upon XPTs as an exchange format. In lieu of external metadata,
here’s an example of how you can make a best effort conversion.

``` r

adsl <- haven::read_xpt(file.path(system.file(package='datasetjson'), "adsl.xpt"))

#' Gather variable metadata in Dataset JSON compliant format
#'
#' @param n Variable name
#' @param .data Dataset to gather attributes
#'
#' @returns Columns compliant data frame
extract_xpt_meta <- function(n, .data) {
  
  attrs <- attributes(.data[[n]])
  
  out <- list()

  # Identify the variable type
  if (inherits(.data[[n]],"Date")) {
    out$dataType <- "date"
    out$targetDataType <- "integer"
  } else if (inherits(.data[[n]],"POSIXt")) {
    out$dataType <- "datetime"
    out$targetDataType <- "integer"
  } else if (inherits(.data[[n]],"numeric")) {
    if (any(is.double(.data[[n]]))) out$dataType <- "float"
    else out$dataType <- "integer"
  }  else if (inherits(.data[[n]],"hms")) {
    out$dataType <- "time"
    out$targetDataType <- "integer"
  } else {
    out$dataType <- "string"
    out$length <- max(purrr::map_int(.data[[n]], nchar), 1L)
  }
  
  out$itemOID <- n
  out$name <- n
  out$label <- attr(.data[[n]], 'label')
  out$displayFormat <- attr(.data[[n]], 'format.sas')
  tibble::as_tibble(out)
  
}

# Loop the ADSL columns
adsl_meta <- purrr::map_df(names(adsl), extract_xpt_meta, .data=adsl)
adsl_meta
#> # A tibble: 49 × 7
#>    dataType length itemOID name    label            targetDataType displayFormat
#>    <chr>     <int> <chr>   <chr>   <chr>            <chr>          <chr>        
#>  1 string       12 STUDYID STUDYID Study Identifier NA             NA           
#>  2 string       11 USUBJID USUBJID Unique Subject … NA             NA           
#>  3 string        4 SUBJID  SUBJID  Subject Identif… NA             NA           
#>  4 string        3 SITEID  SITEID  Study Site Iden… NA             NA           
#>  5 string        3 SITEGR1 SITEGR1 Pooled Site Gro… NA             NA           
#>  6 string       20 ARM     ARM     Description of … NA             NA           
#>  7 string       20 TRT01P  TRT01P  Planned Treatme… NA             NA           
#>  8 float        NA TRT01PN TRT01PN Planned Treatme… NA             NA           
#>  9 string       20 TRT01A  TRT01A  Actual Treatmen… NA             NA           
#> 10 float        NA TRT01AN TRT01AN Actual Treatmen… NA             NA           
#> # ℹ 39 more rows
```

Now that we have the metadata, we can use this to write out the Dataset
JSON file.

``` r

# Create the datasetjson object
ds_json <- dataset_json(
  adsl, 
  item_oid = "ADSL",
  name = "ADSL",
  dataset_label = attr(adsl, 'label'),
  columns = adsl_meta
)

# Write the JSON
json_file_content <- write_dataset_json(ds_json)
```

Just for good measure, we can confirm the metadata we just created is
compliant with the schema.

``` r

# Check schema compliance. jsonvalidate is a suggested package rather than a
# hard dependency, so guard the call.
if (requireNamespace("jsonvalidate", quietly = TRUE)) {
  validate_dataset_json(json_file_content)
}
#> File is valid per the Dataset JSON v1.1.0 schema
#> [1] instancePath schemaPath   keyword      params       message     
#> [6] schema       parentSchema dataPath    
#> <0 rows> (or 0-length row.names)
```

## Bulk File Conversion

If your intention is to convert files into Dataset JSON format in bulk,
there are a couple things you should consider - especially if you’re
trying to replicate existing procedures done using SAS:

Remember that R by default holds data in memory, whereas work datasets
in SAS are still written to disk. This means that if you’re doing a bulk
conversion of datasets, you’ll want to read in and write out one dataset
at a time. For example:

1.  Read in the XPT or SAS7BDAT file
2.  Write out the Dataset JSON file
3.  Remove the objects from memory to free up space

It’s likely best to wrap the conversion process in a function, because
the function namespace will inherently release the temporary objects
during garbage collection. Depending on the size of your data, it could
be easy to max out memory if you first read in all the datasets.

A second consideration is use of the function
[`validate_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_json.md).
Particularly if you have large datasets, we recommend *against* using
this function. The validation it performs is against the Dataset JSON
schema - so it’s not performing additional CDISC checks on the data. We
offer this function primarily due to the fact that the schema is
available, and if necessary the function allows you to check that the
schema compliance is met. That said, we’ve done the testing to make sure
that
[`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
writes the file out using a compliant schema - so this step is
redundant.
