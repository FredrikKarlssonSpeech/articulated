##' Convert frequency (Hz) to semitones
##'
##' Converts frequency values in Hertz to semitones relative to C0 (16.352 Hz).
##'
##' @param f Frequency in Hz (numeric vector)
##' @return Semitone values (numeric vector)
##' @export
##' @examples
##' hz2st(440)  # A4 = 57 semitones
##' hz2st(c(220, 440, 880))
hz2st <- function(f){
  st <- 12*log2(f / 16.352)
  return(st)
}

##' Create a phonetogram (voice range profile)
##'
##' Generates a phonetogram showing the distribution of pitch and amplitude
##' values from an audio recording. Uses superassp for feature extraction.
##'
##' @param soundFile Path to audio file
##' @param bin_size Bin size for discretization (default: 5)
##' @param pitch_method Pitch extraction method from superassp (default: "ksvF0")
##' @param intensity_method Intensity extraction method from superassp (default: "rmsana")
##' @param return_data Return data instead of plot? (default: FALSE)
##' @param ... Additional arguments passed to pitch/intensity extraction functions
##'
##' @return A ggplot2 object (if return_data=FALSE) or a data frame (if return_data=TRUE)
##' @export
##' @examples
##' \dontrun{
##' library(superassp)
##' fonetogram("voice_sample.wav")
##' # Return data for custom plotting
##' data <- fonetogram("voice_sample.wav", return_data = TRUE)
##' }
fonetogram <- function(soundFile, 
                       bin_size = 5,
                       pitch_method = "ksvF0",
                       intensity_method = "rmsana",
                       return_data = FALSE,
                       ...) {
  
  # Check if superassp is available
  if (!requireNamespace("superassp", quietly = TRUE)) {
    stop("superassp package is required for fonetogram(). Install with: install.packages('superassp')")
  }
  
  # Extract pitch using superassp
  pitch_fn <- switch(pitch_method,
                     "ksvF0" = superassp::trk_ksvF0,
                     "snackp" = superassp::trk_snackp,
                     "pitchp" = superassp::trk_pitchp,
                     stop("Unknown pitch method. Use 'ksvF0', 'snackp', or 'pitchp'"))
  
  f0_track <- pitch_fn(soundFile, toFile = FALSE, ...)
  pitch <- f0_track$F0
  pitch[pitch == 0 | is.na(pitch)] <- NA
  
  # Extract intensity using superassp
  intensity_fn <- switch(intensity_method,
                        "rmsana" = superassp::trk_rmsana,
                        "intensityp" = superassp::trk_intensityp,
                        stop("Unknown intensity method. Use 'rmsana' or 'intensityp'"))
  
  intensity_track <- intensity_fn(soundFile, toFile = FALSE, ...)
  
  # Extract RMS values (handle different output formats)
  if ("rms" %in% names(intensity_track)) {
    if (is.matrix(intensity_track$rms)) {
      amplitude <- intensity_track$rms[, 1]
    } else {
      amplitude <- intensity_track$rms
    }
  } else {
    stop("Could not extract intensity values from track")
  }
  
  # Ensure vectors are same length
  min_len <- min(length(pitch), length(amplitude))
  pitch <- pitch[1:min_len]
  amplitude <- amplitude[1:min_len]
  
  # Convert pitch to semitones and bin
  st <- round(hz2st(pitch) / bin_size, digits = 0) * bin_size
  amp_binned <- round(amplitude / bin_size, digits = 0) * bin_size
  
  # Create data frame
  dat <- data.frame(amp = amp_binned, pitch = st)
  
  # Remove NA values and aggregate
  dat <- dat[!is.na(dat$pitch) & !is.na(dat$amp), ]
  
  if (nrow(dat) == 0) {
    warning("No valid pitch/amplitude data found")
    return(NULL)
  }
  
  # Aggregate counts
  dat_agg <- aggregate(list(n = rep(1, nrow(dat))), 
                       by = list(amp = dat$amp, pitch = dat$pitch), 
                       FUN = sum)
  
  # Return data if requested
  if (return_data) {
    return(dat_agg)
  }
  
  # Create plot
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    warning("ggplot2 package required for plotting. Returning data instead.")
    return(dat_agg)
  }
  
  p <- ggplot2::ggplot(dat_agg, ggplot2::aes(x = pitch, y = amp)) +
    ggplot2::geom_tile(ggplot2::aes(fill = n)) +
    ggplot2::scale_fill_viridis_c(option = "viridis") +
    ggplot2::theme_bw() +
    ggplot2::labs(fill = "Count", 
                 x = "Pitch (Semitones)", 
                 y = "Amplitude (dB)",
                 title = "Phonetogram (Voice Range Profile)")
  
  # Add convex hull if ggforce is available
  if (requireNamespace("ggforce", quietly = TRUE)) {
    p <- p + ggforce::geom_mark_hull(ggplot2::aes(filter = n > 0), 
                                     alpha = 0.2, 
                                     fill = "lightgrey",
                                     expand = ggplot2::unit(2, "mm"))
  }
  
  return(p)
}
