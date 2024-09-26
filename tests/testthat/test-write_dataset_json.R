
test_that("write_dataset_json matches the original json", {

  # adsl
  df_name <- "adsl"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/adsl_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0/2024-08-05/adsl",
    last_modified = "2024-08-05T10:08:46",
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
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-08-05/dm",
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
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-08-05/ta",
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
    ref_data = TRUE,
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
      file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-08-05/ta",
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
      ref_data = TRUE,
      columns = df_metadata
    )
    write_dataset_json(ds_json, file = "not/a/valid/directory/ta.json")},
    "Folder supplied to `file` does not exist"
  )
})
