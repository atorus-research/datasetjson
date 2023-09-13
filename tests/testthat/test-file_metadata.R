test_that("Default file_metadata object produces correctly", {
  file_meta <- file_metadata()

  expect_equal(file_meta$datasetJSONVersion, "1.0.0")
  expect_equal(file_meta$fileOID, character())
  expect_equal(file_meta$asOfDateTime, character())
  expect_equal(file_meta$originator, "NA")
  expect_equal(file_meta$sourceSystem, "NA")
  expect_equal(file_meta$sourceSystemVersion, "NA")
})

test_that("Parameters pass through on file_metadata call", {
  file_meta <- file_metadata(
    originator = "Some Org",
    sys = "source system",
    sys_version = "1.0"
  )

  expect_equal(file_meta$originator, "Some Org")
  expect_equal(file_meta$sourceSystem, "source system")
  expect_equal(file_meta$sourceSystemVersion, "1.0")
})

test_that("get_datetime() produces properly formatted datetime", {
  expect_equal(grep("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", get_datetime()), 1)
})

test_that("Setters work on file_metadata objects", {

  file_meta <- file_metadata()

  file_meta_updated <- set_file_oid(file_meta, "/some/path")
  file_meta_updated <- set_originator(file_meta_updated, "Some Org")
  file_meta_updated <- set_source_system(file_meta_updated, "source system", "1.0")

  expect_equal(file_meta_updated$fileOID, "/some/path")
  expect_equal(file_meta_updated$originator, "Some Org")
  expect_equal(file_meta_updated$sourceSystem, "source system")
  expect_equal(file_meta_updated$sourceSystemVersion, "1.0")
})

# Error checking
test_that("Errors are thrown properly", {
  expect_error(
    file_metadata(version = "2.0.0"),
    "Unsupported version specified - currently only version 1.0.0 is supported"
  )
})
