test_that("read_dataset_json matches xpt", {

  # adsl
  df_name <- "adsl"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # adsl attributes check
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  expect_equal(comp_attr[["names"]], comp_expected[["names"]])
  expect_equal(comp_attr[["row.names"]], comp_expected[["row.names"]])
  expect_equal(comp_attr[["label"]], comp_expected[["label"]])

  # ta
  df_name <- "ta"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # ta attributes check
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  expect_equal(comp_attr[["names"]], comp_expected[["names"]])
  expect_equal(comp_attr[["row.names"]], comp_expected[["row.names"]])
  expect_equal(comp_attr[["label"]], comp_expected[["label"]])

  # dm
  df_name <- "dm"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # dm attributes check
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  expect_equal(comp_attr[["names"]], comp_expected[["names"]])
  expect_equal(comp_attr[["row.names"]], comp_expected[["row.names"]])
  expect_equal(comp_attr[["label"]], comp_expected[["label"]])

  # # ae
  expect_error(read_dataset_json(test_path("testdata", "ae.json")), "Dataset JSON file is invalid")
  expect_warning(e <- validate_dataset_json(test_path("testdata", "ae.json")), "File contains errors!")

  # Simple crosscheck of the number of errors without verifying the whole dataframe
  expect_equal(nrow(e), 87)

})
