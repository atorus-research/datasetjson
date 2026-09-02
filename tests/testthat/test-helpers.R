test_that("datasetjson_example lists files when called with no arguments", {
  files <- datasetjson_example()
  expect_type(files, "character")
  expect_true("dm.json" %in% files)
})

test_that("datasetjson_example returns a valid path for a known file", {
  path <- datasetjson_example("dm.json")
  expect_true(file.exists(path))
  expect_true(endsWith(path, "dm.json"))
})

test_that("datasetjson_example errors for unknown file", {
  expect_error(datasetjson_example("nonexistent.json"))
})

test_that("Column metadata can extract properly", {
  ds_json <- dataset_json(
    iris,
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  x <- get_column_metadata(ds_json)
  x<-x[c("itemOID", "name", "label", "dataType", "length", "keySequence")]
  expect_equal(x, as.data.frame(iris_items))
})

test_that("Variable attributes can be applied", {

  iris2 <- iris
  iris2$Species <- as.character(iris$Species)

  ds_json <- dataset_json(
    iris2,
    item_oid = "IG.IRIS",
    name = "IRIS",
    dataset_label = "Iris",
    columns = iris_items
  )

  ds_json <- set_variable_attributes(ds_json)

  expect_equal(
    attributes(ds_json$Sepal.Length),
    list(
      itemOID = "IT.IR.Sepal.Length",
      label = "Sepal Length",
      dataType = "float",
      keySequence=2
    )
  )

  expect_equal(
    attributes(ds_json$Sepal.Width),
    list(
      itemOID = "IT.IR.Sepal.Width",
      label = "Sepal Width",
      dataType = "float"
    )
  )

  expect_equal(
    attributes(ds_json$Petal.Length),
    list(
      itemOID = "IT.IR.Petal.Length",
      label = "Petal Length",
      dataType = "float",
      keySequence=3
    )
  )


  expect_equal(
    attributes(ds_json$Petal.Width),
    list(
      itemOID = "IT.IR.Petal.Width",
      label = "Petal Width",
      dataType = "float"
    )
  )

  expect_equal(
    attributes(ds_json$Species),
    list(
      itemOID = "IT.IR.Species",
      label = "Flower Species",
      dataType = "string",
      length = 10L,
      keySequence=1
    )
  )

})
