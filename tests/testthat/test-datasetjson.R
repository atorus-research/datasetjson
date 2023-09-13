# Objects to use for testing
ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
iris_items_list <- readRDS(test_path("testdata", "iris_items_list.Rds"))

# This test will verify that everything lands where expected and auto-calculated
# fields populate properly
test_that("datasetjson object builds with minimal defaults", {

  # I just want to remove the potential for a corner case
  # where the call to system time splits across a second
  expect_equal(grep("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", ds_json$creationDateTime), 1)

  # File metadata
  expect_equal(ds_json$datasetJSONVersion, "1.0.0")
  expect_equal(ds_json$fileOID, character())
  expect_equal(ds_json$asOfDateTime, character())
  expect_equal(ds_json$originator, "NA")
  expect_equal(ds_json$sourceSystem, "NA")
  expect_equal(ds_json$sourceSystemVersion, "NA")

  # Data type is correct
  expect_equal(tail(names(ds_json), 1), "clinicalData")

  # Data metadata
  expect_equal(ds_json$clinicalData$studyOID, "NA")
  expect_equal(ds_json$clinicalData$metaDataVersionOID, "NA")
  expect_equal(ds_json$clinicalData$metaDataRef, "NA")

  # item_id passes through
  expect_equal(names(ds_json$clinicalData$itemGroupData), "IG.IRIS")

  # Dataset metadata
  expect_equal(ds_json$clinicalData$itemGroupData$IG.IRIS$records, nrow(iris))
  expect_equal(ds_json$clinicalData$itemGroupData$IG.IRIS$name, "IRIS")
  expect_equal(ds_json$clinicalData$itemGroupData$IG.IRIS$label, "Iris")

  # Verify that ITEMGROUPSEQ is attached properly
  iris_items_test <- rbind(
    data.frame(OID  = "ITEMGROUPDATASEQ",
               name = "ITEMGROUPDATASEQ",
               label = "Record Identifier",
               type = "integer",
               length = NA_integer_,
               keySequence = NA_integer_,
               displayFormat = NA_character_),
    iris_items
  )

  expect_equal(ds_json$clinicalData$itemGroupData$IG.IRIS$items, iris_items_list)

  # Verify that data are attached properly with ITEMGRPUPSEQ attached
  iris_test <- cbind(
    ITEMGROUPDATASEQ = 1:nrow(iris),
    iris
  )

  expect_equal(ds_json$clinicalData$itemGroupData$IG.IRIS$itemData, iris_test)
})

test_that("datasetjson setter functions insert info in the right fields", {
  ds_json_updated <- set_data_type(ds_json, "referenceData")
  ds_json_updated <- set_file_oid(ds_json_updated, "/some/path")
  ds_json_updated <- set_metadata_ref(ds_json_updated, "some/define.xml")
  ds_json_updated <- set_metadata_version(ds_json_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  ds_json_updated <- set_originator(ds_json_updated, "Some Org")
  ds_json_updated <- set_source_system(ds_json_updated, "source system", "1.0")
  ds_json_updated <- set_study_oid(ds_json_updated, "SOMESTUDY")

  expect_equal(tail(names(ds_json_updated), 1), "referenceData")
  expect_equal(ds_json_updated$fileOID, "/some/path")
  expect_equal(ds_json_updated$originator, "Some Org")
  expect_equal(ds_json_updated$sourceSystem, "source system")
  expect_equal(ds_json_updated$sourceSystemVersion, "1.0")
  expect_equal(ds_json_updated$referenceData$studyOID, "SOMESTUDY")
  expect_equal(ds_json_updated$referenceData$metaDataVersionOID, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  expect_equal(ds_json_updated$referenceData$metaDataRef, "some/define.xml")
})

test_that("Data type passes through", {
  x <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items, data_type = "referenceData")
  expect_equal(tail(names(x), 1), "referenceData")
})

# Error checking
test_that("Errors are thrown properly", {
  expect_error(
    dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items, data_type = "blah"),
    regexp = "should be one of"
    )

  expect_error(
    dataset_json(iris, item_id = "IG.IRIS", name = "IRIS", items = iris_items),
    "If dataset_meta is not provided, then name, label, and items must be provided"
  )

  expect_error(
    dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items, version="2"),
    regexp = "Unsupported version specified"
  )
})

test_that("Object builds from prespecified metadata objects", {
  file_meta <- file_metadata(
    originator = "Some Org",
    sys = "source system",
    sys_version = "1.0"
  )

  data_meta <- data_metadata(
    study = "SOMESTUDY",
    metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    metadata_ref = "some/define.xml"
  )

  dataset_meta <- dataset_metadata(
    item_id = "IG.IRIS",
    name = "IRIS",
    label = "Iris",
    items = iris_items
  )

  ds_json_from_meta <- dataset_json(iris,
                                    dataset_meta = dataset_meta,
                                    file_meta = file_meta,
                                    data_meta = data_meta)


  expect_equal(tail(names(ds_json_from_meta), 1), "clinicalData")
  expect_equal(ds_json_from_meta$originator, "Some Org")
  expect_equal(ds_json_from_meta$sourceSystem, "source system")
  expect_equal(ds_json_from_meta$sourceSystemVersion, "1.0")
  expect_equal(ds_json_from_meta$clinicalData$studyOID, "SOMESTUDY")
  expect_equal(ds_json_from_meta$clinicalData$metaDataVersionOID, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  expect_equal(ds_json_from_meta$clinicalData$metaDataRef, "some/define.xml")
})
