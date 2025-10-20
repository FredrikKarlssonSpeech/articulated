context("Rcpp rhythm functions")

test_that("cpp_cov computes coefficient of variation correctly", {
  x <- c(1, 2, 3, 4, 5)
  result <- cpp_cov(x)
  expected <- sd(x) / mean(x)
  expect_equal(result, expected)
  
  # Test with NA handling
  x_na <- c(1, 2, NA, 4, 5)
  result_na <- cpp_cov(x_na, na_rm = TRUE)
  expect_false(is.na(result_na))
  
  # Test that NA is returned when na_rm = FALSE
  result_na_false <- cpp_cov(x_na, na_rm = FALSE)
  expect_true(is.na(result_na_false))
})

test_that("cpp_cov5_x computes relative COV correctly", {
  set.seed(123)
  x <- runif(25, 0.1, 0.3)
  result <- cpp_cov5_x(x, n = 20)
  
  # Check it returns a numeric value
  expect_type(result, "double")
  expect_false(is.na(result))
  
  # Test with insufficient data
  x_short <- runif(15, 0.1, 0.3)
  result_na <- cpp_cov5_x(x_short, n = 20, return_na = TRUE)
  expect_true(is.na(result_na))
  
  # Should error if return_na = FALSE and insufficient data
  expect_error(cpp_cov5_x(x_short, n = 20, return_na = FALSE))
})

test_that("COV wrapper function works", {
  x <- c(1, 2, 3, 4, 5)
  result <- COV(x)
  expected <- sd(x) / mean(x)
  expect_equal(result, expected)
})

test_that("COV5_x wrapper function works", {
  set.seed(123)
  x <- runif(25, 0.1, 0.3)
  result <- COV5_x(x, n = 20)
  expect_type(result, "double")
  expect_false(is.na(result))
})

test_that("rPVI computes correctly", {
  x <- c(100, 120, 110, 130, 115)
  result <- rPVI(x)
  expect_type(result, "double")
  expect_false(is.na(result))
  expect_true(result >= 0)
})

test_that("nPVI computes correctly", {
  x <- c(100, 120, 110, 130, 115)
  result <- nPVI(x)
  expect_type(result, "double")
  expect_false(is.na(result))
})

test_that("jitter functions work", {
  set.seed(123)
  x <- runif(20, 0.08, 0.12)
  min_period <- 0.05
  max_period <- 0.15
  
  jitter_loc <- jitter_local(x, min_period, max_period)
  expect_type(jitter_loc, "double")
  expect_false(is.na(jitter_loc))
  
  jitter_r <- jitter_rap(x, min_period, max_period)
  expect_type(jitter_r, "double")
  
  jitter_p <- jitter_ppq5(x, min_period, max_period)
  expect_type(jitter_p, "double")
  
  jitter_d <- jitter_ddp(x, min_period, max_period)
  expect_type(jitter_d, "double")
})
