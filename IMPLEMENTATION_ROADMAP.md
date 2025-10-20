# Articulated Package - Implementation Roadmap

## Quick Summary

The `articulated` package provides speech performance assessment functions. This roadmap outlines refactoring priorities for:
1. **Performance:** Migrating key functions to Rcpp (10-100x speedup)
2. **Integration:** Seamless workflow with superassp's `trk_*` and `lst_*` functions
3. **Quality:** Fixing bugs, adding tests, improving documentation

---

## Current State Analysis

### ✅ Already Optimized (Rcpp)
- `rPVI()`, `nPVI()` - Rhythm variability indices
- `jitter_local()`, `jitter_ddp()`, `jitter_rap()`, `jitter_ppq5()` - Jitter metrics
- `cppRelStab()` - Relative stability (internal)

### ⚠️ Performance Bottlenecks (Pure R)
- `COV()`, `COV5_x()` - Coefficient of variation (~20x speedup potential)
- `vector.space()` - Complex vowel space analysis (~25x speedup)
- `vowel.norms()`, `vowel.angles()` - Trigonometric operations (~20x speedup)
- `VSD()` - Distance matrix computation (~5-20x speedup)
- `sequence_analysis.R` functions - All pure R (~10x speedup)

### 🐛 Critical Bugs
1. **voice_function_displays.R:** `fonetogram()` missing dependencies (magrittr, dplyr, ggplot2, wrassp)
2. **sequence_analysis.R:** Circular dependency with superassp (line 18)
3. **Inconsistent parameter naming:** Mix of `na.rm` and `omit` parameters

---

## Implementation Priority Matrix

