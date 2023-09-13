test_that("Type checker functions throw proper errors", {
  expect_error(set_data_type(1), "Input must be a datasetjson object")

  expect_error(set_source_system(1, "sys", "ver"), "Input must be a datasetjson object or file_metadata object")
  expect_error(set_originator(1, "orig"), "Input must be a datasetjson object or file_metadata object")
  expect_error(set_file_oid(1, "path"), "Input must be a datasetjson object or file_metadata object")

  expect_error(set_study_oid(1, "study"), "Input must be a datasetjson or data_metadata object")
  expect_error(set_metadata_version(1, "study"), "Input must be a datasetjson or data_metadata object")
  expect_error(set_metadata_ref(1, "ref"), "Input must be a datasetjson or data_metadata object")

  expect_error(set_item_data(1, iris), "Input must be a datasetjson or dataset_metadata object")
})
