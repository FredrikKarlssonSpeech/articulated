##' Extract vowel space metrics from formant tracks
##'
##' Processes formant tracks from superassp and computes vowel space metrics
##' using various methods. Handles time windowing and NA filtering automatically.
##'
##' @param formant_track Data frame or track object from superassp formant extraction
##'   (e.g., output from \code{superassp::trk_formantp()})
##' @param time_range Optional numeric vector c(start, end) specifying time window in seconds
##' @param method VSA computation method: "basic" (default), "density", or "continuous"
##' @param center_method Method for computing vowel space center: "wcentroid" (default),
##'   "centroid", or "twomeans"
##' @param ... Additional arguments passed to VSA computation functions
##' 
##' @return Named list of vowel space metrics including:
##'   \itemize{
##'     \item n_vowels - Number of valid vowel measurements
##'     \item f1_mean, f1_sd, f1_range - F1 descriptive statistics
##'     \item f2_mean, f2_sd, f2_range - F2 descriptive statistics
##'     \item vsa - Vowel space area (if method="basic")
##'     \item vsd - Vowel space density (if method="density")
##'     \item cvsa - Continuous vowel space area (if method="continuous")
##'   }
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' formants <- trk_formantp("audio.wav")
##' # Basic vowel space analysis
##' vsa_metrics <- vsa_from_formants(formants)
##' 
##' # Analyze specific time window
##' vsa_early <- vsa_from_formants(formants, time_range = c(0, 5))
##' 
##' # Use density method
##' vsd_metrics <- vsa_from_formants(formants, method = "density")
##' }
vsa_from_formants <- function(formant_track, 
                              time_range = NULL,
                              method = c("basic", "density", "continuous"),
                              center_method = "wcentroid",
                              ...) {
  method <- match.arg(method)
  
  # Extract F1 and F2 from track
  if (!all(c("F1", "F2") %in% names(formant_track))) {
    stop("formant_track must contain F1 and F2 columns")
  }
  
  # Apply time window if specified
  if (!is.null(time_range)) {
    if (!"time" %in% names(formant_track)) {
      warning("No time column found; ignoring time_range parameter")
      f1 <- formant_track$F1
      f2 <- formant_track$F2
    } else {
      idx <- formant_track$time >= time_range[1] & 
             formant_track$time <= time_range[2]
      f1 <- formant_track$F1[idx]
      f2 <- formant_track$F2[idx]
    }
  } else {
    f1 <- formant_track$F1
    f2 <- formant_track$F2
  }
  
  # Remove NA values and invalid formants
  valid <- !is.na(f1) & !is.na(f2) & f1 > 0 & f2 > 0
  f1 <- f1[valid]
  f2 <- f2[valid]
  
  if (length(f1) < 3) {
    warning("Insufficient valid formant measurements (< 3)")
    return(list(
      n_vowels = length(f1),
      error = "Insufficient data"
    ))
  }
  
  # Compute basic descriptive stats
  result <- list(
    n_vowels = length(f1),
    f1_mean = mean(f1),
    f1_sd = stats::sd(f1),
    f1_range = diff(range(f1)),
    f2_mean = mean(f2),
    f2_sd = stats::sd(f2),
    f2_range = diff(range(f2))
  )
  
  # Compute vowel space metrics based on method
  if (method == "basic") {
    # Compute center using Rcpp
    center <- cpp_vowel_center(f1, f2, method = center_method)
    result$f1_center <- center$f1c
    result$f2_center <- center$f2c
    
    # Compute norms and angles using Rcpp
    norms <- cpp_vowel_norms(f1, f2, center$f1c, center$f2c)
    angles <- cpp_vowel_angles(f1, f2, center$f1c, center$f2c)
    
    result$mean_norm <- mean(norms, na.rm = TRUE)
    result$sd_norm <- stats::sd(norms, na.rm = TRUE)
    result$cv_norm <- stats::sd(norms, na.rm = TRUE) / mean(norms, na.rm = TRUE)
    
    # Compute VSA
    result$vsa <- VSA(f1, f2)
    
  } else if (method == "density") {
    result$vsd <- VSD(f2, f1, ...)
    
  } else if (method == "continuous") {
    result$cvsa <- cVSA(f2, f1, ...)
  }
  
  class(result) <- c("articulated_vsa", "list")
  return(result)
}


