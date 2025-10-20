# Articulated Package - Refactoring Assessment and Recommendations

**Date:** October 2025  
**Package Version:** 0.1.0 (2023-07-13)

## Executive Summary

This assessment reviews the `articulated` R package for speech performance analysis, focusing on efficiency improvements through Rcpp implementation and integration with the `superassp` package's `trk_*` and `lst_*` functions.

---

## 1. Current Function Inventory

### 1.1 Rhythm Analysis (`rythm.R`)
**Already in Rcpp (optimal):**
- `rPVI()` - Raw Pairwise Variability Index
- `nPVI()` - Normalized Pairwise Variability Index  
- `jitter_local()` - Local jitter computation
- `jitter_ddp()` - Difference of Differences of Periods
- `jitter_rap()` - Relative Average Perturbation
- `jitter_ppq5()` - Five-point Period Perturbation Quotient
- `cppRelStab()` - Relative stability (internal)

**Pure R functions:**
- `COV()` - Coefficient of variance
- `COV5_x()` - Coefficient of variance for intervals 5-n
- `relstab()` - Relative pace stability (wrapper)
- `PA()` - Pace acceleration

### 1.2 Vowel Formant Displays (`vfd.R`)
**All pure R functions:**
- `vowelspace.center()` - Vowel space center computation (3 methods)
- `vowel.norms()` - Vector norms for vowels
- `vowelspace.corners()` - Corner vowels identification
- `vowel.angles()` - Vector angles for vowels
- `vector.space()` - Complete vowel space analysis
- `VSD()` - Vowel space density (Story 2017)
- `cVSA()` - Continuous vowel space area (Sandoval 2013)
- `VSA()` - Basic vowel space area

### 1.3 Sequence Analysis (`sequence_analysis.R`)
**All pure R functions:**
- `missing_vec()` - Identify missing values
- `missing_frac()` - Fraction of missing values
- `left_changepoint()` - First change point
- `right_changepoint()` - Last change point  
- `peak_prominence()` - Peak prominence via linear model
- `lm_slope()` - Linear model slope

### 1.4 Voice Function Displays (`voice_function_displays.R`)
**Incomplete implementation:**
- `hz2st()` - Hz to semitone conversion
- `fonetogram()` - Phonetogram visualization (incomplete, has dependencies on `%>%`, `filter`, etc. not imported)

---

## 2. Performance Bottlenecks & Rcpp Candidates

### 2.1 High Priority for Rcpp Migration

#### **COV() and COV5_x()**
**Current:** Pure R with `sd()` and `mean()`  
**Bottleneck:** Called repeatedly in rhythm analysis pipelines  
**Rcpp Benefit:** ~10-50x speedup for large vectors  
**Complexity:** Low - straightforward arithmetic

#### **vector.space() and dependencies**
**Current:** Complex R code with loops, `atan2()`, trigonometric operations  
**Bottleneck:** 
- Loop over vowel corners (line 219-239)
- Multiple `mean()` and trigonometric computations
- Vector operations that could be vectorized in C++

**Rcpp Benefit:** ~20-100x speedup  
**Complexity:** Medium - requires careful translation of logic

#### **VSD() - Vowel Space Density**
**Current:** Uses `Rfast::dista()` + `apply()` + `geometry::convhulln()`  
**Bottleneck:**
- Distance matrix computation (line 306)
- Apply over columns (line 307)
- Could be fused into single Rcpp function

**Rcpp Benefit:** ~5-20x speedup by avoiding R overhead  
**Complexity:** Medium - need RcppArmadillo for matrix ops

#### **cVSA() - Continuous Vowel Space Area**
**Current:** Uses ClusterR GMM + filtering + convex hull  
**Bottleneck:** 
- GMM computation is in ClusterR (already optimized)
- But filtering (line 364) could be faster

**Rcpp Benefit:** ~2-5x speedup (limited by GMM)  
**Complexity:** Low for filtering part

### 2.2 Medium Priority

#### **Sequence analysis functions**
**Current:** Pure R with `diff()`, `which()`, `lm()`  
**Functions:** `missing_vec()`, `left/right_changepoint()`, `peak_prominence()`, `lm_slope()`  
**Rcpp Benefit:** ~5-10x speedup  
**Complexity:** Low to medium

