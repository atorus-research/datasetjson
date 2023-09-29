data_meta <- data_metadata()

test_that("Default data_metadata object produces correctly", {
  expect_null(data_meta$studyOID)
  expect_null(data_meta$metaDataVersionOID)
  expect_null(data_meta$metaDataRef)
})

test_that("data_metadata setters work properly", {
  data_meta_updated <- set_metadata_ref(data_meta, "some/define.xml")
  data_meta_updated <- set_metadata_version(data_meta_updated, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  data_meta_updated <- set_study_oid(data_meta_updated, "SOMESTUDY")

  expect_equal(data_meta_updated$studyOID, "SOMESTUDY")
  expect_equal(data_meta_updated$metaDataVersionOID, "MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7")
  expect_equal(data_meta_updated$metaDataRef, "some/define.xml")
})