##' Extract rhythm metrics from intensity or duration data
##'
##' Detects syllable-like units from intensity contours or processes pre-segmented
##' duration data to compute comprehensive rhythm metrics.
##'
##' @param track Either an intensity track from superassp (e.g., \code{trk_rmsana()})
##'   or a numeric vector of durations
##' @param threshold Intensity threshold for syllable detection in dB (default: -20).
##'   Ignored if track is a duration vector.
##' @param min_duration Minimum syllable duration in seconds (default: 0.05)
##' @param max_gap Maximum gap between syllables in seconds (default: 0.3)
##' @param ... Additional arguments
##' 
##' @return Named list of rhythm metrics including:
##'   \itemize{
##'     \item n_syllables - Number of syllables detected
##'     \item mean_duration, sd_duration - Duration statistics
##'     \item cov - Coefficient of variation
##'     \item rpvi, npvi - Pairwise variability indices
##'     \item cov5_20, pa, relstab_* - DDK metrics (if n >= 20)
##'     \item jitter_* - Jitter metrics (if n >= 5)
##'   }
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' # From intensity track
##' intensity <- trk_rmsana("audio.wav")
##' rhythm_metrics <- rhythm_from_intensity(intensity)
##' 
##' # From pre-segmented durations
##' durations <- c(0.12, 0.15, 0.13, 0.14, 0.16)
##' rhythm_metrics <- rhythm_from_intensity(durations)
##' }
rhythm_from_intensity <- function(track,
                                  threshold = -20,
                                  min_duration = 0.05,
                                  max_gap = 0.3,
                                  ...) {
  
  # Check if input is already a duration vector
  if (is.numeric(track) && !is.data.frame(track)) {
    durations <- track
  } else {
    # Extract syllable durations from intensity track
    if (!"rms" %in% names(track)) {
      stop("track must have 'rms' column or be a numeric duration vector")
    }
    
    # Detect syllable-like units
    above_threshold <- track$rms > threshold
    
    # Find runs of consecutive frames above threshold
    runs <- rle(above_threshold)
    
    # Extract durations
    durations <- numeric()
    cumsum_len <- cumsum(runs$lengths)
    
    for (i in seq_along(runs$lengths)) {
      if (runs$values[i]) {  # If above threshold
        start_idx <- if (i == 1) 1 else cumsum_len[i-1] + 1
        end_idx <- cumsum_len[i]
        
        if ("time" %in% names(track)) {
          duration <- track$time[end_idx] - track$time[start_idx]
        } else {
          # Estimate duration from frame count if no time column
          duration <- runs$lengths[i] * 0.005  # Assume 5ms frame rate
        }
        
        if (duration >= min_duration) {
          durations <- c(durations, duration)
        }
      }
    }
  }
  
  if (length(durations) < 2) {
    warning("Insufficient syllables detected (< 2)")
    return(list(
      n_syllables = length(durations),
      error = "Insufficient data"
    ))
  }
  
  # Compute basic metrics
  result <- list(
    n_syllables = length(durations),
    mean_duration = mean(durations),
    sd_duration = stats::sd(durations),
    min_duration = min(durations),
    max_duration = max(durations),
    total_duration = sum(durations),
    
    # Coefficient of variation (using Rcpp)
    cov = COV(durations),
    
    # Pairwise variability indices (using existing Rcpp)
    rpvi = rPVI(durations),
    npvi = nPVI(durations)
  )
  
  # Add metrics requiring 20+ syllables
  if (length(durations) >= 20) {
    result$cov5_20 <- COV5_x(durations, n = 20)
    result$pa <- PA(durations)
    result$relstab_5_12 <- relstab(durations, kind = "5_12")
    result$relstab_13_20 <- relstab(durations, kind = "13_20")
  }
  
  # Add jitter metrics if enough data
  if (length(durations) >= 5) {
    min_period <- stats::quantile(durations, 0.05)
    max_period <- stats::quantile(durations, 0.95)
    
    result$jitter_local <- jitter_local(durations, min_period, max_period)
    result$jitter_rap <- jitter_rap(durations, min_period, max_period)
    result$jitter_ppq5 <- jitter_ppq5(durations, min_period, max_period)
    result$jitter_ddp <- jitter_ddp(durations, min_period, max_period)
  }
  
  class(result) <- c("articulated_rhythm", "list")
  return(result)
}


