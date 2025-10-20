#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Compute vowel space center
//' 
//' Computes the center of a vowel space using different methods.
//' 
//' @param f1 F1 formant values (Hz)
//' @param f2 F2 formant values (Hz)
//' @param method Center computation method: "centroid", "twomeans", or "wcentroid"
//' @param na_rm Remove NA values? (default TRUE)
//' @return List with f1c and f2c center coordinates
//' @author Fredrik Karlsson
//' @export
//' @examples
//' f1 <- c(300, 600, 600, 300)
//' f2 <- c(2200, 1700, 1000, 900)
//' cpp_vowel_center(f1, f2)
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
  if (n == 0) {
    return List::create(Named("f1c") = R_NaReal,
                       Named("f2c") = R_NaReal);
  }
  
  double f1c = 0.0, f2c = 0.0;
  
  if (method == "centroid") {
    // Simple mean of both dimensions
    f1c = mean(f1_clean);
    f2c = mean(f2_clean);
    
  } else if (method == "twomeans") {
    // Compute F1 center
    f1c = mean(f1_clean);
    
    // Split F2 into upper and lower based on F1 center
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
    // Mean F1
    f1c = mean(f1_clean);
    
    // Mean F2 for points below F1 center
    std::vector<double> f2_lower;
    for (int i = 0; i < n; ++i) {
      if (f1_clean[i] < f1c) {
        f2_lower.push_back(f2_clean[i]);
      }
    }
    
    if (!f2_lower.empty()) {
      for (double val : f2_lower) f2c += val;
      f2c /= f2_lower.size();
    } else {
      // Fallback to overall F2 mean if no points below F1 center
      f2c = mean(f2_clean);
    }
  } else {
    stop("Invalid method. Must be 'centroid', 'twomeans', or 'wcentroid'");
  }
  
  return List::create(Named("f1c") = f1c,
                     Named("f2c") = f2c);
}


//' Compute vowel vector norms (distances from center)
//' 
//' Computes the Euclidean distance of each vowel from the vowel space center.
//' 
//' @param f1 F1 formant values (Hz)
//' @param f2 F2 formant values (Hz)
//' @param f1c F1 coordinate of vowel space center
//' @param f2c F2 coordinate of vowel space center
//' @return Vector of Euclidean distances
//' @author Fredrik Karlsson
//' @export
//' @examples
//' f1 <- c(300, 600, 600, 300)
//' f2 <- c(2200, 1700, 1000, 900)
//' center <- cpp_vowel_center(f1, f2)
//' cpp_vowel_norms(f1, f2, center$f1c, center$f2c)
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


//' Compute vowel vector angles (polar coordinates)
//' 
//' Computes the angle of each vowel vector from the vowel space center,
//' in radians using atan2.
//' 
//' @param f1 F1 formant values (Hz)
//' @param f2 F2 formant values (Hz)
//' @param f1c F1 coordinate of vowel space center
//' @param f2c F2 coordinate of vowel space center  
//' @return Vector of angles in radians (-pi to pi)
//' @author Fredrik Karlsson
//' @export
//' @examples
//' f1 <- c(300, 600, 600, 300)
//' f2 <- c(2200, 1700, 1000, 900)
//' center <- cpp_vowel_center(f1, f2)
//' cpp_vowel_angles(f1, f2, center$f1c, center$f2c)
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
