#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Coefficient of Variation (Rcpp implementation)
//' 
//' Computes the coefficient of variation (sd/mean) for a numeric vector.
//' This is a high-performance replacement for the pure R version.
//' 
//' @param x Numeric vector
//' @param na_rm Should NA values be removed? Default TRUE
//' @return Coefficient of variation or NA
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c(1.2, 1.5, 1.3, 1.4, 1.6)
//' cpp_cov(x)
// [[Rcpp::export]]
double cpp_cov(NumericVector x, bool na_rm = true) {
  if (na_rm) {
    x = x[!is_na(x)];
  }
  
  int n = x.size();
  if (n == 0) return R_NaReal;
  if (n == 1) return R_NaReal;  // Cannot compute SD with one value
  
  double sum = 0.0;
  for (int i = 0; i < n; ++i) {
    if (NumericVector::is_na(x[i])) return R_NaReal;
    sum += x[i];
  }
  double mean = sum / n;
  
  double sum_sq = 0.0;
  for (int i = 0; i < n; ++i) {
    double diff = x[i] - mean;
    sum_sq += diff * diff;
  }
  double sd = sqrt(sum_sq / (n - 1));
  
  if (mean == 0.0) return R_NaReal;  // Avoid division by zero
  
  return sd / mean;
}


//' Relative Coefficient of Variation (intervals 5-n vs 1-4)
//' 
//' Computes the coefficient of variance for intervals 5-n relative to 
//' the mean duration of intervals 1-4, as described in Skodda et al. (2012).
//' 
//' @param x Vector of syllable durations
//' @param n Number of intervals to include (default 20)
//' @param return_na Return NA if insufficient data? (default TRUE)
//' @param na_rm Remove NA values before computation? (default TRUE)
//' @return Relative COV or NA
//' @author Fredrik Karlsson
//' @export
//' @references
//' Skodda, S., Lorenz, J., & Schlegel, U. (2012). Instability of syllable 
//' repetition in Parkinson's disease. Basal Ganglia, 3(1), 33-37.
//' @examples
//' durations <- runif(25, 0.1, 0.3)
//' cpp_cov5_x(durations)
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
      stop("Vector length must be at least " + std::to_string(n));
    }
  }
  
  // Mean of first 4 intervals (reference)
  double ref_sum = 0.0;
  for (int i = 0; i < 4; ++i) {
    ref_sum += x[i];
  }
  double ref_mean = ref_sum / 4.0;
  
  // SD of intervals 5 to n (comparison)
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
  
  // Formula from original implementation
  return (comp_sd / (ref_mean / sqrt(comp_n))) * 100.0;
}