##' Complete articulation analysis from audio file
##'
##' Performs comprehensive articulation analysis by extracting both formant
##' and intensity tracks and computing all relevant metrics. Requires superassp.
##'
##' @param audio_file Path to audio file
##' @param formant_fn Function to extract formants (default: \code{superassp::trk_formantp})
##' @param intensity_fn Function to extract intensity (default: \code{superassp::trk_rmsana})
##' @param formant_args List of arguments for formant extraction
##' @param intensity_args List of arguments for intensity extraction
##' @param vsa_method VSA computation method (default: "basic")
##' @param ... Additional arguments passed to metric computation functions
##' 
##' @return Named list with components:
##'   \itemize{
##'     \item file - Audio file path
##'     \item vowel_space - Vowel space metrics from \code{vsa_from_formants()}
##'     \item rhythm - Rhythm metrics from \code{rhythm_from_intensity()}
##'   }
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' # Complete analysis
##' analysis <- articulation_from_audio("speech.wav")
##' print(analysis$vowel_space$vsa)
##' print(analysis$rhythm$rpvi)
##' 
##' # Custom parameters
##' analysis <- articulation_from_audio("speech.wav",
##'                                     vsa_method = "density",
##'                                     formant_args = list(numFormants = 4))
##' }
articulation_from_audio <- function(audio_file,
                                    formant_fn = NULL,
                                    intensity_fn = NULL,
                                    formant_args = list(),
                                    intensity_args = list(),
                                    vsa_method = "basic",
                                    ...) {
  
  # Set default functions if not provided
  if (is.null(formant_fn)) {
    if (!requireNamespace("superassp", quietly = TRUE)) {
      stop("superassp package required. Install with: install.packages('superassp')")
    }
    formant_fn <- superassp::trk_formantp
  }
  
  if (is.null(intensity_fn)) {
    if (!requireNamespace("superassp", quietly = TRUE)) {
      stop("superassp package required")
    }
    intensity_fn <- superassp::trk_rmsana
  }
  
  # Extract tracks
  message("Extracting formants from ", basename(audio_file), "...")
  formants <- do.call(formant_fn, c(list(audio_file), formant_args))
  
  message("Extracting intensity...")
  intensity <- do.call(intensity_fn, c(list(audio_file), intensity_args))
  
  # Compute metrics
  message("Computing vowel space metrics...")
  vsa_metrics <- vsa_from_formants(formants, method = vsa_method, ...)
  
  message("Computing rhythm metrics...")
  rhythm_metrics <- rhythm_from_intensity(intensity, ...)
  
  result <- list(
    file = audio_file,
    vowel_space = vsa_metrics,
    rhythm = rhythm_metrics
  )
  
  class(result) <- c("articulated_analysis", "list")
  return(result)
}


