iris_items_bad <- readRDS(test_path("testdata", "iris_items_bad.Rds"))
iris_items_list <- readRDS(test_path("testdata", "iris_items_list.Rds"))

iris_items_test <- rbind(
  data.frame(OID  = "ITEMGROUPDATASEQ",
             name = "ITEMGROUPDATASEQ",
             label = "Record Identifier",
             type = "integer",
             length = NA_integer_,
             keySequence = NA_integer_,
             displayFormat = NA_character_),
  iris_items
)

test_that("Basic call produces expected object", {
  dataset_meta <- dataset_metadata(
    item_id = "IG.IRIS",
    name = "IRIS",
    label = "Iris",
    items = iris_items
  )

  expect_null(dataset_meta$IG.IRIS$records)
  expect_equal(dataset_meta$IG.IRIS$name, "IRIS")
  expect_equal(dataset_meta$IG.IRIS$label, "Iris")

  # Verify that ITEMGROUPSEQ is attached properly
  expect_equal(dataset_meta$IG.IRIS$items, iris_items_list)

  expect_null(dataset_meta$IG.IRIS$itemData)
})

test_that("ITEMGROUPDATASEQ will not duplicate when provided and data attaches properly", {
  dataset_meta <- dataset_metadata(
    item_id = "IG.IRIS",
    name = "IRIS",
    label = "Iris",
    items = iris_items_test,
    .data = iris
  )

  expect_equal(dataset_meta$IG.IRIS$items, iris_items_list)
})

test_that("items validator generates messages as expected", {
  expect_snapshot_error(dataset_metadata(
    item_id = "IG.IRIS",
    name = "IRIS",
    label = "Iris",
    items = iris_items_bad
  ))
})

test_that("dataset_metadata generates messages as expected", {
  expect_error(
    dataset_metadata(
      item_id = "IG.IRIS",
      name = "IRIS",
      label = "Iris",
      items = iris_items_test,
      .data = as.matrix(iris)
      ), ".data must be a data.frame"
  )
})
