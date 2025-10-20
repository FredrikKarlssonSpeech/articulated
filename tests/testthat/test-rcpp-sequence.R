context("Rcpp sequence analysis functions")

test_that("cpp_missing_vec_numeric identifies missing values", {
  x <- c(0, 0, 1.2, 1.5, 2.0, 0, NA)
  result <- cpp_missing_vec_numeric(x, what_na = 0)
  
  expect_type(result, "logical")
  expect_length(result, length(x))
  expect_true(result[1])  # 0 should be missing
  expect_true(result[2])  # 0 should be missing
  expect_false(result[3]) # 1.2 should not be missing
  expect_true(result[7])  # NA should be missing
})

test_that("cpp_missing_vec_character identifies missing strings", {
  x <- c("a", "b", "NA", "c", NA, "missing")
  result <- cpp_missing_vec_character(x, what_na = c("NA", "missing"))
  
  expect_type(result, "logical")
  expect_true(result[3])  # "NA" string
  expect_true(result[5])  # NA value
  expect_true(result[6])  # "missing" string
  expect_false(result[1]) # "a" not missing
})

test_that("cpp_missing_frac computes fraction correctly", {
  x <- c(0, 0, 1.2, 1.5, 2.0, 0, 0)
  result <- cpp_missing_frac(x, what_na = 0)
  
  expect_type(result, "double")
  expected <- 4 / 7  # 4 zeros out of 7 values
  expect_equal(result, expected)
})

test_that("cpp_left_changepoint finds first transition", {
  x <- c(0, 0, 1.2, 1.5, 2.0)
  result <- cpp_left_changepoint(x, what_na = 0)
  
  expect_type(result, "integer")
  expect_equal(result, 3)  # First non-zero at index 3
  
  # Test with no changepoint
  x_all_missing <- c(0, 0, 0)
  result_na <- cpp_left_changepoint(x_all_missing, what_na = 0)
  expect_true(is.na(result_na))
})

test_that("cpp_right_changepoint finds last transition", {
  x <- c(0, 0, 1.2, 1.5, 0, 0)
  result <- cpp_right_changepoint(x, what_na = 0)
  
  expect_type(result, "integer")
  expect_equal(result, 5)  # Last transition at index 5
})

test_that("cpp_lm_slope computes regression slope", {
  y <- c(1.0, 1.5, 2.0, 2.5, 3.0)
  result <- cpp_lm_slope(y, what_na = 0)
  
  expect_type(result, "double")
  # This is a perfect linear relationship, slope should be 0.5
  expect_true(abs(result - 0.5) < 0.01)
})

test_that("cpp_peak_prominence finds maximum residual", {
  # Create data with a peak
  y <- c(1.0, 1.5, 3.0, 2.0, 2.5)  # Peak at index 3
  result <- cpp_peak_prominence(y, what_na = 0)
  
  expect_type(result, "double")
  expect_true(result > 0)  # Should have positive prominence
})

test_that("missing_vec wrapper function works", {
  x <- c(0, 0, 1.2, 1.5, 2.0)
  result <- missing_vec(x, what.na = 0)
  
  expect_type(result, "logical")
  expect_true(result[1])
  expect_false(result[3])
})

test_that("missing_frac wrapper function works", {
  x <- c(0, 0, 1.2, 1.5, 2.0)
  result <- missing_frac(x, what.na = 0)
  
  expect_type(result, "double")
  expect_equal(result, 2/5)
})

test_that("changepoint wrapper functions work", {
  x <- c(0, 0, 1.2, 1.5, 0, 0)
  
  left <- left_changepoint(x, what.na = 0)
  expect_equal(left, 3)
  
  right <- right_changepoint(x, what.na = 0)
  expect_equal(right, 5)
})

test_that("lm_slope wrapper function works", {
  y <- c(1.0, 1.5, 2.0, 2.5, 3.0)
  result <- lm_slope(y, what.na = 0)
  
  expect_type(result, "double")
  expect_true(abs(result - 0.5) < 0.01)
})

test_that("peak_prominence wrapper function works", {
  y <- c(1.0, 1.5, 3.0, 2.0, 2.5)
  result <- peak_prominence(y, what.na = 0)
  
  expect_type(result, "double")
  expect_true(result > 0)
})