##' Comprehensive articulation feature set (lst_* style)
##'
##' Computes a complete set of articulation features from an audio file,
##' returning a flat named list suitable for data analysis pipelines.
##' Compatible with superassp's lst_* function design.
##'
##' @param audio_file Path to audio file
##' @param vsa_method Vowel space area method: "basic", "density", or "continuous"
##' @param formant_args List of arguments for formant extraction
##' @param intensity_args List of arguments for intensity extraction
##' @param return_tracks Include intermediate tracks in output? (default: FALSE)
##' @param verbose Print progress messages? (default: TRUE)
##' @param ... Additional arguments passed to metric computation
##' 
##' @return Named list of features with atomic values suitable for data frames
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' # Extract all features
##' features <- lst_articulation("speech.wav")
##' 
##' # Convert to data frame
##' df <- as.data.frame(features)
##' 
##' # Process multiple files
##' files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
##' results <- lapply(files, lst_articulation)
##' results_df <- do.call(rbind, lapply(results, as.data.frame))
##' }
lst_articulation <- function(audio_file,
                             vsa_method = c("basic", "density", "continuous"),
                             formant_args = list(),
                             intensity_args = list(),
                             return_tracks = FALSE,
                             verbose = TRUE,
                             ...) {
  
  vsa_method <- match.arg(vsa_method)
  
  # Suppress messages if not verbose
  if (!verbose) {
    analysis <- suppressMessages(
      articulation_from_audio(
        audio_file,
        formant_args = formant_args,
        intensity_args = intensity_args,
        vsa_method = vsa_method,
        ...
      )
    )
  } else {
    analysis <- articulation_from_audio(
      audio_file,
      formant_args = formant_args,
      intensity_args = intensity_args,
      vsa_method = vsa_method,
      ...
    )
  }
  
  # Extract vowel space features
  vs <- analysis$vowel_space
  
  # Extract rhythm features
  rh <- analysis$rhythm
  
  # Build flat feature list
  features <- list(
    file = audio_file,
    
    # Vowel space features
    n_vowels = vs$n_vowels,
    f1_mean = vs$f1_mean,
    f1_sd = vs$f1_sd,
    f1_range = vs$f1_range,
    f2_mean = vs$f2_mean,
    f2_sd = vs$f2_sd,
    f2_range = vs$f2_range
  )
  
  # Add method-specific metrics
  if (vsa_method == "basic" && !is.null(vs$vsa)) {
    features$vsa <- as.numeric(vs$vsa)
    features$f1_center <- vs$f1_center
    features$f2_center <- vs$f2_center
    features$mean_norm <- vs$mean_norm
    features$sd_norm <- vs$sd_norm
    features$cv_norm <- vs$cv_norm
  } else if (vsa_method == "density" && !is.null(vs$vsd)) {
    features$vsd <- as.numeric(vs$vsd)
  } else if (vsa_method == "continuous" && !is.null(vs$cvsa)) {
    features$cvsa <- as.numeric(vs$cvsa)
  }
  
  # Rhythm features
  features$n_syllables <- rh$n_syllables
  features$mean_syllable_duration <- rh$mean_duration
  features$sd_syllable_duration <- rh$sd_duration
  features$min_syllable_duration <- rh$min_duration
  features$max_syllable_duration <- rh$max_duration
  features$total_duration <- rh$total_duration
  features$cov_syllable <- rh$cov
  features$rpvi <- rh$rpvi
  features$npvi <- rh$npvi
  
  # Optional rhythm features (if enough syllables)
  if (!is.null(rh$cov5_20)) {
    features$cov5_20 <- rh$cov5_20
    features$pa <- rh$pa
    features$relstab_5_12 <- rh$relstab_5_12
    features$relstab_13_20 <- rh$relstab_13_20
  }
  
  if (!is.null(rh$jitter_local)) {
    features$jitter_local <- rh$jitter_local
    features$jitter_rap <- rh$jitter_rap
    features$jitter_ppq5 <- rh$jitter_ppq5
    features$jitter_ddp <- rh$jitter_ddp
  }
  
  # Optionally include tracks
  if (return_tracks) {
    features$formant_track <- analysis$vowel_space
    features$intensity_track <- analysis$rhythm
  }
  
  class(features) <- c("lst_articulation", "list")
  return(features)
}


