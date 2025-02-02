ds_json <- dataset_json(
  iris,
  # file_oid = "/some/path",
  # last_modified = "2023-02-15T10:23:15",
  # originator = "Some Org",
  # sys = "source system",
  # sys_version = "1.0",
  # study = "SOMESTUDY",
  # metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
  # metadata_ref = "some/define.xml",
  item_oid = "IG.IRIS",
  name = "IRIS",
  dataset_label = "Iris",
  columns = iris_items
)

iris_items_list <- readRDS(test_path("testdata", "iris_items_list.Rds"))

# This test will verify that everything lands where expected and auto-calculated
# fields populate properly
test_that("datasetjson object builds with minimal defaults", {

  # I just want to remove the potential for a corner case
  # where the call to system time splits across a second
  # expect_equal(grep("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", ds_json$creationDateTime), 1)

  # Metadata
  expect_null(attr(ds_json, "datasetJSONCreationDateTime"))
  expect_equal(attr(ds_json, "datasetJSONVersion"), "1.1.0")
  expect_null(attr(ds_json, "fileOID"))
  expect_null(attr(ds_json, "dbLastModifiedDateTime"))
  expect_null(attr(ds_json, "originator"))
  expect_null(attr(ds_json, "sourceSystem"))
  expect_null(attr(ds_json, "studyOID"))
  expect_null(attr(ds_json, "metaDataVersionOID"))
  expect_null(attr(ds_json, "metaDataRef"))
  expect_equal(attr(ds_json, "itemGroupOID"), "IG.IRIS")
  expect_null(attr(ds_json, "records"))
  expect_equal(attr(ds_json, "name"), "IRIS")
  expect_equal(attr(ds_json, "label"), "Iris")
  expect_equal(attr(ds_json, "columns"), iris_items_list)

})

test_that("datasetjson setter functions insert info in the right fields", {
  ds_json_updated <- set_file_oid(ds_json, "/some/path")
  ds_json_updated <- set_metadata_ref(ds_json_updated, "some/define.xml")
  ds_json_updated <- set_metadata_version(ds_json_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  ds_json_updated <- set_originator(ds_json_updated, "Some Org")
  ds_json_updated <- set_source_system(ds_json_updated, "source system", "1.0")
  ds_json_updated <- set_study_oid(ds_json_updated, "SOMESTUDY")
  ds_json_updated <- set_item_oid(ds_json_updated, "Some Item Group")
  ds_json_updated <- set_dataset_name(ds_json_updated, "Some Dataset Name")
  ds_json_updated <- set_dataset_label(ds_json_updated, "Some Dataset Label")
  ds_json_updated <- set_last_modified(ds_json_updated, "Some Character Date")

  expect_equal(attr(ds_json_updated, "fileOID"), "/some/path")
  expect_equal(attr(ds_json_updated, "originator"), "Some Org")
  expect_equal(attr(ds_json_updated, "sourceSystem"), list(name = "source system", version = "1.0"))
  expect_equal(attr(ds_json_updated, "studyOID"), "SOMESTUDY")
  expect_equal(attr(ds_json_updated, "metaDataVersionOID"), "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  expect_equal(attr(ds_json_updated, "itemGroupOID"), "Some Item Group")
  expect_equal(attr(ds_json_updated, "name"), "Some Dataset Name")
  expect_equal(attr(ds_json_updated, "label"), "Some Dataset Label")
  expect_equal(attr(ds_json_updated, "dbLastModifiedDateTime"), "Some Character Date")

})

# Error checking
test_that("Errors are thrown properly", {
  expect_error(
    dataset_json(iris, version="2"),
    regexp = "Unsupported version specified"
  )
  expect_error(
    dataset_json(as.list(iris), version="1.1.0"),
    regexp = "must inherit from a data.frame"
  )
  expect_error(
    dataset_json(iris),
    regexp = "Issues found in columns data"
  )

  ds_json <- dataset_json(iris, columns = iris_items)

  expect_error(
    set_source_system(ds_json, 123, "1.0"),
    regexp = "`sys` must be a character"
  )
  expect_error(
    set_source_system(ds_json, "source system", 1.0),
    regexp = "`sys_version` must be a character"
  )
  expect_error(
    set_originator(ds_json, 123),
    regexp = "`originator` must be a character"
  )
  expect_error(
    set_file_oid(ds_json, 123),
    regexp = "`file_oid` must be a character"
  )
  expect_error(
    set_study_oid(ds_json, 123),
    regexp = "`study` must be a character"
  )
  expect_error(
    set_metadata_version(ds_json, 123),
    regexp = "`metadata_version` must be a character"
  )
  expect_error(
    set_metadata_ref(ds_json, 123),
    regexp = "`metadata_ref` must be a character"
  )
  expect_error(
    set_item_oid(ds_json, 123),
    regexp = "`item_oid` must be a character"
  )
  expect_error(
    set_dataset_name(ds_json, 123),
    regexp = "`name` must be a character"
  )
  expect_error(
    set_dataset_label(ds_json, 123),
    regexp = "`dataset_label` must be a character"
  )
  expect_error(
    set_last_modified(ds_json, 123),
    regexp = "`last_modified` must be a character"
  )



})
