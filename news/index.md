# Changelog

## datasetjson 0.4.0

### JSON handling moved into the package

Reading and writing are now handled by the `yyjson` C library, bundled
with the package, rather than by an R JSON package. The practical
effects:

- **Numbers survive a write and read unchanged.** Previously a float
  below roughly 5e-7 was read back as `0`, and larger values could lose
  their final digits. Values are now written at the shortest precision
  that reads back identically, and parsed to a double in C rather than
  through R. Files written by earlier versions are unaffected - the loss
  happened on read, so re-reading them with this version recovers the
  original values
  ([\#97](https://github.com/atorus-research/datasetjson/issues/97)).
- **Reading is substantially faster** - roughly 15-18x on files of a few
  hundred thousand rows and up, and it scales linearly with file size.
- `yyjsonr` and `jsonvalidate` are no longer required. `Imports` is now
  just `hms`; `jsonvalidate` moved to `Suggests` and is needed only for
  the `validate_*()` functions
  ([\#70](https://github.com/atorus-research/datasetjson/issues/70)).

### New formats

- [`read_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_ndjson.md),
  [`write_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_ndjson.md)
  and
  [`validate_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_ndjson.md)
  support the Dataset NDJSON representation, where the dataset metadata
  forms the first line and each row follows as a JSON array.
- [`read_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_dsjc.md),
  [`write_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_dsjc.md)
  and
  [`validate_dataset_dsjc()`](https://atorus-research.github.io/datasetjson/reference/validate_dataset_dsjc.md)
  support Dataset JSON Compressed (`.dsjc`), a zLib stream of Dataset
  NDJSON content. Rows are compressed as they are written, so a large
  dataset never needs its uncompressed form held in memory
  ([\#78](https://github.com/atorus-research/datasetjson/issues/78)).
- [`datasetjson_example()`](https://atorus-research.github.io/datasetjson/reference/datasetjson_example.md)
  now ships `dm.json`, `dm.ndjson` and `dm.dsjc`.

### Behavior changes

- `decimals_as_floats` has been removed from
  [`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md).
  Columns with `dataType = "decimal"` and `targetDataType = "decimal"`
  are always converted to numeric on read, as the Dataset JSON v1.1
  specification requires
  ([\#77](https://github.com/atorus-research/datasetjson/issues/77)).
- `digits` is deprecated in
  [`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
  and
  [`write_dataset_ndjson()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_ndjson.md).
  It is ignored, and supplying it warns. Decimals are written at
  whatever precision reads back as the same value, so there is no
  precision left for it to control. To render values at a fixed
  precision, format the column to character yourself and declare it as
  `decimal`/`decimal` in the column metadata.
- `float_as_decimals` is no longer needed to protect precision and
  setting it now warns to say so. It remains available as an
  interoperability choice for systems that require the `decimal` type.
- Reading a file whose columns lack a `name`, or whose `records` value
  is missing, now reports the problem rather than failing obscurely or
  silently substituting a value.

### Fixes

- [`read_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/read_dataset_json.md)
  sets `format.sas` from the `displayFormat` column attribute
  ([\#87](https://github.com/atorus-research/datasetjson/issues/87)).
- Reading from a URL returned only the first line of the file, so any
  pretty-printed JSON lost everything after it and NDJSON returned no
  rows.
- [`write_dataset_json()`](https://atorus-research.github.io/datasetjson/reference/write_dataset_json.md)
  with `float_as_decimals = TRUE` wrote `NA` as a padded string rather
  than JSON `null`
  ([\#76](https://github.com/atorus-research/datasetjson/issues/76)).
- `extract_xpt_meta()` in the `converting_files` vignette could return
  `-Inf` for the `length` of an empty or all-`NA` string column; the
  minimum is now 1
  ([\#71](https://github.com/atorus-research/datasetjson/issues/71)).

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
