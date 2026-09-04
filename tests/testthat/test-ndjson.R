
test_that("write_dataset_ndjson matches the reference ndjson files", {

  # dm
  df_name <- "dm"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/dm_metadata.Rds"))

  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-11-11/dm",
    last_modified = "2020-08-21T09:14:29",
    originator = "CDISC SDTM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "cdisc.com/CDISCPILOT01",
    metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    metadata_ref = "define.xml",
    item_oid = "IG.DM",
    name = "DM",
    dataset_label = "Demographics",
    columns = df_metadata
  )

  ndjson_location <- paste0(df_name, ".ndjson")
  withr::local_file(ndjson_location)
  write_dataset_ndjson(ds_json, ndjson_location)

  # Read back and compare with original JSON output
  comp <- read_dataset_ndjson(ndjson_location)
  expected <- read_dataset_json(test_path("testdata/dm.json"))
  expect_equal(as.data.frame(comp), as.data.frame(expected), ignore_attr = TRUE)

  # Check metadata matches
  comp_lines <- readLines(ndjson_location, warn = FALSE)
  expected_lines <- readLines(test_path("testdata/dm.ndjson"), warn = FALSE)
  comp_meta <- jsonlite::fromJSON(simplifyVector = FALSE, txt = comp_lines[1])
  expected_meta <- jsonlite::fromJSON(simplifyVector = FALSE, txt = expected_lines[1])
  comp_meta$datasetJSONCreationDateTime <- NULL
  expected_meta$datasetJSONCreationDateTime <- NULL
  expect_equal(comp_meta, expected_meta)

  # ta
  df_name <- "ta"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-11-11/ta",
    last_modified = "2020-08-21T09:14:26",
    originator = "CDISC SDTM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "cdisc.com/CDISCPILOT01",
    metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    metadata_ref = "define.xml",
    item_oid = "IG.TA",
    name = "TA",
    dataset_label = "Trial Arms",
    columns = df_metadata
  )

  ndjson_location <- paste0(df_name, ".ndjson")
  withr::local_file(ndjson_location)
  write_dataset_ndjson(ds_json, ndjson_location)

  # Read back and compare with original JSON output
  comp <- read_dataset_ndjson(ndjson_location)
  expected <- read_dataset_json(test_path("testdata/ta.json"))
  expect_equal(as.data.frame(comp), as.data.frame(expected), ignore_attr = TRUE)

  # Check metadata matches
  comp_lines <- readLines(ndjson_location, warn = FALSE)
  expected_lines <- readLines(test_path("testdata/ta.ndjson"), warn = FALSE)
  comp_meta <- jsonlite::fromJSON(simplifyVector = FALSE, txt = comp_lines[1])
  expected_meta <- jsonlite::fromJSON(simplifyVector = FALSE, txt = expected_lines[1])
  comp_meta$datasetJSONCreationDateTime <- NULL
  expected_meta$datasetJSONCreationDateTime <- NULL
  expect_equal(comp_meta, expected_meta)
})

test_that("read_dataset_ndjson matches xpt data", {

  # dm
  comp <- read_dataset_ndjson(test_path("testdata/dm.ndjson"))
  expected <- haven::read_xpt(test_path("testdata/dm.xpt"))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # ta
  comp <- read_dataset_ndjson(test_path("testdata/ta.ndjson"))
  expected <- haven::read_xpt(test_path("testdata/ta.xpt"))
  expect_equal(comp, expected, ignore_attr = TRUE)

  # ae
  comp <- read_dataset_ndjson(test_path("testdata/ae.ndjson"))
  expected <- haven::read_xpt(test_path("testdata/ae.xpt"))
  expect_equal(comp, expected, ignore_attr = TRUE)
})

test_that("read_dataset_ndjson matches read_dataset_json", {

  from_json <- read_dataset_json(test_path("testdata/dm.json"))
  from_ndjson <- read_dataset_ndjson(test_path("testdata/dm.ndjson"))

  # Data values should be identical
  expect_equal(as.data.frame(from_json), as.data.frame(from_ndjson),
               ignore_attr = TRUE)

  # Key metadata attributes should match
  expect_equal(attr(from_json, "fileOID"), attr(from_ndjson, "fileOID"))
  expect_equal(attr(from_json, "originator"), attr(from_ndjson, "originator"))
  expect_equal(attr(from_json, "studyOID"), attr(from_ndjson, "studyOID"))
  expect_equal(attr(from_json, "name"), attr(from_ndjson, "name"))
  expect_equal(attr(from_json, "label"), attr(from_ndjson, "label"))
  expect_equal(attr(from_json, "records"), attr(from_ndjson, "records"))
})

test_that("NDJSON round-trip produces equivalent data", {
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

  ndjson_str <- write_dataset_ndjson(ds_json)
  result <- read_dataset_ndjson(ndjson_str)

  # Species becomes character (factor -> string -> character), same as JSON path
  x <- iris[1:5, ]
  x[5] <- as.character(x[[5]])
  expect_equal(x, result, ignore_attr = TRUE)
})