### 2.3 Low Priority

#### **PA() and relstab()**
**Current:** Wrappers around Rcpp functions  
**Status:** Already optimized via `cppRelStab()`  
**Action:** Keep as-is

---

## 3. Code Quality Issues

### 3.1 Critical Issues

1. **voice_function_displays.R** - `fonetogram()` function is broken:
   - Uses pipe operator `%>%` without importing magrittr
   - Uses `filter()`, `group_by()`, `summarise()`, `ggplot()` without imports
   - Uses `geom_convexhull()` which doesn't exist in standard ggplot2
   - References `wrassp` package not in DESCRIPTION

2. **sequence_analysis.R** - Calls `superassp::missing_vec()` within itself:
   - Line 18: `isNA <- superassp::missing_vec(x,what.na=what.na)`
   - This creates circular dependency if superassp expects articulated

3. **Inconsistent NA handling:**
   - Some functions use `na.rm` parameter
   - Others use `omit` parameter  
   - Should be standardized

### 3.2 Minor Issues

1. **Documentation:** Uses Rdpack for citations but some references incomplete
2. **Naming conventions:** Mix of camelCase (`vowelspace.center`) and snake_case (`missing_vec`)
3. **No unit tests** visible in package structure
4. **vfd.R:** Uses deprecated `purrr::pluck()` style (lines 316, 370, 397)

---

## 4. Integration with superassp

### 4.1 Current State

The `superassp` package provides:
- **`trk_*` functions:** Extract time-series tracks from audio (formants, pitch, intensity, etc.)
- **`lst_*` functions:** Compute feature sets (eGeMAPS, ComParE, voice quality metrics)

The `articulated` package functions operate on:
- Vectors of durations (rhythm functions)
- Vectors of formant values (vowel space functions)

### 4.2 Integration Opportunities

#### **Direct Track Processing**
Create wrapper functions that accept `trk_*` outputs:

```r
# Example: Compute VSD from formant tracks
vsd_from_track <- function(formant_track, time_window = NULL, ...) {
  # Extract F1 and F2 from track object
  # Apply optional time windowing
  # Call VSD()
}

# Example: Rhythm analysis from syllable durations
rhythm_from_track <- function(intensity_track, threshold = -20, ...) {
  # Detect syllable boundaries
  # Compute durations
  # Call COV(), rPVI(), nPVI(), PA()
}
```

#### **List Processing Functions**
Create `lst_*` style functions for articulated:

```r
lst_rhythm <- function(audio_file, ...) {
  # Returns list of all rhythm metrics
  # Similar to lst_voice_reportp()
}

lst_vowelspace <- function(audio_file, formant_track = NULL, ...) {
  # Returns list of all vowel space metrics
}

lst_articulation <- function(audio_file, ...) {
  # Combined rhythm + vowel space metrics
}
```

#### **Batch Processing Support**
Enable operations on multiple tracks/files:

```r
# Process multiple speakers/conditions
articulated_batch <- function(track_list, metric_fn, ...) {
  # Apply metric_fn to each track
  # Return tidy data frame
}
```

### 4.3 Recommended Design Pattern

**1. Core computational functions (Rcpp):**
- Fast, type-safe, vectorized
- Accept simple numeric vectors
- Return single values or simple vectors

**2. Track interface functions (R):**
- Extract data from superassp track objects
- Handle time windowing, segmentation
- Call core functions
- Return structured results

**3. List feature functions (R):**
- High-level API similar to `lst_*` in superassp
- Process audio files end-to-end
- Return named lists compatible with superassp workflows

---

## 5. Proposed Refactoring Plan

### Phase 1: Fix Critical Issues (Week 1)
1. ✓ Remove or fix `fonetogram()` function
2. ✓ Fix `sequence_analysis.R` circular dependency
3. ✓ Add missing imports to DESCRIPTION
4. ✓ Standardize NA handling parameter names

