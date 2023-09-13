test_that("Type checker functions throw proper errors", {
  expect_error(stopifnot_datasetjson(1), "Input must be a datasetjson object")
  expect_error(stopifnot_dataset_metadata(1), "Input must be a dataset_metadata object")
  expect_error(stopifnot_data_metadata(1), "Input must be a data_metadata object")
  expect_error(stopifnot_file_metadata(1), "Input must be a datasetjson object or file_metadata object")
})
