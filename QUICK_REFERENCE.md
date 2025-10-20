# Articulated Package - Quick Reference Guide

## 📋 Current Package Status

**Version:** 0.1.0 (July 2023)  
**Purpose:** Speech performance assessment (articulation errors, phonatory function)  
**Current state:** Functional but dated, mixed R/Rcpp implementation

---

## 🎯 Key Findings

### What's Working Well ✅
- Rhythm analysis functions (rPVI, nPVI, jitter metrics) - **Already in Rcpp**
- Solid theoretical foundation with published references
- Core algorithms are sound

### Critical Issues 🐛
1. **Broken code:** `fonetogram()` function has missing dependencies
2. **Circular dependency:** sequence_analysis.R calls `superassp::missing_vec()`
3. **Performance:** Major functions still in pure R (10-100x slower than Rcpp)
4. **Integration:** No built-in support for superassp workflows

---

## 📊 Functions by Performance Status

### 🚀 Already Fast (Rcpp)
```r
rPVI(x)                    # Raw PVI
nPVI(x)                    # Normalized PVI  
jitter_local(x, ...)       # Local jitter
jitter_rap(x, ...)         # RAP jitter
jitter_ppq5(x, ...)        # PPQ5 jitter
jitter_ddp(x, ...)         # DDP jitter
cppRelStab(x, ...)         # Internal helper
```

### 🐌 Needs Optimization (Pure R)
```r
COV(x)                     # ~20x speedup potential
COV5_x(x, n=20)           # ~19x speedup potential
vector.space(f1, f2)       # ~25x speedup potential
vowel.norms(f1, f2)        # ~20x speedup potential
vowel.angles(f1, f2)       # ~20x speedup potential
VSD(f2, f1)                # ~5-10x speedup potential
cVSA(f2, f1)               # ~2-5x speedup potential
VSA(f1, f2)                # ~3x speedup potential

# Sequence analysis (all ~10-15x potential)
missing_vec(x)
left_changepoint(x)
right_changepoint(x)
peak_prominence(x)
lm_slope(x)
```

---

## 🔧 Recommended Refactoring Priority

### P0: Fix Immediately (1-2 days)
- [ ] Remove or fix `fonetogram()` in voice_function_displays.R
- [ ] Fix circular dependency in sequence_analysis.R (line 18)
- [ ] Standardize parameter names (na.rm vs omit)
- [ ] Update DESCRIPTION with missing imports

### P1: Core Performance (3-4 days)
- [ ] Migrate COV(), COV5_x() to Rcpp → rhythm_extra.cpp
- [ ] Migrate vowel space functions to Rcpp → vowelspace.cpp
- [ ] Migrate sequence analysis to Rcpp → sequence.cpp

### P2: superassp Integration (3-5 days)
- [ ] Create vsa_from_formants() for track processing
- [ ] Create rhythm_from_intensity() for track processing
- [ ] Create lst_articulation() feature extraction
- [ ] Create articulated_batch() for parallel processing

### P3: Quality (4-5 days)
- [ ] Write unit tests (target >90% coverage)
- [ ] Create benchmarks comparing R vs Rcpp
- [ ] Write 4 comprehensive vignettes
- [ ] Set up CI/CD (GitHub Actions)

**Total estimated effort:** 4-6 weeks full-time

---

## 💡 Proposed superassp Integration

### Current Workflow (Manual)
```r
# User has to do everything manually
library(superassp)
formants <- trk_formantp("audio.wav")
f1 <- formants$F1[!is.na(formants$F1)]
f2 <- formants$F2[!is.na(formants$F2)]
vsa <- VSA(f1, f2)
```

### Proposed Workflow (Integrated)
```r
# Option 1: Direct from tracks
library(articulated)
library(superassp)
formants <- trk_formantp("audio.wav")
vsa_metrics <- vsa_from_formants(formants)

# Option 2: End-to-end pipeline (like lst_voice_reportp)
features <- lst_articulation("audio.wav")
# Returns flat list: vsa, f1_mean, f2_mean, rpvi, npvi, etc.

# Option 3: Batch processing
files <- list.files("audio/", pattern = "*.wav", full.names = TRUE)
results <- articulated_batch(files, lst_articulation, parallel = TRUE)
# Returns data frame ready for analysis
```

### Proposed Functions

