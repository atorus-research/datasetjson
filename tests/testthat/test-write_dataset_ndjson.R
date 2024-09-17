
test_that("write_dataset_ndjson matches the original ndjson", {

  # adsl
  df_name <- "adsl"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/adsl_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0/2024-08-01/adsl",
    last_modified = "2024-08-01T16:35:22",
    originator = "CDISC ADaM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "TDF_ADaM.ADaMIG.1.1",
    metadata_version = "MDV.TDF_ADaM.ADaMIG.1.1",
    metadata_ref = "define.xml",
    item_oid = "IG.ADSL",
    name = "ADSL",
    dataset_label = "Subject-Level Analysis Dataset"
  )

  # write json to disk
  ndjson_location <- paste0(df_name,".ndjson")
  withr::local_file(ndjson_location)
  write_dataset_ndjson(ds_json, ndjson_location, items=df_metadata)

  # compare metadata
  comp_metadata <- yyjsonr::read_ndjson_file(ndjson_location, nread = 1, nprobe = 1)
  expected_metadata <- yyjsonr::read_ndjson_file(test_path("testdata/adsl.ndjson"), nread = 1, nprobe = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_metadata, expected_metadata)

  # compare data
  comp_data <- yyjsonr::read_ndjson_file(ndjson_location, nskip = 1)
  expected_data <- yyjsonr::read_ndjson_file(test_path("testdata/adsl.ndjson"), nskip = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_data, expected_data)


  # dm
  df_name <- "dm"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/dm_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-08-01/dm",
    last_modified = "2020-08-21T09:14:29",
    originator = "CDISC SDTM MSG Team",
    sys = "SAS on X64_10PRO",
    sys_version = "9.0401M7",
    study = "cdisc.com/CDISCPILOT01",
    metadata_version = "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7",
    metadata_ref = "define.xml",
    item_oid = "IG.DM",
    name = "DM",
    dataset_label = "Demographics"
  )

  # write json to disk
  ndjson_location <- paste0(df_name,".ndjson")
  withr::local_file(ndjson_location)
  write_dataset_ndjson(ds_json, ndjson_location, items=df_metadata)

  # compare metadata
  comp_metadata <- yyjsonr::read_ndjson_file(ndjson_location, nread = 1, nprobe = 1)
  expected_metadata <- yyjsonr::read_ndjson_file(test_path("testdata/dm.ndjson"), nread = 1, nprobe = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_metadata, expected_metadata)

  # compare data
  comp_data <- yyjsonr::read_ndjson_file(ndjson_location, nskip = 1)
  expected_data <- yyjsonr::read_ndjson_file(test_path("testdata/dm.ndjson"), nskip = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_data, expected_data)

  # ta
  df_name <- "ta"
  orig_df <- haven::read_xpt(test_path(paste0("testdata/", df_name, ".xpt")))
  df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(
    orig_df,
    file_oid = "www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0/2024-08-01/ta",
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
    ref_data = TRUE
  )

  # write json to disk
  ndjson_location <- paste0(df_name,".ndjson")
  withr::local_file(ndjson_location)
  write_dataset_ndjson(ds_json, ndjson_location, items=df_metadata)

  # compare metadata
  comp_metadata <- yyjsonr::read_ndjson_file(ndjson_location, nread = 1, nprobe = 1)
  expected_metadata <- yyjsonr::read_ndjson_file(test_path("testdata/ta.ndjson"), nread = 1, nprobe = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_metadata, expected_metadata)

  # compare data
  comp_data <- yyjsonr::read_ndjson_file(ndjson_location, nskip = 1)
  expected_data <- yyjsonr::read_ndjson_file(test_path("testdata/ta.ndjson"), nskip = 1)

  # remove variables that will always differ
  comp_metadata$datasetJSONCreationDateTime <- NULL
  expected_metadata$datasetJSONCreationDateTime <- NULL

  expect_equal(comp_data, expected_data)
})

test_that("write_dataset_ndjson errors are thrown properly", {
  expect_error(
    write_dataset_ndjson(iris),
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
      ref_data = TRUE
    )
    write_dataset_ndjson(ds_json, items = df_metadata, file = "not/a/valid/directory/ta.json")},
    "Folder supplied to `file` does not exist"
  )
})
