context("Basic package functionality")

test_that("package loads successfully", {
  expect_true(require(articulated))
})

test_that("core functions are exported", {
  expect_true(exists("COV"))
  expect_true(exists("COV5_x"))
  expect_true(exists("rPVI"))
  expect_true(exists("nPVI"))
  expect_true(exists("VSA"))
})

test_that("integration functions are exported", {
  expect_true(exists("vsa_from_formants"))
  expect_true(exists("rhythm_from_intensity"))
  expect_true(exists("lst_articulation"))
  expect_true(exists("articulated_batch"))
})
