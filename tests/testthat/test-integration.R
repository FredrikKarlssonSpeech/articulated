context("superassp integration functions")

test_that("vsa_from_formants processes formant tracks", {
  # Create simulated formant track
  set.seed(123)
  formant_track <- data.frame(
    time = seq(0, 2, by = 0.01),
    F1 = rnorm(201, 500, 100),
    F2 = rnorm(201, 1500, 300),
    F3 = rnorm(201, 2500, 400)
  )
  
  # Test basic method
  result <- vsa_from_formants(formant_track, method = "basic")
  
  expect_type(result, "list")
  expect_s3_class(result, "articulated_vsa")
  expect_true(result$n_vowels > 0)
  expect_true(!is.na(result$f1_mean))
  expect_true(!is.na(result$f2_mean))
  expect_true(!is.null(result$vsa))
})

test_that("vsa_from_formants handles time windowing", {
  set.seed(123)
  formant_track <- data.frame(
    time = seq(0, 2, by = 0.01),
    F1 = rnorm(201, 500, 100),
    F2 = rnorm(201, 1500, 300)
  )
  
  result_early <- vsa_from_formants(formant_track, time_range = c(0, 1))
  result_late <- vsa_from_formants(formant_track, time_range = c(1, 2))
  
  # Should have different numbers of vowels
  expect_true(result_early$n_vowels < 201)
  expect_true(result_late$n_vowels < 201)
  expect_true(result_early$n_vowels > 0)
})

test_that("vsa_from_formants handles different methods", {
  set.seed(123)
  formant_track <- data.frame(
    time = seq(0, 1, by = 0.01),
    F1 = rnorm(101, 500, 100),
    F2 = rnorm(101, 1500, 300)
  )
  
  result_basic <- vsa_from_formants(formant_track, method = "basic")
  result_density <- vsa_from_formants(formant_track, method = "density")
  result_continuous <- vsa_from_formants(formant_track, method = "continuous")
  
  expect_s3_class(result_basic, "articulated_vsa")
  expect_s3_class(result_density, "articulated_vsa")
  expect_s3_class(result_continuous, "articulated_vsa")
})

test_that("rhythm_from_intensity processes duration vectors", {
  durations <- runif(25, 0.1, 0.3)
  result <- rhythm_from_intensity(durations)
  
  expect_type(result, "list")
  expect_s3_class(result, "articulated_rhythm")
  expect_equal(result$n_syllables, 25)
  expect_true(!is.na(result$mean_duration))
  expect_true(!is.na(result$cov))
  expect_true(!is.na(result$rpvi))
  expect_true(!is.na(result$npvi))
})

test_that("rhythm_from_intensity handles insufficient data", {
  durations <- c(0.1)
  
  expect_warning(result <- rhythm_from_intensity(durations))
  expect_equal(result$n_syllables, 1)
  expect_true(!is.null(result$error))
})

test_that("rhythm_from_intensity computes optional metrics", {
  set.seed(123)
  durations <- runif(25, 0.1, 0.3)
  result <- rhythm_from_intensity(durations)
  
  # With 25 syllables, should have DDK metrics
  expect_true(!is.null(result$cov5_20))
  expect_true(!is.null(result$pa))
  expect_true(!is.null(result$relstab_5_12))
  
  # Should also have jitter metrics
  expect_true(!is.null(result$jitter_local))
  expect_true(!is.null(result$jitter_rap))
})

test_that("rhythm_from_intensity handles track input", {
  # Simulated intensity track - correct length
  n_frames <- 600
  intensity_track <- data.frame(
    time = seq(0, (n_frames-1) * 0.005, by = 0.005),
    rms = rep(c(-30, -10, -30, -15, -30, -12), each = 100)
  )
  
  result <- rhythm_from_intensity(intensity_track, threshold = -20)
  
  expect_type(result, "list")
  expect_s3_class(result, "articulated_rhythm")
  expect_true(result$n_syllables > 0)
})

test_that("articulation_from_audio errors without superassp", {
  # Should error if superassp not available and no functions provided
  skip_if(requireNamespace("superassp", quietly = TRUE), 
          "superassp is installed")
  
  expect_error(articulation_from_audio("fake.wav"))
})

test_that("articulated_batch handles empty input", {
  expect_error(articulated_batch(character(0)))
})

test_that("articulated_batch returns data frame", {
  # This would require actual audio files, so we skip if superassp not available
  skip_if_not_installed("superassp")
  skip("Requires actual audio files")
  
  # Example test structure:
  # files <- c("test1.wav", "test2.wav")
  # result <- articulated_batch(files, lst_rhythm)
  # expect_s3_class(result, "data.frame")
  # expect_equal(nrow(result), 2)
})
