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

  # the content is byte-for-byte what write_dataset_ndjson() puts in a file.
  # R's type = "gzip" covers both RFC 1952 (gzip, 0x1F 0x8B) and RFC 1950
  # (zLib, 0x78 0xDA); DSJC is the latter, so this inflates it correctly
  # despite the argument's name.
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

  # inflate() returns Z_DATA_ERROR: the stream is structurally broken
  damaged <- write_dataset_dsjc(ds)
  damaged[50:60] <- as.raw(0)
  expect_error(read_dataset_dsjc(damaged),
               "Could not read Dataset JSON Compressed content")

  # inflate() returns Z_OK with no input left and no Z_STREAM_END: the stream is
  # well formed as far as it goes but stops early. Any prefix of a valid deflate
  # stream is a valid partial stream, so both a heavy truncation and the loss of
  # just the trailing checksum land here rather than on the error above.
  full <- write_dataset_dsjc(ds)
  expect_error(read_dataset_dsjc(full[seq_len(40)]),
               "ended before it was complete")
  expect_error(read_dataset_dsjc(full[seq_len(length(full) - 4L)]),
               "ended before it was complete")
  expect_error(read_dataset_dsjc(full[seq_len(length(full) - 1L)]),
               "ended before it was complete")

  expect_error(read_dataset_dsjc("no/such/file.dsjc"), "must be a path")
})

test_that("float_as_decimals works through the compressed path", {
  # prepare_dataset_for_write() is shared, but write_dataset_dsjc() passes
  # as_decimal to its own C entry point, so the flag needs covering here too
  ds <- make_ds(head(iris, 5))

  expect_warning(write_dataset_dsjc(ds, float_as_decimals = TRUE),
                 "no longer needed to protect against")
  bytes <- suppressWarnings(write_dataset_dsjc(ds, float_as_decimals = TRUE))

  # the numbers really are quoted inside the compressed content, and the column
  # metadata really did flip to decimal/decimal
  content <- rawToChar(memDecompress(bytes, type = "gzip"))
  expect_true(grepl('"dataType":"decimal","targetDataType":"decimal"', content,
                    fixed = TRUE))
  expect_true(grepl('["5.1","3.5"', content, fixed = TRUE))

  # and it reads back to the same data as the plain compressed path
  expect_equal(as.data.frame(read_dataset_dsjc(bytes)),
               as.data.frame(read_dataset_dsjc(write_dataset_dsjc(ds))),
               ignore_attr = TRUE)

  # values survive the decimal encoding through compression bit-exactly
  v <- c(143.66666666666699825, 2 / 3, 1 / 3)
  d <- data.frame(SUBJ = c("a", "b", "c"), V = v, stringsAsFactors = FALSE)
  items <- data.frame(
    itemOID = c("IT.SUBJ", "IT.V"), name = c("SUBJ", "V"),
    label = c("Subject", "Value"), dataType = c("string", "float"),
    stringsAsFactors = FALSE
  )
  dsv <- dataset_json(d, item_oid = "t", name = "t", dataset_label = "t",
                      columns = items)
  back <- read_dataset_dsjc(
    suppressWarnings(write_dataset_dsjc(dsv, float_as_decimals = TRUE)))
  expect_identical(as.double(back$V), v)
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

test_that("the three shipped example files agree with each other", {
  # dm.ndjson and dm.dsjc are generated from dm.json in data-raw, so all three
  # must read back to the same dataset
  reads <- list(
    json   = read_dataset_json(datasetjson_example("dm.json")),
    ndjson = read_dataset_ndjson(datasetjson_example("dm.ndjson")),
    dsjc   = read_dataset_dsjc(datasetjson_example("dm.dsjc"))
  )

  for (nm in c("ndjson", "dsjc")) {
    expect_equal(as.data.frame(reads[[nm]]), as.data.frame(reads$json),
                 ignore_attr = "datasetJSONCreationDateTime", info = nm)
    a <- attributes(reads$json)
    b <- attributes(reads[[nm]])
    a$datasetJSONCreationDateTime <- b$datasetJSONCreationDateTime <- NULL
    expect_equal(b, a, info = nm)
  }

  expect_message(validate_dataset_ndjson(datasetjson_example("dm.ndjson")),
                 "File is valid")
  expect_message(validate_dataset_dsjc(datasetjson_example("dm.dsjc")),
                 "File is valid")

  # the compressed form is meaningfully smaller than either uncompressed one
  expect_lt(file.size(datasetjson_example("dm.dsjc")),
            file.size(datasetjson_example("dm.json")) / 2)
  expect_lt(file.size(datasetjson_example("dm.dsjc")),
            file.size(datasetjson_example("dm.ndjson")) / 2)

  # and dm.dsjc really is dm.ndjson compressed. Each file carries the moment it
  # was written, so that one field is normalised before comparing.
  blank_created <- function(x) {
    sub('"datasetJSONCreationDateTime":"[^"]*"',
        '"datasetJSONCreationDateTime":"X"', x)
  }
  dsjc_path <- datasetjson_example("dm.dsjc")
  inflated <- rawToChar(memDecompress(
    readBin(dsjc_path, "raw", file.size(dsjc_path)), type = "gzip"))
  ndjson_text <- paste0(
    paste(readLines(datasetjson_example("dm.ndjson"), warn = FALSE),
          collapse = "\n"),
    "\n")

  expect_identical(blank_created(inflated), blank_created(ndjson_text))
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
