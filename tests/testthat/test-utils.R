test_that("Type checker functions throw proper errors", {
  expect_error(set_source_system(1, "sys", "ver"), "Input must be a datasetjson object")
  expect_error(set_originator(1, "orig"), "Input must be a datasetjson object")
  expect_error(set_file_oid(1, "path"), "Input must be a datasetjson object")

  expect_error(set_study_oid(1, "study"), "Input must be a datasetjson")
  expect_error(set_metadata_version(1, "study"), "Input must be a datasetjson")
  expect_error(set_metadata_ref(1, "ref"), "Input must be a datasetjson")
})


test_that("URL checker regex works as expected", {
  url_list <- c(
    "https://github.com/cdisc-org/DataExchange-DatasetJson/raw/master/examples/sdtm/ti.json", # true
    "http://github.com/cdisc-org/DataExchange-DatasetJson/raw/master/examples/sdtm/ti.json",  # true
    test_path("testdata", "ta.json"),                                                         # false
    normalizePath(test_path("testdata", "ta.json")),                                          # false
    paste0("file://", normalizePath(test_path("testdata", "ta.json"))),                       # true
    paste0("ftp://", normalizePath(test_path("testdata", "ta.json"))),                        # true
    paste0("ftps://", normalizePath(test_path("testdata", "ta.json"))),                       # true
    paste0("sftp://", normalizePath(test_path("testdata", "ta.json")))                        # true
  )

  bool_check <- c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE)

  expect_equal(path_is_url(url_list), bool_check)
})
