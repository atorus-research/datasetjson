# Paths that the reference datasets never reach: boolean columns, malformed
# files, values that contradict their declared type, and the URL entry points.

mk <- function(d, items) {
  dataset_json(d, item_oid = "t", name = "t", dataset_label = "t",
               columns = items)
}

test_that("boolean columns round-trip, including NA", {
  d <- data.frame(
    SUBJ = c("A", "B", "C"),
    FLAG = c(TRUE, FALSE, NA),
    stringsAsFactors = FALSE
  )
  items <- data.frame(
    itemOID = c("IT.SUBJ", "IT.FLAG"), name = c("SUBJ", "FLAG"),
    label = c("Subject", "Flag"), dataType = c("string", "boolean"),
    stringsAsFactors = FALSE
  )
  ds <- mk(d, items)

  js <- write_dataset_json(ds)
  expect_true(grepl("true", js, fixed = TRUE))
  expect_true(grepl("false", js, fixed = TRUE))
  expect_true(grepl("null", js, fixed = TRUE))
  expect_message(validate_dataset_json(js), "File is valid")

  for (back in list(read_dataset_json(js),
                    read_dataset_ndjson(write_dataset_ndjson(ds)))) {
    expect_type(back$FLAG, "logical")
    expect_identical(as.logical(back$FLAG), c(TRUE, FALSE, NA))
  }
})

test_that("NA of every type survives a round trip", {
  d <- data.frame(
    S = NA_character_, I = NA_integer_, F = NA_real_, B = NA,
    stringsAsFactors = FALSE
  )
  items <- data.frame(
    itemOID = paste0("IT.", names(d)), name = names(d), label = names(d),
    dataType = c("string", "integer", "float", "boolean"),
    stringsAsFactors = FALSE
  )
  back <- read_dataset_json(write_dataset_json(mk(d, items)))

  expect_true(is.na(back$S))
  expect_true(is.na(back$I))
  expect_true(is.na(back$F))
  expect_true(is.na(back$B))
  expect_type(back$I, "integer")
  expect_type(back$F, "double")
  expect_type(back$B, "logical")
})

test_that("values contradicting their declared type become NA with a warning", {
  # build a valid file, then rewrite the row so each value has the wrong type
  d <- data.frame(S = "x", I = 1L, F = 1.5, B = TRUE, stringsAsFactors = FALSE)
  items <- data.frame(
    itemOID = paste0("IT.", names(d)), name = names(d), label = names(d),
    dataType = c("string", "integer", "float", "boolean"),
    stringsAsFactors = FALSE
  )
  js <- write_dataset_json(mk(d, items))

  # string <- number and boolean; number <- string; boolean <- string
  swapped <- sub('["x",1,1.5,true]', '[12.5,"nope","nope","nope"]', js,
                 fixed = TRUE)
  expect_false(identical(swapped, js))

  expect_warning(read_dataset_json(swapped), "did not match the declared")
  back <- suppressWarnings(read_dataset_json(swapped))
  expect_equal(back$S, "12.5", ignore_attr = TRUE)   # number rendered into a string column
  expect_true(is.na(back$I))
  expect_true(is.na(back$F))
  expect_true(is.na(back$B))

  # a boolean landing in a string column is rendered, not dropped
  bool_in_str <- sub('["x",1,1.5,true]', '[true,1,1.5,true]', js, fixed = TRUE)
  expect_equal(suppressWarnings(read_dataset_json(bool_in_str))$S, "true",
               ignore_attr = TRUE)
})

test_that("integers beyond R's range are reported rather than wrapped", {
  d <- data.frame(N = 1L)
  items <- data.frame(itemOID = "IT.N", name = "N", label = "N",
                      dataType = "integer", stringsAsFactors = FALSE)
  js <- sub("[[1]]", "[[9999999999]]", write_dataset_json(mk(d, items)),
            fixed = TRUE)

  expect_warning(read_dataset_json(js), "exceeded R's integer range")
  back <- suppressWarnings(read_dataset_json(js))
  expect_true(is.na(back$N))
})