### Phase 2: Rcpp Migration (Weeks 2-3)
1. **Create new Rcpp functions:**
   - `cpp_cov()` - Simple COV calculation
   - `cpp_cov5_x()` - Relative COV calculation
   - `cpp_vowel_norms()` - Vector norms calculation
   - `cpp_vowel_angles()` - Vector angles calculation
   - `cpp_vector_space()` - Full vowel space analysis
   - `cpp_distance_matrix()` - For VSD optimization

2. **Optimize existing Rcpp:**
   - Add error checking to `cppRelStab()`
   - Improve parameter validation in jitter functions

### Phase 3: superassp Integration (Weeks 4-5)
1. **Create track interface functions:**
   - `vsa_from_formants()` - Process formant tracks
   - `rhythm_from_intensity()` - Process intensity tracks
   - `articulation_from_tracks()` - Combined analysis

2. **Create lst_* functions:**
   - `lst_articulation()` - All metrics
   - `lst_rhythm()` - Rhythm metrics only
   - `lst_vowelspace()` - Vowel space metrics only

3. **Documentation:**
   - Vignette showing superassp integration
   - Examples with real audio files

### Phase 4: Testing & Documentation (Week 6)
1. Unit tests for all Rcpp functions
2. Integration tests with superassp
3. Benchmarks comparing R vs Rcpp
4. Update all documentation

---

## 6. Detailed Rcpp Implementation Examples

### 6.1 Simple COV Function

```cpp
#include <Rcpp.h>
using namespace Rcpp;

//' Coefficient of Variation
//' 
//' @param x Numeric vector
//' @param na_rm Remove NA values?
//' @return Standard deviation / mean
//' @export
// [[Rcpp::export]]
double cpp_cov(NumericVector x, bool na_rm = true) {
  if (na_rm) {
    x = x[!is_na(x)];
  }
  
  int n = x.size();
  if (n == 0) return R_NaReal;
  
  double sum = 0.0;
  for (int i = 0; i < n; ++i) {
    sum += x[i];
  }
  double mean = sum / n;
  
  double sum_sq = 0.0;
  for (int i = 0; i < n; ++i) {
    double diff = x[i] - mean;
    sum_sq += diff * diff;
  }
  double sd = sqrt(sum_sq / (n - 1));
  
  return sd / mean;
}
```

### 6.2 COV5_x Function

```cpp
//' Relative Coefficient of Variation (intervals 5-n vs 1-4)
//' 
//' @param x Vector of syllable durations
//' @param n Number of intervals (default 20)
//' @param return_na Return NA if insufficient data?
//' @param na_rm Remove NA values?
//' @return Relative COV or NA
//' @export
// [[Rcpp::export]]
double cpp_cov5_x(NumericVector x, int n = 20, 
                  bool return_na = true, bool na_rm = true) {
  if (na_rm) {
    x = x[!is_na(x)];
  }
  
  int N = x.size();
  if (N < n) {
    if (return_na) {
      return R_NaReal;
    } else {
      Rcpp::stop("Vector length must be at least " + std::to_string(n));
    }
  }
  
  // Mean of first 4 intervals
  double ref_sum = 0.0;
  for (int i = 0; i < 4; ++i) {
    ref_sum += x[i];
  }
  double ref_mean = ref_sum / 4.0;
  
  // SD of intervals 5 to n
  int comp_n = n - 4;
  double comp_sum = 0.0;
  for (int i = 4; i < n; ++i) {
    comp_sum += x[i];
  }
  double comp_mean = comp_sum / comp_n;
  
  double sum_sq = 0.0;
  for (int i = 4; i < n; ++i) {
    double diff = x[i] - comp_mean;
    sum_sq += diff * diff;
  }
  double comp_sd = sqrt(sum_sq / (comp_n - 1));
  
  return (comp_sd / (ref_mean / sqrt(comp_n))) * 100.0;
}
```

### 6.3 Vowel Space Functions

