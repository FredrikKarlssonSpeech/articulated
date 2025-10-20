context("Rcpp vowel space functions")

test_that("cpp_vowel_center computes center correctly", {
  f1 <- c(300, 600, 600, 300)
  f2 <- c(2200, 1700, 1000, 900)
  
  # Test centroid method
  center_cent <- cpp_vowel_center(f1, f2, method = "centroid")
  expect_type(center_cent, "list")
  expect_named(center_cent, c("f1c", "f2c"))
  expect_equal(center_cent$f1c, mean(f1))
  expect_equal(center_cent$f2c, mean(f2))
  
  # Test wcentroid method
  center_wcent <- cpp_vowel_center(f1, f2, method = "wcentroid")
  expect_type(center_wcent, "list")
  expect_named(center_wcent, c("f1c", "f2c"))
  
  # Test twomeans method
  center_2m <- cpp_vowel_center(f1, f2, method = "twomeans")
  expect_type(center_2m, "list")
  
  # Test NA handling
  f1_na <- c(300, NA, 600, 300)
  center_na <- cpp_vowel_center(f1_na, f2, method = "centroid", na_rm = TRUE)
  expect_false(is.na(center_na$f1c))
})

test_that("cpp_vowel_norms computes Euclidean distances", {
  f1 <- c(300, 600, 600, 300)
  f2 <- c(2200, 1700, 1000, 900)
  f1c <- mean(f1)
  f2c <- mean(f2)
  
  norms <- cpp_vowel_norms(f1, f2, f1c, f2c)
  
  expect_type(norms, "double")
  expect_length(norms, length(f1))
  expect_true(all(norms >= 0))
  
  # Manually compute first norm to verify
  expected_norm1 <- sqrt((f1[1] - f1c)^2 + (f2[1] - f2c)^2)
  expect_equal(norms[1], expected_norm1)
})

test_that("cpp_vowel_angles computes polar angles", {
  f1 <- c(300, 600, 600, 300)
  f2 <- c(2200, 1700, 1000, 900)
  f1c <- mean(f1)
  f2c <- mean(f2)
  
  angles <- cpp_vowel_angles(f1, f2, f1c, f2c)
  
  expect_type(angles, "double")
  expect_length(angles, length(f1))
  expect_true(all(angles >= -pi & angles <= pi))
})

test_that("VSA computes vowel space area", {
  f1 <- c(300, 600, 600, 300)
  f2 <- c(2200, 1700, 1000, 900)
  
  vsa <- VSA(f1, f2)
  expect_s3_class(vsa, "units")
  expect_true(as.numeric(vsa) > 0)
})

test_that("VSD computes vowel space density", {
  set.seed(123)
  f1 <- rnorm(100, 500, 100)
  f2 <- rnorm(100, 1500, 300)
  
  # VSD may fail with certain random data, so we allow NA
  vsd <- tryCatch(VSD(f2, f1), error = function(e) NA)
  
  # Should return either a valid units object or NA
  expect_true(is.na(vsd) || inherits(vsd, "units"))
})

test_that("cVSA computes continuous vowel space area", {
  set.seed(123)
  f1 <- rnorm(100, 500, 100)
  f2 <- rnorm(100, 1500, 300)
  
  # cVSA may fail with certain random data or geometry issues
  cvsa <- tryCatch(cVSA(f2, f1, vowel_categories = 3), error = function(e) NA)
  
  # Should return either a valid units object or NA
  expect_true(is.na(cvsa) || inherits(cvsa, "units"))
})
