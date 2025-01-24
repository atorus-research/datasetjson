
test_that("write_dataset_json matches the original json", {

  # adsl
  df_name <- "adsl"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/adsl_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0/2024-11-11/adsl",
    last_modified = "2022-04-16T20:09:03",
    originator = "CDISC ADaM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "TDF_ADaM.ADaMIG.1.1",
    metadata_version = "MDV.TDF_ADaM.ADaMIG.1.1",
    metadata_ref = "define.xml",
    item_oid = "IG.ADSL",
    name = "ADSL",
    dataset_label = "Subject-Level Analysis Dataset",
    columns = df_metadata
  )

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/adsl.json"))

  # remove datasetJSONCreationDateTime, this will always differ
  comp$datasetJSONCreationDateTime <- NULL
  expected$datasetJSONCreationDateTime <- NULL

  expect_equal(comp, expected)


  # dm
  df_name <- "dm"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/dm_metadata.Rds"))

  # create dataset json object
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

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/dm.json"))


  # remove datasetJSONCreationDateTime, this will always differ
  comp$datasetJSONCreationDateTime <- NULL
  expected$datasetJSONCreationDateTime <- NULL

  expect_equal(comp, expected)

  # ta
  df_name <- "ta"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

  # create dataset json object
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

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/ta.json"))

  # remove datasetJSONCreationDateTime, this will always differ
  comp$datasetJSONCreationDateTime <- NULL
  expected$datasetJSONCreationDateTime <- NULL

  expect_equal(comp, expected)
})

test_that("write_dataset_json errors are thrown properly", {
  expect_error(
    write_dataset_json(iris),
    "Input must be a datasetjson object"
    )

  expect_error({
    df_name <- "ta"
    orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
    df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

    # create dataset json object

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
    write_dataset_json(ds_json, file = "not/a/valid/directory/ta.json")},
    "Folder supplied to `file` does not exist"
  )
})

test_that("datetime and times write out properly", {
  df_name <- "adsl"
  orig_df <- readRDS(testthat::test_path("testdata", "adsl_time_test.Rds"))
  df_metadata <- readRDS(testthat::test_path("testdata", "adsl_time_test_meta.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0/2024-11-11/adsl",
    last_modified = "2022-04-16T20:09:03",
    originator = "CDISC ADaM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "TDF_ADaM.ADaMIG.1.1",
    metadata_version = "MDV.TDF_ADaM.ADaMIG.1.1",
    metadata_ref = "define.xml",
    item_oid = "IG.ADSL",
    name = "ADSL",
    dataset_label = "Subject-Level Analysis Dataset",
    columns = df_metadata
  )

  # Write JSON
  adsl_json_output <- write_dataset_json(ds_json)
  adsl_json_input <- read_dataset_json(adsl_json_output)

  # The ignore_attr option isn't working here.
  # Period objects (i.e. times)
  x <- orig_df$VISIT1TM
  y <- adsl_json_input$VISIT1TM
  attr(y, 'label') <- NULL
  expect_equal(x, y)

  # Datetimes
  x <- orig_df$VIST1DTM
  y <- adsl_json_input$VIST1DTM
  attr(y, 'label') <- NULL
  expect_equal(x, y)

  # Dates
  x <- orig_df$VISIT1DT
  y <- adsl_json_input$VISIT1DT
  attr(x, 'format.sas') <- NULL
  expect_equal(x, y)

  # Check that times in supported data types convert propery
  ds_json$VISIT1TM <- hms::as_hms(as.numeric(ds_json$VISIT1TM))

  # Write JSON
  adsl_json_output <- write_dataset_json(ds_json)
  adsl_json_input <- read_dataset_json(adsl_json_output)
  expect_equal(as.numeric(orig_df$VISIT1TM), as.numeric(adsl_json_input$VISIT1TM))

  # Check that times in supported data types convert propery
  ds_json$VISIT1TM <- data.table::as.ITime(as.numeric(ds_json$VISIT1TM))

  # Write JSON
  adsl_json_output <- write_dataset_json(ds_json)
  adsl_json_input <- read_dataset_json(adsl_json_output)
  expect_equal(as.numeric(orig_df$VISIT1TM), as.numeric(adsl_json_input$VISIT1TM))

})



make_ds_json <- function(dat, meta) {
  dataset_json(
    dat,
    file_oid = "www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0/2024-11-11/adsl",
    last_modified = "2022-04-16T20:09:03",
    originator = "CDISC ADaM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "TDF_ADaM.ADaMIG.1.1",
    metadata_version = "MDV.TDF_ADaM.ADaMIG.1.1",
    metadata_ref = "define.xml",
    item_oid = "IG.ADSL",
    name = "ADSL",
    dataset_label = "Subject-Level Analysis Dataset",
    columns = meta
  )
}

test_that("Writing errors trigger", {
  orig_df <- readRDS(testthat::test_path("testdata", "adsl_time_test.Rds"))
  df_metadata <- readRDS(testthat::test_path("testdata", "adsl_time_test_meta.Rds"))

  # fails for POSIXct
  orig_df2 <- orig_df
  orig_df2$VIST1DTM <- as.numeric(orig_df2$VIST1DTM)

  # create dataset json object
  ds_json <- make_ds_json(orig_df2, df_metadata)
  expect_error(write_dataset_json(ds_json), "Date time variable")

  orig_df3 <- orig_df
  orig_df3$VISIT1TM <- as.numeric(orig_df3$VISIT1TM)
  ds_json2 <- make_ds_json(orig_df3, df_metadata)
  expect_error(write_dataset_json(ds_json2), "If dataType is time")

  # Fudge metadata
  df_metadata2 <- df_metadata
  df_metadata2$targetDataType <- NA_character_

  ds_json3 <- make_ds_json(orig_df, df_metadata2)

  expect_error(write_dataset_json(ds_json3), "If dataType is date")

})