**Track processing:**
- `vsa_from_formants(track, method = "basic")` → vowel space metrics
- `rhythm_from_intensity(track)` → rhythm metrics  
- `articulation_from_audio(file)` → complete analysis

**Feature extraction (lst_* style):**
- `lst_articulation(file)` → ~30 features (vowel space + rhythm)
- `lst_rhythm(file)` → ~15 rhythm features only
- `lst_vowelspace(file)` → ~10 vowel space features only

**Batch processing:**
- `articulated_batch(files, fn, parallel = TRUE)` → data frame

---

## 📈 Expected Performance Improvements

| Function | Current (µs) | After Rcpp (µs) | Speedup |
|----------|--------------|-----------------|---------|
| COV(1000) | 100 | 5 | 20x |
| COV5_x(100) | 150 | 8 | 19x |
| vowel.norms(1000) | 10000 | 500 | 20x |
| vector.space(1000) | 50000 | 2000 | 25x |
| VSD(1000) | 200000 | 50000 | 4x |
| missing_vec(1000) | 50 | 3 | 17x |

**Real-world impact:**
- Single file analysis: 5-10 seconds → 0.5-1 second
- Batch of 1000 files: 90 minutes → 10 minutes (with parallelization)

---

## 📦 Files Created/Modified in Refactoring

### New Rcpp Source Files
```
src/rhythm_extra.cpp       # COV functions
src/vowelspace.cpp         # Vowel space functions  
src/sequence.cpp           # Sequence analysis functions
```

### New R Files
```
R/superassp_integration.R  # Track processing functions
R/lst_functions.R          # Feature extraction (lst_* style)
R/batch_processing.R       # Batch workflows
R/articulated-package.R    # Package documentation
```

### Modified R Files
```
R/rythm.R                  # Use new Rcpp COV functions
R/vfd.R                    # Use new Rcpp vowel functions
R/sequence_analysis.R      # Use new Rcpp, fix bugs
R/voice_function_displays.R # Fix or remove fonetogram()
```

### New Tests
```
tests/testthat/test-cov.R
tests/testthat/test-rhythm.R
tests/testthat/test-vowelspace.R
tests/testthat/test-sequence.R
tests/testthat/test-integration.R
tests/testthat/test-lst.R
```

### New Documentation
```
vignettes/introduction.Rmd
vignettes/superassp-integration.Rmd
vignettes/rhythm-analysis.Rmd
vignettes/vowel-space.Rmd
vignettes/benchmarks.Rmd
```

---

## 🚀 Quick Start (After Refactoring)

### Installation
```r
# From GitHub
devtools::install_github("username/articulated")

# With superassp integration
install.packages("superassp")
library(articulated)
library(superassp)
```

### Basic Usage
```r
# Analyze single file
features <- lst_articulation("speech.wav")
print(features$vsa)
print(features$rpvi)

# Batch analysis
files <- list.files("data/", pattern = "*.wav", full.names = TRUE)
results <- articulated_batch(files, lst_articulation, parallel = TRUE)
write.csv(results, "articulation_features.csv")

# Work with existing tracks
formants <- trk_formantp("speech.wav")
intensity <- trk_rmsana("speech.wav")

vsa_metrics <- vsa_from_formants(formants, method = "density")
rhythm_metrics <- rhythm_from_intensity(intensity)
```

### Advanced Usage
```r
# Custom time windowing
formants <- trk_formantp("speech.wav")
vowels_early <- vsa_from_formants(formants, time_range = c(0, 5))
vowels_late <- vsa_from_formants(formants, time_range = c(5, 10))

# Compare methods
vsa_basic <- vsa_from_formants(formants, method = "basic")
vsa_density <- vsa_from_formants(formants, method = "density")
vsa_continuous <- vsa_from_formants(formants, method = "continuous")

# Manual rhythm analysis
durations <- c(0.12, 0.15, 0.13, 0.14, ...) # Your syllable durations
metrics <- list(
  cov = COV(durations),
  rpvi = rPVI(durations),
  npvi = nPVI(durations),
  pa = PA(durations),
  relstab_5_12 = relstab(durations, kind = "5_12")
)
```

---

## 📚 Key References

