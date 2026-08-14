# Example Variable Metadata for Iris

Example of the necessary variable metadata included in a Dataset JSON
file based on the Iris data frame.

## Usage

``` r
iris_items
```

## Format

### `iris_items` A data frame with 5 rows and 6 columns:

- itemOID:

  Unique identifier for Variable. Must correspond to ItemDef/@OID in
  Define-XML.

- name:

  Display format supports data visualization of numeric float and date
  values.

- label:

  Label for Variable

- dataType:

  Data type for Variable

- length:

  Length for Variable

- keySequence:

  Indicates that this item is a key variable in the dataset structure.
  It also provides an ordering for the keys.