```cpp
#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Compute vowel space center
//' 
//' @param f1 F1 formant values
//' @param f2 F2 formant values
//' @param method "centroid", "twomeans", or "wcentroid"
//' @param na_rm Remove NA values?
//' @return List with f1c and f2c
//' @export
// [[Rcpp::export]]
List cpp_vowel_center(NumericVector f1, NumericVector f2,
                      std::string method = "wcentroid",
                      bool na_rm = true) {
  
  NumericVector f1_clean = clone(f1);
  NumericVector f2_clean = clone(f2);
  
  if (na_rm) {
    LogicalVector valid = !is_na(f1) & !is_na(f2);
    f1_clean = f1[valid];
    f2_clean = f2[valid];
  }
  
  int n = f1_clean.size();
  double f1c = 0.0, f2c = 0.0;
  
  if (method == "centroid") {
    f1c = mean(f1_clean);
    f2c = mean(f2_clean);
    
  } else if (method == "twomeans") {
    f1c = mean(f1_clean);
    
    // Split into upper and lower
    std::vector<double> f2_upper, f2_lower;
    for (int i = 0; i < n; ++i) {
      if (f1_clean[i] > f1c) {
        f2_upper.push_back(f2_clean[i]);
      } else {
        f2_lower.push_back(f2_clean[i]);
      }
    }
    
    double f2cH = 0.0, f2cL = 0.0;
    if (!f2_upper.empty()) {
      for (double val : f2_upper) f2cH += val;
      f2cH /= f2_upper.size();
    }
    if (!f2_lower.empty()) {
      for (double val : f2_lower) f2cL += val;
      f2cL /= f2_lower.size();
    }
    
    f2c = (f2cH + f2cL) / 2.0;
    
  } else if (method == "wcentroid") {
    f1c = mean(f1_clean);
    
    std::vector<double> f2_lower;
    for (int i = 0; i < n; ++i) {
      if (f1_clean[i] < f1c) {
        f2_lower.push_back(f2_clean[i]);
      }
    }
    
    if (!f2_lower.empty()) {
      for (double val : f2_lower) f2c += val;
      f2c /= f2_lower.size();
    }
  }
  
  return List::create(Named("f1c") = f1c,
                     Named("f2c") = f2c);
}

//' Compute vowel vector norms
//' 
//' @param f1 F1 formant values
//' @param f2 F2 formant values  
//' @param f1c F1 center
//' @param f2c F2 center
//' @return Vector of norms
//' @export
// [[Rcpp::export]]
NumericVector cpp_vowel_norms(NumericVector f1, NumericVector f2,
                               double f1c, double f2c) {
  int n = f1.size();
  NumericVector norms(n);
  
  for (int i = 0; i < n; ++i) {
    if (NumericVector::is_na(f1[i]) || NumericVector::is_na(f2[i])) {
      norms[i] = NA_REAL;
    } else {
      double df1 = f1[i] - f1c;
      double df2 = f2[i] - f2c;
      norms[i] = sqrt(df1 * df1 + df2 * df2);
    }
  }
  
  return norms;
}

//' Compute vowel vector angles
//' 
//' @param f1 F1 formant values
//' @param f2 F2 formant values
//' @param f1c F1 center  
//' @param f2c F2 center
//' @return Vector of angles (radians)
//' @export
// [[Rcpp::export]]
NumericVector cpp_vowel_angles(NumericVector f1, NumericVector f2,
                                double f1c, double f2c) {
  int n = f1.size();
  NumericVector angles(n);
  
  for (int i = 0; i < n; ++i) {
    if (NumericVector::is_na(f1[i]) || NumericVector::is_na(f2[i])) {
      angles[i] = NA_REAL;
    } else {
      double df1 = f1[i] - f1c;
      double df2 = f2[i] - f2c;
      angles[i] = atan2(df1, df2);
    }
  }
  
  return angles;
}
```

### 6.4 Sequence Analysis Functions