### Rhythm Metrics
- **PVI:** Nolan & Asu (2009). Phonetica, 66(1-2), 64-77
- **COV5_x, relstab:** Skodda et al. (2012). Basal Ganglia, 3(1), 33-37
- **PA:** Flasskamp et al. (2010). J Neural Transmission, 117(5), 605-612

### Vowel Space Metrics
- **VSA:** Karlsson & van Doorn (2012). JASA, 132(4), 2633-2641
- **VSD:** Story (2017). JASA, doi:10.1121/1.4983342
- **cVSA:** Sandoval et al. (2013). JASA, doi:10.1121/1.4826150

---

## 🔍 Common Use Cases

### Clinical Assessment
```r
# Compare patient vs control
patient_features <- lst_articulation("patient.wav")
control_features <- lst_articulation("control.wav")

# Focus on DDK metrics
compare_ddk <- function(p, c) {
  data.frame(
    metric = c("COV5_20", "PA", "relstab_5_12"),
    patient = c(p$cov5_20, p$pa, p$relstab_5_12),
    control = c(c$cov5_20, c$pa, c$relstab_5_12)
  )
}
```

### Longitudinal Studies
```r
# Process multiple sessions
sessions <- c("baseline.wav", "month1.wav", "month3.wav", "month6.wav")
results <- articulated_batch(sessions, lst_articulation)
results$session <- c("baseline", "month1", "month3", "month6")

# Plot trajectory
library(ggplot2)
ggplot(results, aes(x = session, y = vsa, group = 1)) +
  geom_line() + geom_point() +
  labs(title = "VSA over time")
```

### Research Pipelines
```r
# Integration with statistical analysis
library(dplyr)

# Extract features from all participants
features <- articulated_batch(audio_files, lst_articulation, parallel = TRUE)

# Add metadata
features <- features %>%
  mutate(
    participant_id = str_extract(file, "P\\d+"),
    condition = str_extract(file, "control|patient")
  )

# Statistical comparison
library(lme4)
model <- lmer(vsa ~ condition + (1|participant_id), data = features)
summary(model)
```

---

## 🤝 Contributing

### Development Setup
```bash
git clone https://github.com/username/articulated.git
cd articulated
```

```r
# Install dev dependencies
install.packages(c("devtools", "roxygen2", "testthat"))

# Build and test
devtools::document()
devtools::test()
devtools::check()
```

### Adding New Features
1. Write function in appropriate R/ file
2. Add Rcpp implementation if performance-critical
3. Write tests in tests/testthat/
4. Add examples and documentation
5. Update NEWS.md
6. Submit pull request

### Reporting Issues
- Use GitHub issues
- Include minimal reproducible example
- Specify R version, OS, package version
- Attach sample audio if relevant (anonymized)

---

## 📞 Support

**Documentation:**
- Package help: `?articulated`, `?lst_articulation`
- Vignettes: `vignette("superassp-integration")`
- GitHub: https://github.com/username/articulated

**Getting Help:**
- GitHub issues for bugs/features
- Email maintainer for questions
- Stack Overflow tag: `[r] [articulated]`

**Citation:**
```
Karlsson, F. (2023). articulated: Speech Performance Assessment.
R package version 0.2.0. https://github.com/username/articulated
```

---

## ✅ Implementation Checklist

### Phase 1: Critical Fixes
- [ ] Fix fonetogram() or remove it
- [ ] Fix sequence_analysis.R circular dependency
- [ ] Standardize parameter names
- [ ] Update DESCRIPTION

### Phase 2: Rcpp Migration
- [ ] Implement cpp_cov() and cpp_cov5_x()
- [ ] Implement cpp_vowel_* functions
- [ ] Implement cpp_sequence_* functions
- [ ] Update R wrappers

### Phase 3: Integration
- [ ] Create vsa_from_formants()
- [ ] Create rhythm_from_intensity()
- [ ] Create lst_articulation()
- [ ] Create articulated_batch()

### Phase 4: Quality
- [ ] Write unit tests (>90% coverage)
- [ ] Create benchmarks
- [ ] Write vignettes
- [ ] Set up CI/CD

### Phase 5: Release
- [ ] Update NEWS.md
- [ ] Update README.md
- [ ] Create CITATION file
- [ ] Tag release v0.2.0
- [ ] Submit to CRAN (optional)

---

**Last Updated:** October 2025  
**Status:** Planning/Proposal Phase  
**Next Step:** Review assessment and begin Phase 1 fixes
