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
  expect_warning(e <- validate_dataset_json(test_path("testdata", "ae.json")), "File contains errors!")

  # Simple crosscheck of the number of errors without verifying the whole dataframe
  expect_equal(nrow(e), 87)

})

test_that("Dataset JSON can be read from a URL", {
  file_path <- test_path("testdata", "ta.json")
  url_file_path <- paste0("file://", normalizePath(test_path("testdata", "ta.json")))

  from_disk <- read_dataset_json(file_path)
  from_url <- read_dataset_json(url_file_path)

  expect_equal(from_disk, from_url)
})

test_that("Dataset JSON can be read from imported string", {
  ds_json <- dataset_json(iris[1:5, ], "IG.IRIS", "IRIS", "Iris", iris_items)
  js <- write_dataset_json(ds_json, pretty=TRUE)
  expect_silent(dat <- read_dataset_json(js))
  x <- iris
  x[5] <- as.character(x[[5]])
  expect_equal(x[1:5, ], dat, ignore_attr=TRUE)
})