test_that("NDJSON string output has correct structure", {
  ds_json <- dataset_json(
    iris[1:5, ],
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  result <- write_dataset_ndjson(ds_json)
  expect_true(is.character(result))

  lines <- strsplit(result, "\n")[[1]]
  # 1 metadata line + 5 data rows
  expect_equal(length(lines), 6)

  # Line 1 should be valid JSON object with metadata
  meta <- jsonlite::fromJSON(simplifyVector = FALSE, txt = lines[1])
  expect_true("columns" %in% names(meta))
  expect_true("name" %in% names(meta))
  expect_false("rows" %in% names(meta))

  # Lines 2-6 should be JSON arrays
  for (i in 2:6) {
    parsed <- jsonlite::fromJSON(simplifyVector = FALSE, txt = lines[i])
    expect_equal(length(parsed), 5)
  }
})

test_that("NDJSON can be written to and read from disk", {
  ds_json <- dataset_json(
    iris[1:5, ],
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  ndjson_location <- "test_output.ndjson"
  withr::local_file(ndjson_location)

  write_dataset_ndjson(ds_json, ndjson_location)
  expect_true(file.exists(ndjson_location))

  result <- read_dataset_ndjson(ndjson_location)
  x <- iris[1:5, ]
  x[5] <- as.character(x[[5]])
  expect_equal(x, result, ignore_attr = TRUE)
})

test_that("write_dataset_ndjson errors are thrown properly", {
  expect_error(
    write_dataset_ndjson(iris),
    "Input must be a datasetjson object"
  )

  ds_json <- dataset_json(
    iris[1:5, ],
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  expect_error(
    write_dataset_ndjson(ds_json, file = "not/a/valid/directory/test.ndjson"),
    "Folder supplied to `file` does not exist"
  )
})

test_that("read_dataset_ndjson warnings are thrown for record mismatch", {
  ds_json <- dataset_json(
    iris[1:5, ],
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  ndjson_str <- write_dataset_ndjson(ds_json)

  # Modify records count in metadata line
  ndjson_modified <- sub('"records":5', '"records":100', ndjson_str)

  expect_warning(
    read_dataset_ndjson(ndjson_modified),
    "The number of rows in the data does not match the number of records recorded in the metadata."
  )
})

test_that("float_as_decimal works with NDJSON", {
  test_df <- head(iris, 5)
  test_df['float_col'] <- c(
    143.66666666666699825,
    2/3,
    1/3,
    165/37,
    6/7
  )

  test_items <- iris_items |> dplyr::bind_rows(
    data.frame(
      itemOID = "IT.IR.float_col",
      name = "float_col",
      label = "Test column long decimal",
      dataType = "float"
    )
  )

  dsjson <- dataset_json(
    test_df,
    item_oid = "test_df",
    name = "test_df",
    dataset_label = "test_df",
    columns = test_items
  )

  ndjson_out1 <- write_dataset_ndjson(dsjson, float_as_decimals = FALSE)
  ndjson_out2 <- suppressWarnings(write_dataset_ndjson(dsjson, float_as_decimals = TRUE))

  out1 <- read_dataset_ndjson(ndjson_out1)
  out2 <- read_dataset_ndjson(ndjson_out2)

  # Numbers are parsed to double in C, so a plain read is exact too
  expect_equal(out1$float_col, test_df$float_col, ignore_attr = TRUE)

  # Should be rectified by manual decimal conversions
  expect_equal(out2$float_col, test_df$float_col, ignore_attr = TRUE)
})

test_that("validate_dataset_ndjson works correctly", {
  # Valid reference file
  expect_message(
    validate_dataset_ndjson(test_path("testdata/dm.ndjson")),
    "File is valid per the Dataset NDJSON v1.1.0 schema"
  )

  # Valid generated NDJSON
  ds_json <- dataset_json(
    iris[1:3, ],
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )
  ndjson_str <- write_dataset_ndjson(ds_json)
  expect_message(
    validate_dataset_ndjson(ndjson_str),
    "File is valid per the Dataset NDJSON v1.1.0 schema"
  )

  # A row with the wrong number of values is reported against its line
  lines <- strsplit(ndjson_str, "\n")[[1]]
  lines[3] <- "[1, 2]"
  expect_warning(
    validate_dataset_ndjson(paste(lines, collapse = "\n")),
    "File contains errors!"
  )
  errs <- suppressWarnings(validate_dataset_ndjson(paste(lines, collapse = "\n")))
  expect_equal(errs$line, 3L)
  expect_match(errs$message, "Expected 5 values, got 2")

  # A line that is not valid JSON at all
  lines[3] <- "[1, 2"
  errs <- suppressWarnings(validate_dataset_ndjson(paste(lines, collapse = "\n")))
  expect_equal(errs$message, "Invalid JSON")

  # Metadata line that does not meet the schema
  bad_meta <- c('{"datasetJSONVersion": "1.1.0"}', "[1, 2, 3, 4, 5]")
  expect_warning(
    validate_dataset_ndjson(paste(bad_meta, collapse = "\n")),
    "File contains errors!"
  )

  # Empty input
  expect_warning(validate_dataset_ndjson(""), "File contains errors!")
  errs <- suppressWarnings(validate_dataset_ndjson(""))
  expect_equal(errs$message, "File is empty")
})