##' Rhythm-only feature extraction
##'
##' Extracts rhythm metrics from audio file using intensity-based
##' syllable detection. Faster than full articulation analysis.
##'
##' @inheritParams lst_articulation
##' @param intensity_args List of arguments for intensity extraction
##' @param return_track Return intensity track? (default: FALSE)
##' 
##' @return Named list of rhythm features
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' rhythm_features <- lst_rhythm("ddk_task.wav")
##' print(rhythm_features$cov5_20)
##' }
lst_rhythm <- function(audio_file,
                       intensity_args = list(),
                       return_track = FALSE,
                       verbose = TRUE,
                       ...) {
  
  if (!requireNamespace("superassp", quietly = TRUE)) {
    stop("superassp package required")
  }
  
  if (verbose) {
    message("Extracting intensity from ", basename(audio_file), "...")
  }
  
  intensity <- do.call(superassp::trk_rmsana,
                      c(list(audio_file), intensity_args))
  
  if (verbose) {
    message("Computing rhythm metrics...")
  }
  
  rhythm_metrics <- rhythm_from_intensity(intensity, ...)
  
  features <- list(
    file = audio_file,
    n_syllables = rhythm_metrics$n_syllables,
    mean_duration = rhythm_metrics$mean_duration,
    sd_duration = rhythm_metrics$sd_duration,
    cov = rhythm_metrics$cov,
    rpvi = rhythm_metrics$rpvi,
    npvi = rhythm_metrics$npvi
  )
  
  if (!is.null(rhythm_metrics$cov5_20)) {
    features$cov5_20 <- rhythm_metrics$cov5_20
    features$pa <- rhythm_metrics$pa
    features$relstab_5_12 <- rhythm_metrics$relstab_5_12
    features$relstab_13_20 <- rhythm_metrics$relstab_13_20
  }
  
  if (!is.null(rhythm_metrics$jitter_local)) {
    features$jitter_local <- rhythm_metrics$jitter_local
    features$jitter_rap <- rhythm_metrics$jitter_rap
    features$jitter_ppq5 <- rhythm_metrics$jitter_ppq5
    features$jitter_ddp <- rhythm_metrics$jitter_ddp
  }
  
  if (return_track) {
    features$intensity_track <- intensity
  }
  
  class(features) <- c("lst_rhythm", "list")
  return(features)
}


##' Vowel space feature extraction
##'
##' Extracts vowel space metrics from audio file using formant analysis.
##' Supports multiple VSA computation methods.
##'
##' @inheritParams lst_articulation
##' @param methods Character vector of VSA methods to compute
##' @param formant_args List of arguments for formant extraction
##' @param return_track Return formant track? (default: FALSE)
##' 
##' @return Named list of vowel space features
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' # Compute multiple methods
##' vsa_features <- lst_vowelspace("vowels.wav", methods = c("basic", "density"))
##' print(vsa_features$vsa)
##' print(vsa_features$vsd)
##' }
lst_vowelspace <- function(audio_file,
                          methods = c("basic"),
                          formant_args = list(),
                          return_track = FALSE,
                          verbose = TRUE,
                          ...) {
  
  if (!requireNamespace("superassp", quietly = TRUE)) {
    stop("superassp package required")
  }
  
  if (verbose) {
    message("Extracting formants from ", basename(audio_file), "...")
  }
  
  formants <- do.call(superassp::trk_formantp,
                     c(list(audio_file), formant_args))
  
  features <- list(file = audio_file)
  
  for (method in methods) {
    if (verbose) {
      message("Computing vowel space metrics (", method, ")...")
    }
    
    vsa_metrics <- vsa_from_formants(formants, method = method, ...)
    
    if (method == "basic" && !is.null(vsa_metrics$vsa)) {
      features$vsa <- as.numeric(vsa_metrics$vsa)
      features$f1_center <- vsa_metrics$f1_center
      features$f2_center <- vsa_metrics$f2_center
      features$mean_norm <- vsa_metrics$mean_norm
      features$sd_norm <- vsa_metrics$sd_norm
      features$f1_mean <- vsa_metrics$f1_mean
      features$f2_mean <- vsa_metrics$f2_mean
    } else if (method == "density" && !is.null(vsa_metrics$vsd)) {
      features$vsd <- as.numeric(vsa_metrics$vsd)
    } else if (method == "continuous" && !is.null(vsa_metrics$cvsa)) {
      features$cvsa <- as.numeric(vsa_metrics$cvsa)
    }
  }
  
  if (return_track) {
    features$formant_track <- formants
  }
  
  class(features) <- c("lst_vowelspace", "list")
  return(features)
}