| Priority | Component | Impact | Effort | Files to Create/Modify |
|----------|-----------|--------|--------|------------------------|
| **P0** | Fix critical bugs | High | Low | sequence_analysis.R, vfd.R, DESCRIPTION |
| **P1** | Rcpp: COV functions | High | Low | src/rhythm_extra.cpp, R/rythm.R |
| **P2** | Rcpp: Vowel space | High | Medium | src/vowelspace.cpp, R/vfd.R |
| **P3** | Rcpp: Sequence analysis | Medium | Low | src/sequence.cpp, R/sequence_analysis.R |
| **P4** | superassp integration | High | Medium | R/superassp_integration.R |
| **P5** | lst_* functions | High | Medium | R/lst_functions.R |
| **P6** | Tests & benchmarks | Medium | High | tests/testthat/*.R |
| **P7** | Documentation | Medium | Medium | vignettes/*.Rmd |

---

## Detailed Implementation Plan

### Phase 1: Critical Fixes (Week 1, 1-2 days)

**Goal:** Package builds and passes R CMD check

1. **Fix sequence_analysis.R circular dependency**
   ```r
   # Current (line 18):
   isNA <- superassp::missing_vec(x, what.na=what.na)
   
   # Fix: Use local function
   isNA <- missing_vec(x, what.na=what.na)
   ```

2. **Fix or remove voice_function_displays.R**
   - Option A: Remove `fonetogram()` entirely (deprecated/incomplete)
   - Option B: Add dependencies (wrassp, dplyr, ggplot2, ggforce) and fix imports

3. **Standardize parameter names**
   - Choose either `na.rm` (R convention) or `omit` (current Rcpp)
   - Recommend: Use `na.rm` everywhere for consistency with base R

4. **Update DESCRIPTION**
   - Add missing imports if keeping `fonetogram()`
   - Remove circular superassp dependency

**Deliverables:**
- Package passes `R CMD check` without errors
- All existing tests pass
- Updated DESCRIPTION

---

### Phase 2: Core Rcpp Functions (Week 1-2, 3-4 days)

**Goal:** Migrate performance-critical functions to Rcpp

#### 2.1 Rhythm Functions

**File:** `src/rhythm_extra.cpp` (new)

```cpp
// Functions to implement:
- cpp_cov()           // Simple COV
- cpp_cov5_x()        // Relative COV for DDK tasks
```

**File:** `R/rythm.R` (modify)

```r
# Update wrappers to use Rcpp:
COV <- function(x, na.rm = TRUE) {
  cpp_cov(x, na_rm = na.rm)
}

COV5_x <- function(x, n = 20, return.na = TRUE, na.rm = TRUE) {
  cpp_cov5_x(x, n = n, return_na = return.na, na_rm = na.rm)
}

# Keep PA() and relstab() as-is (already use Rcpp internally)
```

**Expected speedup:** 15-20x for COV operations

#### 2.2 Vowel Space Functions

**File:** `src/vowelspace.cpp` (new)

```cpp
// Functions to implement:
- cpp_vowel_center()     // Center computation (3 methods)
- cpp_vowel_norms()      // Vector norms
- cpp_vowel_angles()     // Vector angles
- cpp_euclidean_dist()   // Distance matrix for VSD
- cpp_count_within_radius() // Density computation for VSD
```

**File:** `R/vfd.R` (modify)

```r
# Update functions to use Rcpp where beneficial:
vowel.norms <- function(f1, f2, na.rm = TRUE, center = NULL, 
                        center.method = "wcentroid") {
  if (is.null(center)) {
    center <- cpp_vowel_center(f1, f2, method = center.method, na_rm = na.rm)
    # Returns list(f1c, f2c) directly
  }
  cpp_vowel_norms(f1, f2, center$f1c, center$f2c)
}

# Similar updates for vowel.angles(), vowelspace.center()
# VSD() can use cpp_count_within_radius() instead of apply()
```

**Expected speedup:** 20-30x for norm/angle computations, 5-10x for VSD

#### 2.3 Sequence Analysis Functions

**File:** `src/sequence.cpp` (new)

```cpp
// Functions to implement:
- cpp_missing_vec_numeric()
- cpp_missing_vec_character()
- cpp_missing_frac()
- cpp_left_changepoint()
- cpp_right_changepoint()
- cpp_lm_slope()
- cpp_peak_prominence()
```

**File:** `R/sequence_analysis.R` (refactor)

```r
# Replace pure R implementations with Rcpp calls:
missing_vec <- function(x, what.na = 0) {
  if (is.numeric(what.na)) {
    cpp_missing_vec_numeric(x, what.na)
  } else {
    cpp_missing_vec_character(x, what.na)
  }
}

left_changepoint <- function(x, what.na = 0) {
  cpp_left_changepoint(x, what.na)
}

# etc.
```

**Expected speedup:** 10-15x for sequence operations

**Deliverables:**
- New Rcpp source files with comprehensive documentation
- Updated R wrappers maintaining backward compatibility
- Roxygen documentation for all new functions

---

### Phase 3: superassp Integration (Week 2-3, 3-5 days)

**Goal:** Seamless workflow with superassp package

#### 3.1 Track Processing Functions

**File:** `R/superassp_integration.R` (new)

**Functions to implement:**

```r
vsa_from_formants(formant_track, ...)
  # Input: superassp trk_formantp() output
  # Output: List of vowel space metrics
  # Handles: Time windowing, NA filtering, center computation

rhythm_from_intensity(intensity_track, ...)
  # Input: superassp trk_rmsana() output
  # Output: List of rhythm metrics
  # Handles: Syllable detection, duration extraction

articulation_from_audio(audio_file, ...)
  # Input: Audio file path
  # Output: Combined vowel space + rhythm analysis
  # Calls: Both formant and intensity extraction
```

**Key design decisions:**
- Accept both track objects and raw vectors (flexibility)
- Return structured lists with consistent naming
- Include diagnostic info (n_vowels, n_syllables, warnings)
- Support time windowing for longitudinal studies

#### 3.2 List Feature Functions (lst_* style)

**File:** `R/lst_functions.R` (new)

**Functions to implement:**

```r
lst_articulation(audio_file, ...)
  # Returns: Flat list of ~20-30 features
  # Compatible with: as.data.frame() for analysis
  # Similar to: superassp::lst_voice_reportp()

lst_rhythm(audio_file, ...)
  # Returns: Rhythm features only
  # Faster than full articulation analysis

lst_vowelspace(audio_file, methods = c("basic", "density"), ...)
  # Returns: VSA features using specified methods
  # Options: "basic", "density", "continuous"
```

**Design principles:**
1. Flat structure - all elements are atomic (length-1 vectors)
2. Consistent naming - feature names are descriptive and unique
3. Missing data handling - NA for features that can't be computed
4. Metadata - include n_vowels, n_syllables for quality assessment

#### 3.3 Batch Processing

**File:** `R/batch_processing.R` (new)

```r
articulated_batch(audio_files, feature_fn = lst_articulation, 
                  parallel = TRUE, ...)
  # Process multiple files in parallel
  # Return: Data frame with one row per file
  # Error handling: Continue on failure, log warnings
```

**Deliverables:**
- Integration functions with comprehensive examples
- Vignette: "Integration with superassp" showing real workflows
- Example audio files in `inst/extdata/` (or use superassp's)

---

### Phase 4: Testing & Quality (Week 3-4, 4-5 days)

**Goal:** Comprehensive test coverage and benchmarks

#### 4.1 Unit Tests

**Directory:** `tests/testthat/` (new)

**Test files to create:**

```
test-cov.R              # COV, COV5_x
test-rhythm.R           # rPVI, nPVI, jitter functions
test-vowelspace.R       # All vowel space functions
test-sequence.R         # Sequence analysis functions
test-integration.R      # superassp integration
test-lst.R              # lst_* functions
test-batch.R            # Batch processing
```

**Test coverage goals:**
- Edge cases: Empty vectors, single values, all NA
- Numeric accuracy: Compare with known values
- Parameter validation: Invalid inputs raise errors
- Backward compatibility: Results match old implementation
- Performance: Rcpp faster than pure R

#### 4.2 Benchmarks

**File:** `vignettes/benchmarks.Rmd` (new)

**Benchmark comparisons:**
```r
library(microbenchmark)
library(ggplot2)

# COV functions
x <- runif(1000)
microbenchmark(
  R_version = sd(x) / mean(x),
  Rcpp_version = cpp_cov(x),
  times = 1000
)

# Vowel space (1000 vowels)
f1 <- runif(1000, 300, 900)
f2 <- runif(1000, 800, 2500)
microbenchmark(
  R_norms = vowel.norms_old(f1, f2),
  Rcpp_norms = vowel.norms(f1, f2),
  times = 100
)
```

**Deliverables:**
- 100+ unit tests with >90% code coverage
- Benchmark vignette showing 10-100x speedups
- CI/CD setup (GitHub Actions) running checks on commit

---

### Phase 5: Documentation (Week 4, 2-3 days)

**Goal:** Clear, comprehensive documentation

#### 5.1 Function Documentation

**Update all .R files:**
- Complete Roxygen2 documentation for all exported functions
- Add `@examples` to every user-facing function
- Include `@references` for published algorithms
- Add `@seealso` cross-references

#### 5.2 Vignettes

**File:** `vignettes/introduction.Rmd`
```
- Installation and setup
- Basic usage examples
- Interpretation of metrics
```

**File:** `vignettes/superassp-integration.Rmd`
```
- Workflow with superassp
- Processing formant tracks
- Batch processing pipelines
- Real data example
```

**File:** `vignettes/rhythm-analysis.Rmd`
```
- DDK task analysis
- Interpretation of COV5_x, PA, relstab
- Clinical applications
```

**File:** `vignettes/vowel-space.Rmd`
```
- VSA, VSD, cVSA comparison
- When to use each method
- Normalization considerations
```

#### 5.3 Package Documentation

**File:** `R/articulated-package.R` (new)
```r
#' articulated: Speech Performance Assessment
#'
#' Functions for assessing articulation errors and phonatory function
#' from acoustic data, with emphasis on diadochokinetic (DDK) tasks
#' and vowel space analysis.
#'
#' @section Main function groups:
#' 
#' **Rhythm Analysis:**
#' - COV, COV5_x, PA, relstab: DDK task metrics
#' - rPVI, nPVI: Rhythm variability
#' - jitter_*: Jitter metrics
#' 
#' **Vowel Space Analysis:**
#' - VSA, VSD, cVSA: Vowel space area
#' - vowel.norms, vowel.angles: Individual vowel metrics
#' 
#' **Integration Functions:**
#' - vsa_from_formants: Process superassp tracks
#' - lst_articulation: Feature extraction pipeline
#' 
#' @docType package
#' @name articulated
NULL
```

**Deliverables:**
- 4+ comprehensive vignettes
- Updated README.md with installation and quick start
- NEWS.md documenting all changes
- CITATION file for academic use

---

## File Structure After Refactoring

```
articulated/
├── DESCRIPTION              # Updated dependencies
├── NAMESPACE                # Updated exports
├── NEWS.md                  # NEW: Version history
├── README.md                # Updated with examples
├── CITATION                 # NEW: How to cite
├── R/
│   ├── articulated.R        # Package setup (unchanged)
│   ├── articulated-package.R # NEW: Package documentation
│   ├── rythm.R              # MODIFIED: Use new Rcpp functions
│   ├── vfd.R                # MODIFIED: Use new Rcpp functions
│   ├── sequence_analysis.R  # REFACTORED: Use Rcpp, fix bugs
│   ├── voice_function_displays.R # FIXED or REMOVED
│   ├── superassp_integration.R # NEW: Track processing
│   ├── lst_functions.R      # NEW: Feature extraction
│   ├── batch_processing.R   # NEW: Batch workflows
│   ├── utils.R              # NEW: Shared utilities
│   └── RcppExports.R        # Auto-generated
├── src/
│   ├── rythm.cpp            # Existing jitter/PVI functions
│   ├── rhythm_extra.cpp     # NEW: COV functions
│   ├── vowelspace.cpp       # NEW: Vowel space functions
│   ├── sequence.cpp         # NEW: Sequence analysis
│   └── RcppExports.cpp      # Auto-generated
├── tests/
│   └── testthat/
│       ├── test-cov.R       # NEW
│       ├── test-rhythm.R    # NEW
│       ├── test-vowelspace.R # NEW
│       ├── test-sequence.R  # NEW
│       ├── test-integration.R # NEW
│       └── test-lst.R       # NEW
├── vignettes/
│   ├── introduction.Rmd     # NEW
│   ├── superassp-integration.Rmd # NEW
│   ├── rhythm-analysis.Rmd  # NEW
│   ├── vowel-space.Rmd      # NEW
│   └── benchmarks.Rmd       # NEW
├── inst/
│   ├── extdata/             # NEW: Example audio files
│   └── CITATION             # NEW
└── man/                     # Updated documentation
```

---

## Success Metrics

### Performance
- [ ] COV functions: >15x faster than pure R
- [ ] Vowel space functions: >20x faster
- [ ] Sequence analysis: >10x faster
- [ ] Overall pipeline: Process 1000 audio files in <10 minutes (parallelized)

### Integration
- [ ] All superassp `trk_*` outputs work with integration functions
- [ ] `lst_*` functions return same structure as superassp
- [ ] Batch processing supports parallel execution
- [ ] Example workflow processes real data end-to-end

### Quality
- [ ] Test coverage >90%
- [ ] Zero errors/warnings from `R CMD check`
- [ ] All functions have examples that run
- [ ] 4+ vignettes with working code
- [ ] Cited in at least 2 publications (longer term)

---

## Maintenance Plan

### Short-term (3 months)
- Monitor GitHub issues
- Fix bugs reported by users
- Add requested features to backlog
- Respond to questions within 48 hours

### Medium-term (6-12 months)
- Add support for new superassp track types
- Implement additional rhythm metrics from literature
- Create GUI or Shiny app for non-R users
- Submit to CRAN (if not already)

### Long-term (1-2 years)
- Integration with other speech analysis packages (e.g., phonR, emuR)
- Machine learning models for clinical classification
- Longitudinal analysis tools
- Mobile/web deployment

---

## Getting Started (For Developers)

### Prerequisites
```r
# Install development tools
install.packages(c("devtools", "roxygen2", "testthat", "knitr"))

# Install dependencies
install.packages(c("Rcpp", "geometry", "ClusterR", "Rfast", "units"))

# Optional: Install superassp for integration
install.packages("superassp")
```

### Build and Test
```bash
cd articulated/

# Generate documentation
Rscript -e "devtools::document()"

# Run tests
Rscript -e "devtools::test()"

# Check package
Rscript -e "devtools::check()"

# Build package
R CMD build .

# Install locally
R CMD INSTALL articulated_0.2.0.tar.gz
```

### Contribution Workflow
1. Create branch: `git checkout -b feature/your-feature`
2. Make changes with tests
3. Run `devtools::check()` - must pass with 0 errors/warnings
4. Update NEWS.md
5. Submit pull request with description
6. Code review and merge

---

## Questions & Next Steps

**For package author:**

1. **Priority confirmation:** Does this roadmap match your priorities?
2. **superassp dependency:** Should articulated formally depend on superassp, or keep it as suggested?
3. **voice_function_displays.R:** Keep and fix, or remove entirely?
4. **Naming conventions:** Standardize on snake_case or keep current mix?
5. **Version number:** Bump to 0.2.0 or 1.0.0 after refactoring?

**Recommended immediate actions:**

1. Review `REFACTORING_ASSESSMENT.md` for detailed analysis
2. Try proposed Rcpp implementations in `src/proposed_*.cpp`
3. Test integration code with real superassp tracks
4. Decide on Phase 1 fixes (critical bugs)
5. Set up GitHub issues for tracking

**Resources provided:**

- `REFACTORING_ASSESSMENT.md` - Comprehensive assessment (30+ pages)
- `src/proposed_vowelspace.cpp` - Example Rcpp implementations
- `src/proposed_sequence.cpp` - More Rcpp examples
- `R/proposed_superassp_integration.R` - Integration functions
- This roadmap - Step-by-step implementation plan

---

## Contact & Support

For questions about this refactoring plan:
- Create GitHub issue with tag `refactoring`
- Email package maintainer
- Review provided example code and documentation

**Estimated total effort:** 4-6 weeks full-time (or 2-3 months part-time)

**Expected outcome:** Modern, fast, well-documented package fully integrated with superassp ecosystem
