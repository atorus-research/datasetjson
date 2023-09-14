test_that("validate_dataset_json returns correct messages", {

  ds_json <- dataset_json(iris, "IG.IRIS", "IRIS", "Iris", iris_items)
  js <- write_dataset_json(ds_json)

  expect_message(validate_dataset_json(js), "File is valid per the Dataset JSON v1.0.0 schema")

})
