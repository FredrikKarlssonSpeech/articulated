#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Identify missing or invalid values in numeric vector
//' 
//' Identifies values that are NA, NULL, or below/equal to a threshold.
//' 
//' @param x Numeric vector
//' @param what_na Threshold value (values <= this are considered missing)
//' @return Logical vector indicating missing values
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c(1.2, 0, 1.5, NA, -1, 2.0)
//' cpp_missing_vec_numeric(x, what_na = 0)
// [[Rcpp::export]]
LogicalVector cpp_missing_vec_numeric(NumericVector x, double what_na = 0.0) {
  int n = x.size();
  LogicalVector result(n);
  
  for (int i = 0; i < n; ++i) {
    result[i] = (NumericVector::is_na(x[i]) || x[i] <= what_na);
  }
  
  return result;
}


//' Identify missing or invalid values in character vector
//' 
//' Identifies values that are NA or match specified strings.
//' 
//' @param x Character vector
//' @param what_na Character vector of values to consider missing
//' @return Logical vector indicating missing values
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c("a", "missing", "b", NA, "c")
//' cpp_missing_vec_character(x, c("missing", ""))
// [[Rcpp::export]]
LogicalVector cpp_missing_vec_character(CharacterVector x, 
                                         CharacterVector what_na) {
  int n = x.size();
  int n_na = what_na.size();
  LogicalVector result(n);
  
  for (int i = 0; i < n; ++i) {
    bool is_missing = CharacterVector::is_na(x[i]);
    
    if (!is_missing) {
      for (int j = 0; j < n_na; ++j) {
        if (x[i] == what_na[j]) {
          is_missing = true;
          break;
        }
      }
    }
    
    result[i] = is_missing;
  }
  
  return result;
}


//' Compute fraction of missing values
//' 
//' Calculates the proportion of values that are missing or invalid.
//' 
//' @param x Numeric vector
//' @param what_na Threshold for missing values
//' @return Fraction of missing values (0 to 1)
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c(1.2, 0, 1.5, NA, -1, 2.0)
//' cpp_missing_frac(x)
// [[Rcpp::export]]
double cpp_missing_frac(NumericVector x, double what_na = 0.0) {
  LogicalVector is_missing = cpp_missing_vec_numeric(x, what_na);
  int n = is_missing.size();
  
  if (n == 0) return R_NaReal;
  
  int count = 0;
  for (int i = 0; i < n; ++i) {
    if (is_missing[i]) count++;
  }
  
  return (double)count / n;
}


//' Find first changepoint in missing value pattern
//' 
//' Identifies the index of the first transition between missing and 
//' non-missing values (or vice versa).
//' 
//' @param x Numeric vector
//' @param what_na Threshold for missing values
//' @return Index of first changepoint (1-based) or NA if no changepoint
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c(0, 0, 1.2, 1.5, 2.0)
//' cpp_left_changepoint(x)  # Returns 3
// [[Rcpp::export]]
int cpp_left_changepoint(NumericVector x, double what_na = 0.0) {
  LogicalVector m = cpp_missing_vec_numeric(x, what_na);
  int n = m.size();
  
  if (n < 2) return NA_INTEGER;
  
  for (int i = 1; i < n; ++i) {
    if (m[i] != m[i-1]) {
      return i + 1;  // R uses 1-based indexing
    }
  }
  
  return NA_INTEGER;
}


//' Find last changepoint in missing value pattern
//' 
//' Identifies the index of the last transition between missing and
//' non-missing values (or vice versa).
//' 
//' @param x Numeric vector
//' @param what_na Threshold for missing values
//' @return Index of last changepoint (1-based) or NA if no changepoint
//' @author Fredrik Karlsson
//' @export
//' @examples
//' x <- c(0, 0, 1.2, 1.5, 0, 0)
//' cpp_right_changepoint(x)  # Returns 5
// [[Rcpp::export]]
int cpp_right_changepoint(NumericVector x, double what_na = 0.0) {
  LogicalVector m = cpp_missing_vec_numeric(x, what_na);
  int n = m.size();
  
  if (n < 2) return NA_INTEGER;
  
  int last_cp = NA_INTEGER;
  for (int i = 1; i < n; ++i) {
    if (m[i] != m[i-1]) {
      last_cp = i + 1;  // R uses 1-based indexing
    }
  }
  
  return last_cp;
}