test_that("decimal values that are not numbers are reported", {
  d <- data.frame(V = c("1.5", "abc"), stringsAsFactors = FALSE)
  items <- data.frame(itemOID = "IT.V", name = "V", label = "V",
                      dataType = "decimal", targetDataType = "decimal",
                      stringsAsFactors = FALSE)
  js <- write_dataset_json(mk(d, items))

  expect_warning(read_dataset_json(js), "could not be parsed as numbers")
  back <- suppressWarnings(read_dataset_json(js))
  expect_equal(as.double(back$V), c(1.5, NA), ignore_attr = TRUE)

  # a bare number in a decimal column is tolerated
  numeric_form <- sub('["1.5"]', "[1.5]", js, fixed = TRUE)
  expect_equal(as.double(suppressWarnings(read_dataset_json(numeric_form))$V)[1],
               1.5)

  # and an empty string reads as NA, not zero
  empty <- sub('"abc"', '""', js, fixed = TRUE)
  expect_true(is.na(read_dataset_json(empty)$V[2]))
})

test_that("an unrecognised dataType is read as text", {
  d <- data.frame(V = "0123", stringsAsFactors = FALSE)
  items <- data.frame(itemOID = "IT.V", name = "V", label = "V",
                      dataType = "URI", stringsAsFactors = FALSE)
  back <- read_dataset_json(write_dataset_json(mk(d, items)))
  expect_type(back$V, "character")
  expect_equal(back$V, "0123", ignore_attr = TRUE)
})

test_that("malformed Dataset JSON is rejected with a useful message", {
  expect_error(read_dataset_json("[1,2,3]"),
               "must be a JSON object at the top level")
  expect_error(read_dataset_json('{"columns":[{"name":"a","dataType":"string"}]}'),
               "`rows` is missing or not an array")
  expect_error(read_dataset_json('{"rows":[]}'),
               "`columns` is missing or not an array")
  expect_error(read_dataset_json('{"columns":[],"rows":[]}'),
               "`columns` is empty")
  expect_error(
    read_dataset_json('{"columns":[{"name":"a","dataType":"string"}],"rows":[1]}'),
    "Row 1 is not an array"
  )
})

test_that("malformed Dataset NDJSON is rejected with a useful message", {
  expect_error(read_dataset_ndjson(""), "empty")
  expect_error(read_dataset_ndjson("not json\n[1]"), "Failed to parse the metadata line")
  expect_error(read_dataset_ndjson("[1,2]\n[1]"),
               "first NDJSON line must be a JSON object")
  expect_error(read_dataset_ndjson('{"name":"a"}\n[1]'),
               "`columns` is missing from the metadata line")
  expect_error(
    read_dataset_ndjson('{"columns":[{"name":"a","dataType":"string"}]}\nnot json'),
    "Failed to parse data line 2"
  )
  expect_error(
    read_dataset_ndjson('{"columns":[{"name":"a","dataType":"string"}]}\n{"a":1}'),
    "line 2 is not an array"
  )
})

test_that("rows shorter than the column list are reported", {
  d <- data.frame(A = "x", B = "y", stringsAsFactors = FALSE)
  items <- data.frame(itemOID = c("IT.A", "IT.B"), name = c("A", "B"),
                      label = c("A", "B"), dataType = c("string", "string"),
                      stringsAsFactors = FALSE)
  js <- sub('["x","y"]', '["x"]', write_dataset_json(mk(d, items)), fixed = TRUE)

  expect_warning(read_dataset_json(js), "fewer values than there are columns")
  back <- suppressWarnings(read_dataset_json(js))
  expect_true(is.na(back$B))
})

test_that("NDJSON and DSJC-adjacent readers accept a URL", {
  ds <- mk(head(iris, 10), iris_items)
  f <- withr::local_tempfile(fileext = ".ndjson")
  write_dataset_ndjson(ds, f)
  u <- paste0("file://", f)

  expect_equal(read_dataset_ndjson(u), read_dataset_ndjson(f))
  expect_message(validate_dataset_ndjson(u), "File is valid")
})

