test_that("validate_dataset_json returns correct messages", {

    ds_json <- dataset_json(
      iris,
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
  js <- write_dataset_json(ds_json)

  expect_message(validate_dataset_json(js), "File is valid per the Dataset JSON v1.1.0 schema")

})

test_that("JSON can checked from URL", {
  fpath <- paste0("file://", normalizePath(test_path("testdata", "invalid_dm.json")))
  expect_warning(
    err <- validate_dataset_json(fpath),
    "File contains errors!"
  )

  # Loose check of number of issues
  expect_equal(dim(err), c(1, 9))
})
