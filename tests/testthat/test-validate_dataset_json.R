test_that("validate_dataset_json returns correct messages", {

  ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
  js <- write_dataset_json(ds_json)

  expect_message(validate_dataset_json(js), "File is valid per the Dataset JSON v1.0.0 schema")

})

test_that("JSON can checked from URL", {
  fpath <- paste0("file://", normalizePath(test_path("testdata", "ae.json")))
  expect_warning(
    err <- validate_dataset_json(fpath),
    "File contains errors!"
  )

  # Loose check of number of issues
  expect_equal(dim(err), c(87, 9))
})
