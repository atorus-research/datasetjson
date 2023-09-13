set_test_adam_metadata <- function(ds_json){
  ds_json <- set_originator(ds_json, "CDISC ADaM MSG Team")
  ds_json <- set_source_system(ds_json, "Sponsor System", "1.0")
  ds_json <- set_metadata_ref(ds_json, "https://metadata.location.org/TDF_ADaM_ADaMIG11/define.xml")
  ds_json <- set_metadata_version(ds_json, "MDV.TDF_ADaM.ADaMIG.1.1")
  ds_json <- set_study_oid(ds_json, "TDF_ADaM.ADaMIG.1.1")
  ds_json
}
set_test_sdtm_metadata <- function(ds_json){
  ds_json <- set_originator(ds_json, "CDISC SDTM MSG Team")
  ds_json <- set_source_system(ds_json, "Sponsor System", "1.0")
  ds_json <- set_metadata_ref(ds_json, "https://metadata.location.org/CDISCPILOT01/define.xml")
  ds_json <- set_metadata_version(ds_json, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  ds_json <- set_study_oid(ds_json, "cdisc.com/CDISCPILOT01")
  ds_json
}

test_that("write_dataset_json matches the original json", {

  # adsl
  df_name <- "adsl"
  df_from_json <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  df_metadata <- readRDS(test_path("testdata/adsl_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(df_from_json, "IG.ADSL", "ADSL", "Subject-Level Analysis Dataset", df_metadata)
  ds_json <- set_test_adam_metadata(ds_json)

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/adsl.json"))

  # remove fileOID and creationDateTime, this will alway differ
  # remove asOfDateTime, this is not in adsl.json (to confirm if extensible)
  comp$fileOID <- NULL
  expected$fileOID <- NULL
  comp$asOfDateTime <- NULL
  comp$creationDateTime <- NULL
  expected$creationDateTime <- NULL

  expect_equal(comp, expected)


  # dm
  df_name <- "dm"
  df_from_json <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  df_metadata <- readRDS(test_path("testdata/dm_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(df_from_json, "IG.DM", "DM", "Demographics", df_metadata)
  ds_json <- set_test_sdtm_metadata(ds_json)

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/dm.json"))

  # remove fileOID and creationDateTime, this will alway differ
  # remove asOfDateTime, this is not in adsl.json (to confirm if extensible)
  comp$fileOID <- NULL
  expected$fileOID <- NULL
  comp$asOfDateTime <- NULL
  expected$asOfDateTime <- NULL
  comp$creationDateTime <- NULL
  expected$creationDateTime <- NULL

  expect_equal(comp, expected)

  # ta
  df_name <- "ta"
  df_from_json <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
  df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

  # create dataset json object
  ds_json <- dataset_json(df_from_json, "IG.TA", "TA", "Trial Arms", df_metadata, data_type="referenceData")
  ds_json <- set_test_sdtm_metadata(ds_json)

  # write json to disk
  json_location <- paste0(df_name,".json")
  withr::local_file(json_location)
  write_dataset_json(ds_json, json_location)

  comp <- jsonlite::read_json(json_location)
  expected <- jsonlite::read_json(test_path("testdata/ta.json"))

  # remove fileOID and creationDateTime, this will alway differ
  # remove asOfDateTime, this is not in adsl.json (to confirm if extensible)
  comp$fileOID <- NULL
  expected$fileOID <- NULL
  comp$asOfDateTime <- NULL
  expected$asOfDateTime <- NULL
  comp$creationDateTime <- NULL
  expected$creationDateTime <- NULL

  expect_equal(comp, expected)

  # Error check
  ds_json$creationDateTime <- 1
  expect_error(write_dataset_json(ds_json, json_location), "Dataset JSON file is invalid")
})

test_that("write_dataset_json errors are thrown properly", {
  expect_error(
    write_dataset_json(iris),
    "Input must be a datasetjson object"
    )

  expect_error({
    df_name <- "ta"
    df_from_json <- read_dataset_json(test_path(paste0("testdata/", df_name, ".json")))
    df_metadata <- readRDS(test_path("testdata/ta_metadata.Rds"))

    # create dataset json object
    ds_json <- dataset_json(df_from_json, "IG.TA", "TA", "Trial Arms", df_metadata, data_type="referenceData")
    ds_json <- set_test_sdtm_metadata(ds_json)
    write_dataset_json(ds_json, file = "not/a/valid/directory/ta.json")},
    "Folder supplied to `file` does not exist"
  )
})