```cpp
//' Identify missing values
//' 
//' @param x Numeric or character vector
//' @param what_na Threshold for numeric or values for character
//' @return Logical vector
//' @export
// [[Rcpp::export]]
LogicalVector cpp_missing_vec_numeric(NumericVector x, double what_na = 0.0) {
  int n = x.size();
  LogicalVector result(n);
  
  for (int i = 0; i < n; ++i) {
    result[i] = (NumericVector::is_na(x[i]) || x[i] <= what_na);
  }
  
  return result;
}

//' Left changepoint (first transition)
//' 
//' @param x Numeric vector
//' @param what_na Missing value threshold
//' @return Index of first changepoint or NA
//' @export
// [[Rcpp::export]]
int cpp_left_changepoint(NumericVector x, double what_na = 0.0) {
  LogicalVector m = cpp_missing_vec_numeric(x, what_na);
  int n = m.size();
  
  if (n < 2) return NA_INTEGER;
  
  for (int i = 1; i < n; ++i) {
    if (m[i] != m[i-1]) {
      return i;  // R uses 1-based indexing
    }
  }
  
  return NA_INTEGER;
}

//' Right changepoint (last transition)
//' 
//' @param x Numeric vector
//' @param what_na Missing value threshold
//' @return Index of last changepoint or NA
//' @export
// [[Rcpp::export]]
int cpp_right_changepoint(NumericVector x, double what_na = 0.0) {
  LogicalVector m = cpp_missing_vec_numeric(x, what_na);
  int n = m.size();
  
  if (n < 2) return NA_INTEGER;
  
  int last_cp = NA_INTEGER;
  for (int i = 1; i < n; ++i) {
    if (m[i] != m[i-1]) {
      last_cp = i;
    }
  }
  
  return last_cp;
}
```

---

## 7. superassp Integration Examples

### 7.1 Track Processing Functions

```r
#' Compute vowel space metrics from formant tracks
#'
#' @param formant_track Output from trk_formant* functions
#' @param time_range Optional c(start, end) time in seconds
#' @param method VSA method: "basic", "density", "continuous"
#' @param ... Additional arguments passed to VSA functions
#' 
#' @return Named list of vowel space metrics
#' @export
vsa_from_formants <- function(formant_track, 
                              time_range = NULL,
                              method = c("basic", "density", "continuous"),
                              ...) {
  method <- match.arg(method)
  
  # Extract F1 and F2 from track
  # superassp tracks typically have time, F1, F2, F3, etc. columns
  if (!is.null(time_range)) {
    idx <- formant_track$time >= time_range[1] & 
           formant_track$time <= time_range[2]
    f1 <- formant_track$F1[idx]
    f2 <- formant_track$F2[idx]
  } else {
    f1 <- formant_track$F1
    f2 <- formant_track$F2
  }
  
  # Remove NA values
  valid <- !is.na(f1) & !is.na(f2)
  f1 <- f1[valid]
  f2 <- f2[valid]
  
  # Compute metrics based on method
  result <- list(
    n_vowels = length(f1),
    f1_range = range(f1),
    f2_range = range(f2)
  )
  
  if (method == "basic") {
    result$vsa <- VSA(f1, f2)
    result$center <- vowelspace.center(f1, f2)
    result$norms <- vowel.norms(f1, f2)
  } else if (method == "density") {
    result$vsd <- VSD(f2, f1, ...)
  } else if (method == "continuous") {
    result$cvsa <- cVSA(f2, f1, ...)
  }
  
  class(result) <- c("articulated_vsa", "list")
  return(result)
}

#' Compute rhythm metrics from intensity track
#'
#' @param intensity_track Output from trk_rmsana or trk_intensityp
#' @param threshold Intensity threshold for syllable detection (dB)
#' @param min_duration Minimum syllable duration (seconds)
#' @param ... Additional arguments
#' 
#' @return Named list of rhythm metrics
#' @export
rhythm_from_intensity <- function(intensity_track,
                                  threshold = -20,
                                  min_duration = 0.05,
                                  ...) {
  
  # Detect syllable-like units from intensity
  # Simple threshold-based segmentation
  above_threshold <- intensity_track$rms > threshold
  
  # Find runs (consecutive TRUE values)
  runs <- rle(above_threshold)
  
  # Extract durations of syllable-like segments
  durations <- numeric()
  cumsum_len <- cumsum(runs$lengths)
  
  for (i in seq_along(runs$lengths)) {
    if (runs$values[i]) {  # If above threshold
      start_idx <- if (i == 1) 1 else cumsum_len[i-1] + 1
      end_idx <- cumsum_len[i]
      
      duration <- intensity_track$time[end_idx] - 
                  intensity_track$time[start_idx]
      
      if (duration >= min_duration) {
        durations <- c(durations, duration)
      }
    }
  }
  
  # Compute rhythm metrics
  result <- list(
    n_syllables = length(durations),
    durations = durations,
    cov = COV(durations),
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
  
  class(result) <- c("articulated_rhythm", "list")
  return(result)
}

#' Combined articulation analysis from audio file
#'
#' @param audio_file Path to audio file
#' @param formant_method Formant extraction method
#' @param ... Additional arguments
#' 
#' @return Named list with both rhythm and vowel space metrics
#' @export
articulation_from_audio <- function(audio_file,
                                    formant_method = "formantp",
                                    ...) {
  
  # Extract formants
  formant_fn <- match.fun(paste0("trk_", formant_method))
  formants <- formant_fn(audio_file, ...)
  
  # Extract intensity  
  intensity <- trk_rmsana(audio_file, ...)
  
  # Compute metrics
  result <- list(
    file = audio_file,
    vowel_space = vsa_from_formants(formants, ...),
    rhythm = rhythm_from_intensity(intensity, ...)
  )
  
  class(result) <- c("articulated_analysis", "list")
  return(result)
}
```

