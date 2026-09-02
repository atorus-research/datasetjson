# Changelog

## datasetjson 0.4.0

- `decimals_as_floats` parameter removed from
  [`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md).
  Variables with `dataType = "decimal"` and `targetDataType = "decimal"`
  are now always converted to numeric on read, per the Dataset JSON v1.1
  specification.
- Fixed a bug in the `converting_files` vignette where
  `extract_xpt_meta()` could return `-Inf` for the `length` field of
  empty or all-NA string columns; minimum length is now 1
  ([\#71](https://github.com/atorus-research/datasetjson/issues/71))
- Fixed a bug where
  [`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
  with `float_as_decimals = TRUE` would write `NA` values as padded
  strings (e.g., `" NA"`) instead of JSON `null`
  ([\#76](https://github.com/atorus-research/datasetjson/issues/76))

## datasetjson 0.3.0

CRAN release: 2025-01-30

This release provides a significant overhaul of the package due to the
updates for Dataset JSON 1.1.0. Performance has also been significantly
improved, as well as the main object interface.

- Initial support for Dataset JSON v1.1.0 schema
- Flip JSON backend to {yyjsonr}
  ([\#32](https://github.com/atorus-research/datasetjson/issues/32))
- Redesign of core objects
- New vignettes and helper functions

## datasetjson 0.2.0

CRAN release: 2024-01-09

- Remove schema validation on read and write
  ([\#26](https://github.com/atorus-research/datasetjson/issues/26))
- Address CRAN issues
  ([\#29](https://github.com/atorus-research/datasetjson/issues/29))

## datasetjson 0.1.0

CRAN release: 2023-10-13

- Capability to read and validate Dataset JSON files from URLs has been
  added ([\#8](https://github.com/atorus-research/datasetjson/issues/8))
- Remove autoset of fileOID using output path
  ([\#3](https://github.com/atorus-research/datasetjson/issues/3))
- Don’t auto-populate optional attributes with NA
  ([\#16](https://github.com/atorus-research/datasetjson/issues/16))
- Push dependency versions back
  ([\#18](https://github.com/atorus-research/datasetjson/issues/18))
- Default `pretty` parameter on
  [`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
  to false
  ([\#20](https://github.com/atorus-research/datasetjson/issues/20))

## datasetjson 0.0.1

CRAN release: 2023-09-14

Initial development version of datasetjson, introducing core objects,
readers and writers.
