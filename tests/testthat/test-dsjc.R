# DSJC is a zLib stream of Dataset NDJSON content and nothing else, so the tests
# check both halves: that the compression is standard and readable by any zLib
# implementation, and that the content inside is exactly what the NDJSON writer
# would have produced.

make_ds <- function(d = iris, items = iris_items) {
  dataset_json(d, item_oid = "IG.IRIS", name = "IRIS", dataset_label = "Iris",
               columns = items)
}

test_that("DSJC is a plain zLib stream of the NDJSON content", {
  ds <- make_ds()
  bytes <- write_dataset_dsjc(ds)

  expect_type(bytes, "raw")

  # zLib (RFC 1950) header, level 9
  expect_identical(as.integer(bytes[1:2]), c(120L, 218L))

  # the content is byte-for-byte what write_dataset_ndjson() puts in a file
  f <- withr::local_tempfile(fileext = ".ndjson")
  write_dataset_ndjson(ds, f)
  expect_identical(
    memDecompress(bytes, type = "gzip"),
    readBin(f, "raw", file.size(f))
  )
})

test_that("DSJC round-trips through a file and through raw bytes", {
  ds <- make_ds()
  from_ndjson <- read_dataset_ndjson(write_dataset_ndjson(ds))

  f <- withr::local_tempfile(fileext = ".dsjc")
  expect_null(write_dataset_dsjc(ds, f))
  expect_true(file.exists(f))
  expect_equal(read_dataset_dsjc(f), from_ndjson)

  expect_equal(read_dataset_dsjc(write_dataset_dsjc(ds)), from_ndjson)
})

test_that("every compression level produces a readable stream", {
  ds <- make_ds(head(iris, 20))
  f <- withr::local_tempfile(fileext = ".ndjson")
  write_dataset_ndjson(ds, f)
  nd <- readBin(f, "raw", file.size(f))

  sizes <- integer()
  for (lvl in c(0L, 1L, 6L, 9L)) {
    b <- write_dataset_dsjc(ds, level = lvl)
    expect_identical(memDecompress(b, type = "gzip"), nd, info = lvl)
    expect_equal(read_dataset_dsjc(b), read_dataset_dsjc(write_dataset_dsjc(ds)),
                 info = lvl)
    sizes <- c(sizes, length(b))
  }
  # level 0 stores, higher levels compress
  expect_gt(sizes[1], sizes[2])

  expect_error(write_dataset_dsjc(ds, level = 10), "between 0 and 9")
  expect_error(write_dataset_dsjc(ds, level = -1), "between 0 and 9")
  expect_error(write_dataset_dsjc(ds, level = NA), "between 0 and 9")
})

test_that("a stream compressed by another tool reads correctly", {
  ds <- make_ds(head(iris, 20))
  f <- withr::local_tempfile(fileext = ".ndjson")
  write_dataset_ndjson(ds, f)

  # compressed by R's zlib, not ours
  theirs <- memCompress(readBin(f, "raw", file.size(f)), type = "gzip")
  expect_equal(read_dataset_dsjc(theirs), read_dataset_ndjson(f))
})

test_that("corrupt compressed input is reported, not crashed on", {
  ds <- make_ds(head(iris, 20))

  damaged <- write_dataset_dsjc(ds)
  damaged[50:60] <- as.raw(0)
  expect_error(read_dataset_dsjc(damaged),
               "Could not read Dataset JSON Compressed content")

  truncated <- write_dataset_dsjc(ds)[1:40]
  expect_error(read_dataset_dsjc(truncated),
               "ended before it was complete")

  expect_error(read_dataset_dsjc("no/such/file.dsjc"), "must be a path")
})

test_that("DSJC content validates as Dataset NDJSON", {
  ds <- make_ds()
  expect_message(
    validate_dataset_dsjc(write_dataset_dsjc(ds)),
    "File is valid per the Dataset NDJSON v1.1.0 schema"
  )

  f <- withr::local_tempfile(fileext = ".dsjc")
  write_dataset_dsjc(ds, f)
  expect_message(validate_dataset_dsjc(f), "File is valid")

  expect_warning(
    validate_dataset_dsjc(as.raw(c(1, 2, 3, 4))),
    "File contains errors!"
  )
})

test_that("numbers survive the compressed path bit-exactly", {
  set.seed(42)
  n <- 200
  v <- 10^runif(n, -12, 12) * sample(c(-1, 1), n, TRUE) * runif(n, 1, 10)
  d <- data.frame(SUBJ = sprintf("S%03d", seq_len(n)), V = v,
                  stringsAsFactors = FALSE)
  items <- data.frame(
    itemOID = c("IT.SUBJ", "IT.V"), name = c("SUBJ", "V"),
    label = c("Subject", "Value"), dataType = c("string", "float"),
    stringsAsFactors = FALSE
  )
  ds <- dataset_json(d, item_oid = "t", name = "t", dataset_label = "t",
                     columns = items)

  expect_identical(as.double(read_dataset_dsjc(write_dataset_dsjc(ds))$V), v)
})

test_that("the shipped example file reads back as the JSON it came from", {
  from_json <- read_dataset_json(datasetjson_example("dm.json"))
  from_dsjc <- read_dataset_dsjc(datasetjson_example("dm.dsjc"))

  expect_equal(as.data.frame(from_json), as.data.frame(from_dsjc),
               ignore_attr = "datasetJSONCreationDateTime")

  a <- attributes(from_json)
  b <- attributes(from_dsjc)
  a$datasetJSONCreationDateTime <- b$datasetJSONCreationDateTime <- NULL
  expect_equal(a, b)

  expect_message(validate_dataset_dsjc(datasetjson_example("dm.dsjc")),
                 "File is valid")

  # it is meaningfully smaller than the JSON it came from
  expect_lt(file.size(datasetjson_example("dm.dsjc")),
            file.size(datasetjson_example("dm.json")) / 2)
})

test_that("DSJC can be read from a URL", {
  ds <- make_ds(head(iris, 25))
  f <- withr::local_tempfile(fileext = ".dsjc")
  write_dataset_dsjc(ds, f)

  # file:// exercises the same binary path as http(s) without needing a network
  u <- paste0("file://", f)
  expect_true(path_is_url(u))

  expect_equal(read_dataset_dsjc(u), read_dataset_dsjc(f))
  expect_message(validate_dataset_dsjc(u), "File is valid")

  # the bytes must come through untouched - readLines() would corrupt them
  expect_identical(read_raw_from_url(u), readBin(f, "raw", file.size(f)))
})