### 7.2 List Feature Functions (lst_* style)

```r
#' Compute comprehensive articulation feature set
#'
#' Similar to lst_voice_reportp() but focused on articulation
#'
#' @param audio_file Path to audio file
#' @param formant_kwargs List of arguments for formant extraction
#' @param intensity_kwargs List of arguments for intensity extraction
#' @param return_tracks Return intermediate tracks?
#' 
#' @return Named list of articulation features
#' @export
lst_articulation <- function(audio_file,
                             formant_kwargs = list(),
                             intensity_kwargs = list(),
                             return_tracks = FALSE) {
  
  # Extract tracks
  formants <- do.call(trk_formantp, 
                     c(list(audio_file), formant_kwargs))
  intensity <- do.call(trk_rmsana,
                      c(list(audio_file), intensity_kwargs))
  
  # Compute metrics
  vsa_metrics <- vsa_from_formants(formants, method = "basic")
  vsd_metrics <- vsa_from_formants(formants, method = "density")
  rhythm_metrics <- rhythm_from_intensity(intensity)
  
  # Flatten into feature vector
  features <- list(
    # Vowel space features
    vsa = as.numeric(vsa_metrics$vsa),
    vsd = as.numeric(vsd_metrics$vsd),
    f1_center = vsa_metrics$center$f1,
    f2_center = vsa_metrics$center$f2,
    f1_range_min = vsa_metrics$f1_range[1],
    f1_range_max = vsa_metrics$f1_range[2],
    f2_range_min = vsa_metrics$f2_range[1],
    f2_range_max = vsa_metrics$f2_range[2],
    mean_vowel_norm = mean(vsa_metrics$norms, na.rm = TRUE),
    sd_vowel_norm = sd(vsa_metrics$norms, na.rm = TRUE),
    
    # Rhythm features
    n_syllables = rhythm_metrics$n_syllables,
    mean_syllable_duration = mean(rhythm_metrics$durations, na.rm = TRUE),
    sd_syllable_duration = sd(rhythm_metrics$durations, na.rm = TRUE),
    cov_syllable_duration = rhythm_metrics$cov,
    rpvi = rhythm_metrics$rpvi,
    npvi = rhythm_metrics$npvi
  )
  
  # Add optional features if enough syllables
  if (rhythm_metrics$n_syllables >= 20) {
    features$cov5_20 <- rhythm_metrics$cov5_20
    features$pa <- rhythm_metrics$pa
    features$relstab_5_12 <- rhythm_metrics$relstab_5_12
    features$relstab_13_20 <- rhythm_metrics$relstab_13_20
  }
  
  # Optionally include tracks
  if (return_tracks) {
    features$tracks <- list(
      formants = formants,
      intensity = intensity
    )
  }
  
  class(features) <- c("lst_articulation", "list")
  return(features)
}

#' Compute rhythm-only feature set
#'
#' @inheritParams lst_articulation
#' @export
lst_rhythm <- function(audio_file,
                       intensity_kwargs = list(),
                       return_tracks = FALSE) {
  
  intensity <- do.call(trk_rmsana,
                      c(list(audio_file), intensity_kwargs))
  
  rhythm_metrics <- rhythm_from_intensity(intensity)
  
  features <- list(
    n_syllables = rhythm_metrics$n_syllables,
    mean_duration = mean(rhythm_metrics$durations, na.rm = TRUE),
    sd_duration = sd(rhythm_metrics$durations, na.rm = TRUE),
    cov = rhythm_metrics$cov,
    rpvi = rhythm_metrics$rpvi,
    npvi = rhythm_metrics$npvi
  )
  
  if (rhythm_metrics$n_syllables >= 20) {
    features$cov5_20 <- rhythm_metrics$cov5_20
    features$pa <- rhythm_metrics$pa
    features$relstab_5_12 <- rhythm_metrics$relstab_5_12
    features$relstab_13_20 <- rhythm_metrics$relstab_13_20
  }
  
  if (return_tracks) {
    features$track <- intensity
  }
  
  class(features) <- c("lst_rhythm", "list")
  return(features)
}

#' Compute vowel space feature set
#'
#' @inheritParams lst_articulation  
#' @param methods Which VSA methods to include
#' @export
lst_vowelspace <- function(audio_file,
                          formant_kwargs = list(),
                          methods = c("basic", "density"),
                          return_tracks = FALSE) {
  
  formants <- do.call(trk_formantp,
                     c(list(audio_file), formant_kwargs))
  
  features <- list()
  
  if ("basic" %in% methods) {
    vsa_metrics <- vsa_from_formants(formants, method = "basic")
    features <- c(features, list(
      vsa = as.numeric(vsa_metrics$vsa),
      f1_center = vsa_metrics$center$f1,
      f2_center = vsa_metrics$center$f2,
      mean_vowel_norm = mean(vsa_metrics$norms, na.rm = TRUE),
      sd_vowel_norm = sd(vsa_metrics$norms, na.rm = TRUE)
    ))
  }
  
  if ("density" %in% methods) {
    vsd_metrics <- vsa_from_formants(formants, method = "density")
    features$vsd <- as.numeric(vsd_metrics$vsd)
  }
  
  if ("continuous" %in% methods) {
    cvsa_metrics <- vsa_from_formants(formants, method = "continuous")
    features$cvsa <- as.numeric(cvsa_metrics$cvsa)
  }
  
  if (return_tracks) {
    features$track <- formants
  }
  
  class(features) <- c("lst_vowelspace", "list")
  return(features)
}
```