test_that("validate_dataset_ndjson reports a line that is not JSON at all", {
  ds <- mk(head(iris, 3), iris_items)
  lines <- strsplit(write_dataset_ndjson(ds), "\n")[[1]]
  lines[3] <- '{"not":"an array"}'
  errs <- suppressWarnings(validate_dataset_ndjson(paste(lines, collapse = "\n")))
  expect_equal(errs$message, "Line is not an array of values")
})

test_that("factors write as labels, including NA levels", {
  d <- data.frame(
    G = factor(c("a", "b", NA), levels = c("a", "b")),
    stringsAsFactors = FALSE
  )
  items <- data.frame(itemOID = "IT.G", name = "G", label = "G",
                      dataType = "string", stringsAsFactors = FALSE)
  js <- write_dataset_json(mk(d, items))

  expect_true(grepl('"a"', js, fixed = TRUE))
  expect_true(grepl("null", js, fixed = TRUE))
  expect_equal(read_dataset_json(js)$G, c("a", "b", NA), ignore_attr = TRUE)
})

test_that("nested values in a scalar column are reported, not silently kept", {
  d <- data.frame(S = "x", V = "1.5", stringsAsFactors = FALSE)
  items <- data.frame(
    itemOID = c("IT.S", "IT.V"), name = c("S", "V"), label = c("S", "V"),
    dataType = c("string", "decimal"),
    targetDataType = c(NA_character_, "decimal"), stringsAsFactors = FALSE
  )
  js <- write_dataset_json(mk(d, items))

  # an object where a string is declared, and a boolean where a decimal is
  broken <- sub('["x","1.5"]', '[{"a":1},true]', js, fixed = TRUE)
  expect_false(identical(broken, js))

  expect_warning(read_dataset_json(broken), "did not match the declared")
  back <- suppressWarnings(read_dataset_json(broken))
  expect_true(is.na(back$S))
  expect_true(is.na(back$V))
})

test_that("a column with no name is rejected", {
  # `name` is required by the standard; without it the column cannot be placed
  # in the data frame, and the failure should say so rather than surfacing as
  # an obscure subscript error from R
  js <- paste0(
    '{"datasetJSONVersion":"1.1.0","itemGroupOID":"t","name":"t","label":"t",',
    '"records":1,"columns":[{"itemOID":"IT.A","dataType":"string"},',
    '{"itemOID":"IT.B","name":"B","dataType":"string"}],',
    '"rows":[["x","y"]]}'
  )
  expect_error(read_dataset_json(js), "Column 1 in `columns` has no `name`",
               fixed = TRUE)
  expect_error(read_dataset_ndjson(
    paste0('{"columns":[{"itemOID":"IT.A","dataType":"string"}]}\n["x"]')),
    "has no `name`")
})

test_that("NDJSON larger than the write buffer is flushed correctly", {
  # the file writer flushes every 8MB; this crosses that boundary
  n <- 260000L
  d <- data.frame(
    A = sprintf("subject-%06d", seq_len(n)),
    B = sprintf("value-%06d", seq_len(n)),
    stringsAsFactors = FALSE
  )
  items <- data.frame(
    itemOID = c("IT.A", "IT.B"), name = c("A", "B"), label = c("A", "B"),
    dataType = c("string", "string"), stringsAsFactors = FALSE
  )
  f <- withr::local_tempfile(fileext = ".ndjson")
  write_dataset_ndjson(mk(d, items), f)

  expect_gt(file.size(f), 8 * 1024^2)
  back <- read_dataset_ndjson(f)
  expect_equal(nrow(back), n)
  expect_equal(back$A[c(1, n)], d$A[c(1, n)], ignore_attr = TRUE)
  expect_equal(back$B[c(1, n)], d$B[c(1, n)], ignore_attr = TRUE)
})

test_that("the validators say so when jsonvalidate is not installed", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(validate_dataset_json("{}"), "is required for this function")
  expect_error(validate_dataset_ndjson("{}"), "is required for this function")
})