//' Compute slope of linear regression
//' 
//' Fits a simple linear regression y ~ x and returns the slope coefficient.
//' NA values are automatically removed.
//' 
//' @param y Response vector
//' @param what_na Threshold for missing values
//' @return Slope coefficient or NA if insufficient data
//' @author Fredrik Karlsson
//' @export
//' @examples
//' y <- c(1.0, 1.5, 2.0, 2.3, 3.0)
//' cpp_lm_slope(y)
// [[Rcpp::export]]
double cpp_lm_slope(NumericVector y, double what_na = 0.0) {
  // Remove NA and missing values
  LogicalVector valid = !cpp_missing_vec_numeric(y, what_na);
  NumericVector y_clean;
  std::vector<double> x_clean;
  
  for (int i = 0; i < y.size(); ++i) {
    if (valid[i]) {
      y_clean.push_back(y[i]);
      x_clean.push_back(i + 1);  // 1-based like seq_along in R
    }
  }
  
  int n = y_clean.size();
  if (n < 2) return R_NaReal;
  
  // Compute means
  double sum_x = 0.0, sum_y = 0.0;
  for (int i = 0; i < n; ++i) {
    sum_x += x_clean[i];
    sum_y += y_clean[i];
  }
  double mean_x = sum_x / n;
  double mean_y = sum_y / n;
  
  // Compute slope using least squares
  double num = 0.0, denom = 0.0;
  for (int i = 0; i < n; ++i) {
    double dx = x_clean[i] - mean_x;
    double dy = y_clean[i] - mean_y;
    num += dx * dy;
    denom += dx * dx;
  }
  
  if (denom == 0.0) return R_NaReal;
  
  return num / denom;
}


//' Compute peak prominence (maximum residual from linear trend)
//' 
//' Fits a linear regression and returns the maximum positive residual,
//' which represents the most prominent peak above the trend line.
//' 
//' @param y Response vector
//' @param what_na Threshold for missing values
//' @return Maximum residual or NA if insufficient data
//' @author Fredrik Karlsson
//' @export
//' @examples
//' y <- c(1.0, 1.5, 3.0, 2.0, 2.5)  # Peak at index 3
//' cpp_peak_prominence(y)
// [[Rcpp::export]]
double cpp_peak_prominence(NumericVector y, double what_na = 0.0) {
  // Remove NA and missing values
  LogicalVector valid = !cpp_missing_vec_numeric(y, what_na);
  NumericVector y_clean;
  std::vector<double> x_clean;
  
  for (int i = 0; i < y.size(); ++i) {
    if (valid[i]) {
      y_clean.push_back(y[i]);
      x_clean.push_back(i + 1);
    }
  }
  
  int n = y_clean.size();
  if (n < 2) return R_NaReal;
  
  // Compute means
  double sum_x = 0.0, sum_y = 0.0;
  for (int i = 0; i < n; ++i) {
    sum_x += x_clean[i];
    sum_y += y_clean[i];
  }
  double mean_x = sum_x / n;
  double mean_y = sum_y / n;
  
  // Compute slope and intercept
  double num = 0.0, denom = 0.0;
  for (int i = 0; i < n; ++i) {
    double dx = x_clean[i] - mean_x;
    double dy = y_clean[i] - mean_y;
    num += dx * dy;
    denom += dx * dx;
  }
  
  if (denom == 0.0) return R_NaReal;
  
  double slope = num / denom;
  double intercept = mean_y - slope * mean_x;
  
  // Compute residuals and find maximum
  double max_resid = R_NegInf;
  for (int i = 0; i < n; ++i) {
    double predicted = intercept + slope * x_clean[i];
    double residual = y_clean[i] - predicted;
    if (residual > max_resid) {
      max_resid = residual;
    }
  }
  
  return max_resid;
}