### 7.3 Batch Processing Support

```r
#' Process multiple audio files
#'
#' @param audio_files Vector of audio file paths
#' @param feature_fn Feature extraction function (e.g., lst_articulation)
#' @param parallel Use parallel processing?
#' @param n_cores Number of cores for parallel processing
#' @param ... Arguments passed to feature_fn
#' 
#' @return Data frame with features for each file
#' @export
articulated_batch <- function(audio_files,
                              feature_fn = lst_articulation,
                              parallel = FALSE,
                              n_cores = parallel::detectCores() - 1,
                              ...) {
  
  if (parallel && requireNamespace("parallel", quietly = TRUE)) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl))
    
    results <- parallel::parLapply(cl, audio_files, function(f) {
      tryCatch(
        feature_fn(f, ...),
        error = function(e) {
          warning(paste("Error processing", f, ":", e$message))
          return(NULL)
        }
      )
    })
  } else {
    results <- lapply(audio_files, function(f) {
      tryCatch(
        feature_fn(f, ...),
        error = function(e) {
          warning(paste("Error processing", f, ":", e$message))
          return(NULL)
        }
      )
    })
  }
  
  # Convert to data frame
  valid_results <- results[!sapply(results, is.null)]
  
  df <- do.call(rbind, lapply(seq_along(valid_results), function(i) {
    feat <- valid_results[[i]]
    # Remove non-atomic elements (like tracks)
    feat <- feat[sapply(feat, function(x) is.atomic(x) && length(x) == 1)]
    data.frame(
      file = audio_files[i],
      as.data.frame(feat),
      stringsAsFactors = FALSE
    )
  }))
  
  return(df)
}
```

---

## 8. Performance Expectations

Based on typical Rcpp optimizations:

