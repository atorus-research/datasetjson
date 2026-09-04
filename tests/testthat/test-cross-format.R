# The JSON and NDJSON representations of a dataset carry identical content; only
# the framing differs. So reading either one must produce the same object -
# values, types and metadata attributes alike - and writing must be
# deterministic enough that both entry points converge on the same bytes.

# The creation timestamp is regenerated on every write, so it is the one field
# that can never match. Everything else must.
blank_created <- function(x) {
  sub('"datasetJSONCreationDateTime":"[^"]*"',
      '"datasetJSONCreationDateTime":"X"', x)
}

parse_json <- function(txt) {
  x <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
  x$datasetJSONCreationDateTime <- NULL
  x
}

parse_ndjson <- function(txt) {
  lines <- strsplit(txt, "\n")[[1]]
  lines <- lines[nzchar(trimws(lines))]
  meta <- jsonlite::fromJSON(lines[1], simplifyVector = FALSE)
  meta$datasetJSONCreationDateTime <- NULL
  list(meta = meta,
       rows = lapply(lines[-1], jsonlite::fromJSON, simplifyVector = FALSE))
}

# adsl is excluded from the cross-reference comparisons; see the final test,
# which pins down exactly why.
converging <- c("dm", "ta", "ae")

test_that("reading either format yields byte-identical output in both formats", {
  for (nm in converging) {
    from_json <- read_dataset_json(test_path("testdata", paste0(nm, ".json")))
    from_ndjson <- read_dataset_ndjson(test_path("testdata", paste0(nm, ".ndjson")))

    # same data
    expect_equal(as.data.frame(from_json), as.data.frame(from_ndjson),
                 info = nm)

    # same metadata, attribute for attribute
    a <- attributes(from_json)
    b <- attributes(from_ndjson)
    a$datasetJSONCreationDateTime <- b$datasetJSONCreationDateTime <- NULL
    expect_equal(a, b, info = nm)

    # and therefore the same bytes out, whichever format we write
    expect_identical(
      blank_created(write_dataset_json(from_json)),
      blank_created(write_dataset_json(from_ndjson)),
      info = nm
    )
    expect_identical(
      blank_created(write_dataset_ndjson(from_json)),
      blank_created(write_dataset_ndjson(from_ndjson)),
      info = nm
    )
  }
})

test_that("a trip through the other format changes nothing", {
  # adsl included here: this path never crosses the two reference files, so the
  # discrepancy between them does not apply
  for (nm in c(converging, "adsl")) {
    from_json <- read_dataset_json(test_path("testdata", paste0(nm, ".json")))
    from_ndjson <- read_dataset_ndjson(test_path("testdata", paste0(nm, ".ndjson")))

    # json -> ndjson -> json
    direct <- blank_created(write_dataset_json(from_json))
    via_ndjson <- blank_created(write_dataset_json(
      read_dataset_ndjson(write_dataset_ndjson(from_json))
    ))
    expect_identical(via_ndjson, direct, info = nm)

    # ndjson -> json -> ndjson
    direct_nd <- blank_created(write_dataset_ndjson(from_ndjson))
    via_json <- blank_created(write_dataset_ndjson(
      read_dataset_json(write_dataset_json(from_ndjson))
    ))
    expect_identical(via_json, direct_nd, info = nm)
  }
})

test_that("cross-format output reproduces the CDISC reference files", {
  for (nm in converging) {
    ref_json <- paste(
      readLines(test_path("testdata", paste0(nm, ".json")), warn = FALSE),
      collapse = "\n")
    ref_ndjson <- paste(
      readLines(test_path("testdata", paste0(nm, ".ndjson")), warn = FALSE),
      collapse = "\n")

    # ndjson in, json out - must match the published json
    ours <- parse_json(write_dataset_json(
      read_dataset_ndjson(test_path("testdata", paste0(nm, ".ndjson")))))
    theirs <- parse_json(ref_json)
    expect_equal(ours, theirs, info = nm)

    # json in, ndjson out - must match the published ndjson
    ours_nd <- parse_ndjson(write_dataset_ndjson(
      read_dataset_json(test_path("testdata", paste0(nm, ".json")))))
    theirs_nd <- parse_ndjson(ref_ndjson)
    theirs_nd$meta$rows <- NULL
    expect_equal(ours_nd$meta, theirs_nd$meta, info = nm)
    expect_equal(ours_nd$rows, theirs_nd$rows, info = nm)
  }
})

