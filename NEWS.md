# datasetjson 0.3.0

This release provides a significant overhaul of the package due to the updates 
for Dataset JSON 1.1.0. Performance has also been significantly improved, as well
as the main object interface.

-  Initial support for Dataset JSON v1.1.0 schema
-  Flip JSON backend to {yyjsonr} (#32)
-  Redesign of core objects
-  New vignettes and helper functions

# datasetjson 0.2.0

- Remove schema validation on read and write (#26)
- Address CRAN issues (#29)

# datasetjson 0.1.0

-   Capability to read and validate Dataset JSON files from URLs has been added (#8)
-   Remove autoset of fileOID using output path (#3)
-   Don't auto-populate optional attributes with NA (#16)
-   Push dependency versions back (#18)
-   Default `pretty` parameter on `write_dataset_json()` to false (#20)

# datasetjson 0.0.1

Initial development version of datasetjson, introducing core objects, readers and writers.
