test_that("read_dataset_json matches xpt", {

  # adsl ----
  df_name <- "adsl"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # adsl attributes check for those available in xpt
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  expect_equal(comp_attr[["row.names"]], comp_expected[["row.names"]])
  expect_equal(comp_attr[["label"]], comp_expected[["label"]])
  expect_equal(comp_attr[["names"]], comp_expected[["names"]])


  # ta ----
  df_name <- "ta"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # ta attributes check for those available in xpt
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  expect_equal(comp_attr[["row.names"]], comp_expected[["row.names"]])
  expect_equal(comp_attr[["label"]], comp_expected[["label"]])
  expect_equal(comp_attr[["names"]], comp_expected[["names"]])

  # dm ----
  df_name <- "dm"
  comp <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  expected <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # dm attributes check for those available in xpt
  comp_attr <- attributes(comp)
  comp_expected <- attributes(expected)

  # invalid json ----
  expect_warning(e <- validate_dataset_json(test_path("testdata", "invalid_dm.json")), "File contains errors!")

  # Simple crosscheck of the number of errors without verifying the whole dataframe
  expect_equal(nrow(e), 1)

})

test_that("Dataset JSON can be read from a URL", {
  file_path <- test_path("testdata", "ta.json")
  url_file_path <- paste0("file://", normalizePath(test_path("testdata", "ta.json")))

  from_disk <- read_dataset_json(file_path)
  from_url <- read_dataset_json(url_file_path)

  expect_equal(from_disk, from_url)
})

test_that("Dataset JSON can be read from imported string", {
  ds_json <- dataset_json(
    iris[1:5, ],
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
  js <- write_dataset_json(ds_json, pretty=TRUE)
  expect_silent(dat <- read_dataset_json(js))
  x <- iris
  x[5] <- as.character(x[[5]])
  expect_equal(x[1:5, ], dat, ignore_attr=TRUE)
})

test_that("datetime conversions work properly",{
  iris_timetest <- read_dataset_json(test_path("testdata", "iris_timetest.json"))

  expect_s3_class(iris_timetest$Datetime, "POSIXct")
  expect_equal(class(iris_timetest$Time), c("hms", "difftime"), ignore_attr=TRUE)

  expect_equal(sort(unique(iris_timetest$Datetime)),
               as.POSIXct(strptime(c("2024-01-01T12:34:56", "2024-01-17T18:45:56"),
                        "%Y-%m-%dT%H:%M:%S", tz="UTC")))
  expect_equal(sort(unique(as.numeric(iris_timetest$Time))),
               as.numeric(as_hms(c("12:34:56", "18:45:56"))))
})

test_that("read_dataset_json warnings are thrown properly", {
  ds_json <- dataset_json(
    iris[1:5, ],
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
  js <- write_dataset_json(ds_json, pretty=TRUE)

  # modify records attribute so it doesn't match the number of rows in the data
  js_record_update <- gsub("\"records\": 5", "\"records\": 100", js)

  expect_warning(read_dataset_json(js_record_update),
                 "The number of rows in the data does not match the number of records recorded in the metadata.")
})