test_that("the two adsl reference files disagree with each other", {
  # Documented rather than skipped. If these expectations start failing, the
  # reference data changed and the exclusion above should be revisited.
  from_json <- read_dataset_json(test_path("testdata", "adsl.json"))
  from_ndjson <- read_dataset_ndjson(test_path("testdata", "adsl.ndjson"))

  # 1. the files carry different dataset labels
  expect_equal(attr(from_json, "label"), "Subject-Level Analysis Dataset")
  expect_equal(attr(from_ndjson, "label"), "Subject-Level Analysis")

  # 2. the data itself is identical, so this is metadata only
  expect_equal(as.data.frame(from_json), as.data.frame(from_ndjson),
               ignore_attr = TRUE)

  # 3. every other attribute agrees
  a <- attributes(from_json)
  b <- attributes(from_ndjson)
  a$datasetJSONCreationDateTime <- b$datasetJSONCreationDateTime <- NULL
  a$label <- b$label <- NULL
  expect_equal(a, b)
})

test_that("whole-valued floats are written as floats", {
  # adsl AVGDD and CUMDOSE are dataType float holding whole numbers. yyjson
  # renders those as 0.0 where the CDISC reference file has 0. Both are valid
  # JSON numbers that parse to the same double, and this matches what the
  # package wrote before the native writer.
  j <- write_dataset_json(read_dataset_json(test_path("testdata", "adsl.json")))
  parsed <- jsonlite::fromJSON(j, simplifyVector = FALSE)
  nms <- vapply(parsed$columns, function(z) z$name, character(1))
  cumdose <- parsed$rows[[1]][[which(nms == "CUMDOSE")]]

  expect_true(grepl("0.0", j, fixed = TRUE))
  expect_identical(cumdose, 0)          # a double, not an integer literal
  expect_equal(as.double(cumdose), 0)
})

test_that("numbers survive a write and read bit-exactly on every path", {
  # expect_equal() carries a ~1.5e-8 tolerance, which is orders of magnitude too
  # loose to notice last-bit precision loss - the exact failure this package
  # exists to avoid. These comparisons are identical(), no tolerance at all.
  set.seed(42)
  n <- 300
  v <- 10^runif(n, -12, 12) * sample(c(-1, 1), n, TRUE) * runif(n, 1, 10)
  v[1:3] <- c(0, NA, 1)

  d <- data.frame(SUBJ = sprintf("S%03d", seq_len(n)), V = v,
                  stringsAsFactors = FALSE)
  items <- data.frame(
    itemOID = c("IT.SUBJ", "IT.V"), name = c("SUBJ", "V"),
    label = c("Subject", "Value"), dataType = c("string", "float"),
    stringsAsFactors = FALSE
  )
  ds <- dataset_json(d, item_oid = "t", name = "t", dataset_label = "t",
                     columns = items)

  paths <- list(
    "json"                  = function() read_dataset_json(write_dataset_json(ds)),
    "ndjson"                = function() read_dataset_ndjson(write_dataset_ndjson(ds)),
    "json, decimal"         = function() read_dataset_json(
      suppressWarnings(write_dataset_json(ds, float_as_decimals = TRUE))),
    "ndjson, decimal"       = function() read_dataset_ndjson(
      suppressWarnings(write_dataset_ndjson(ds, float_as_decimals = TRUE))),
    "json -> ndjson -> json" = function() read_dataset_json(
      write_dataset_json(read_dataset_ndjson(write_dataset_ndjson(ds))))
  )

  for (nm in names(paths)) {
    got <- as.double(paths[[nm]]()$V)
    expect_identical(got, v, info = nm)
  }
})