##' Batch process multiple audio files
##'
##' Processes multiple audio files in parallel or sequentially, extracting
##' articulation features and returning results as a data frame.
##'
##' @param audio_files Character vector of audio file paths
##' @param feature_fn Feature extraction function (default: \code{lst_articulation})
##' @param parallel Use parallel processing? (default: FALSE)
##' @param n_cores Number of cores for parallel processing (default: all available - 1)
##' @param progress Show progress bar? (default: TRUE)
##' @param stop_on_error Stop if any file fails? (default: FALSE)
##' @param ... Arguments passed to feature_fn
##' 
##' @return Data frame with one row per file
##' 
##' @author Fredrik Nylén
##' @export
##' @examples
##' \dontrun{
##' files <- list.files("audio", pattern = "\\.wav$", full.names = TRUE)
##' 
##' # Sequential processing
##' results <- articulated_batch(files, lst_articulation)
##' 
##' # Parallel processing
##' results <- articulated_batch(files, lst_rhythm, parallel = TRUE, n_cores = 4)
##' 
##' # Save results
##' write.csv(results, "articulation_features.csv", row.names = FALSE)
##' }
articulated_batch <- function(audio_files,
                              feature_fn = lst_articulation,
                              parallel = FALSE,
                              n_cores = parallel::detectCores() - 1,
                              progress = TRUE,
                              stop_on_error = FALSE,
                              ...) {
  
  if (length(audio_files) == 0) {
    stop("No audio files provided")
  }
  
  if (parallel && requireNamespace("parallel", quietly = TRUE)) {
    if (progress) {
      message("Processing ", length(audio_files), " files in parallel using ", 
              n_cores, " cores...")
    }
    
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl))
    
    # Export necessary packages and functions
    parallel::clusterEvalQ(cl, {
      library(articulated)
      if (requireNamespace("superassp", quietly = TRUE)) {
        library(superassp)
      }
    })
    
    results <- parallel::parLapply(cl, audio_files, function(f) {
      tryCatch(
        feature_fn(f, verbose = FALSE, ...),
        error = function(e) {
          warning(paste("Error processing", basename(f), ":", e$message))
          if (stop_on_error) stop(e)
          return(NULL)
        }
      )
    })
  } else {
    # Sequential processing with optional progress bar
    if (progress && requireNamespace("utils", quietly = TRUE)) {
      message("Processing ", length(audio_files), " files sequentially...")
      pb <- utils::txtProgressBar(min = 0, max = length(audio_files), style = 3)
    }
    
    results <- lapply(seq_along(audio_files), function(i) {
      if (progress && exists("pb")) {
        utils::setTxtProgressBar(pb, i)
      }
      
      tryCatch(
        feature_fn(audio_files[i], verbose = FALSE, ...),
        error = function(e) {
          warning(paste("Error processing", basename(audio_files[i]), ":", e$message))
          if (stop_on_error) stop(e)
          return(NULL)
        }
      )
    })
    
    if (progress && exists("pb")) {
      close(pb)
    }
  }
  
  # Filter out failed files
  valid_results <- results[!sapply(results, is.null)]
  
  if (length(valid_results) == 0) {
    stop("No files were successfully processed")
  }
  
  if (length(valid_results) < length(audio_files)) {
    message("Successfully processed ", length(valid_results), " of ", 
            length(audio_files), " files")
  }
  
  # Convert to data frame
  df <- do.call(rbind, lapply(valid_results, function(feat) {
    # Remove non-atomic elements (like tracks)
    feat <- feat[sapply(feat, function(x) is.atomic(x) && length(x) == 1)]
    as.data.frame(feat, stringsAsFactors = FALSE)
  }))
  
  rownames(df) <- NULL
  return(df)
}