| Function | Current (R) | Optimized (Rcpp) | Speedup |
|----------|-------------|------------------|---------|
| COV() | 100 µs | 5 µs | ~20x |
| COV5_x() | 150 µs | 8 µs | ~19x |
| vector.space() | 50 ms | 2 ms | ~25x |
| vowel.norms() | 10 ms | 0.5 ms | ~20x |
| VSD() | 200 ms | 50 ms | ~4x |
| missing_vec() | 50 µs | 3 µs | ~17x |
| changepoint functions | 100 µs | 10 µs | ~10x |

*Estimates based on 1000 vowel measurements or 100 duration values*

---

## 9. Recommended File Structure

```
articulated/
├── R/
│   ├── articulated.R          # Package setup
│   ├── rhythm.R               # R wrappers for rhythm functions
│   ├── rhythm_track.R         # NEW: Track interface for rhythm
│   ├── vowelspace.R           # R wrappers for vowel space
│   ├── vowelspace_track.R     # NEW: Track interface for vowel space  
│   ├── sequence_analysis.R    # Refactored sequence analysis
│   ├── lst_functions.R        # NEW: lst_* style functions
│   ├── utils.R                # NEW: Shared utilities
│   └── RcppExports.R          # Auto-generated
├── src/
│   ├── RcppExports.cpp        # Auto-generated
│   ├── rhythm.cpp             # Rhythm Rcpp functions
│   ├── vowelspace.cpp         # NEW: Vowel space Rcpp functions
│   ├── sequence.cpp           # NEW: Sequence analysis Rcpp
│   └── utils.cpp              # NEW: Shared C++ utilities
├── inst/
│   └── examples/              # NEW: Example scripts
├── tests/
│   └── testthat/              # NEW: Unit tests
└── vignettes/
    ├── introduction.Rmd       # NEW: Basic usage
    ├── superassp_integration.Rmd  # NEW: Integration guide
    └── performance.Rmd        # NEW: Benchmarks
```

---

## 10. Migration Checklist

### Immediate Actions
- [ ] Remove or fix `fonetogram()` function
- [ ] Fix `sequence_analysis.R` circular dependency with superassp
- [ ] Add missing dependencies to DESCRIPTION
- [ ] Standardize parameter naming (na.rm vs omit)

### Rcpp Migration
- [ ] Implement `cpp_cov()` and `cpp_cov5_x()`
- [ ] Implement `cpp_vowel_center()`, `cpp_vowel_norms()`, `cpp_vowel_angles()`
- [ ] Implement `cpp_missing_vec()` and changepoint functions
- [ ] Create comprehensive vowel space Rcpp function
- [ ] Add error checking and validation to all Rcpp functions
- [ ] Update R wrappers to use new Rcpp functions

### superassp Integration
- [ ] Create `vsa_from_formants()` function
- [ ] Create `rhythm_from_intensity()` function
- [ ] Create `lst_articulation()` function
- [ ] Create `lst_rhythm()` function
- [ ] Create `lst_vowelspace()` function
- [ ] Create `articulated_batch()` function
- [ ] Write vignette with real audio examples

### Testing & Documentation
- [ ] Create unit tests for all functions
- [ ] Create integration tests with superassp
- [ ] Benchmark R vs Rcpp implementations
- [ ] Update all function documentation
- [ ] Add package-level documentation
- [ ] Create comprehensive vignettes

### Package Maintenance
- [ ] Set up CI/CD (GitHub Actions)
- [ ] Add code coverage reporting
- [ ] Create CONTRIBUTING.md
- [ ] Update NEWS.md with changes
- [ ] Bump version to 0.2.0

---

## 11. Conclusion

The `articulated` package has solid foundational functions for speech performance analysis, with some already optimized in Rcpp. The main opportunities for improvement are:

1. **Performance:** Migrate remaining bottleneck functions (vowel space, sequence analysis) to Rcpp for 10-100x speedup
2. **Integration:** Create seamless interfaces with superassp's track-based workflow
3. **Usability:** Develop high-level `lst_*` functions that process audio files end-to-end
4. **Reliability:** Fix critical bugs, add comprehensive tests, improve documentation

The proposed refactoring maintains backward compatibility while significantly improving performance and usability, especially for users already working with the superassp ecosystem.

