test_df <- data.frame(
  d1 = as.Date(c(19906:19916)) + (365 * 10),
  d2 = as.Date(c(19916:19926)) + (365 * 10),
  dt1 = as.POSIXct(((19906:19916)  + (365 * 10)) * 24 * 60 * 60 + (2 * 60 * 60) + (45 * 60) + 20),
  dt2 = as.POSIXct(((19916:19926)  + (365 * 10)) * 24 * 60 * 60 + (2 * 60 * 60) + (45 * 60) + 20)
)

check_df <- test_df
check_df[1:2] <- check_df[1:2] + (365 * 10 + 3)
check_df[3:4] <- check_df[3:4] + ((365 * 10 + 3) * 24 * 60 * 60)

test_that("Check that columns convert as expected", {
  x <- test_df
  x <- convert_to_sas_datenum(x)
  x <- convert_to_sas_datetimenum(x)
  x[1:2] <- lapply(x[1:2], as.Date)
  x[3:4] <- lapply(x[3:4], as.POSIXct)

  expect_equal(x, check_df, ignore_attr=TRUE)
})
