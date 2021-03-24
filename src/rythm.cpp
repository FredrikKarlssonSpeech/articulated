#include <Rcpp.h>
using namespace Rcpp;

//' Raw pairwise variability index.
//' 
//' Computes the raw Pairwire Variability Index (rPVI) on a supplied vector of durations.
//' 
//' @author Fredrik Karlsson
//' @export
//' 
//' @param x A vector of durations in arbitrary unit.
//' @param na.rm Boolean indicating whether NA values should be removed before calculating rPVI.
//' 
//' @return A single value reprenting the rPVI for the vector of durations
//' 
//' @references Nolan, F., & Asu, E. L. (2009). The Pairwise Variability Index and Coexisting Rhythms in Language. Phonetica, 66(1-2), 64–77. doi:10.1159/000208931 
//'
// [[Rcpp::export]]
double rPVI(NumericVector x, bool narm) {
  int n = x.size();
  double rpvi = 0;
  double total = 0;
  if(narm){
    x = x[!is_na(x)];  
  }
  
  if(n > 1){
    // i goes from 2-n and i-1 goes from 1 to n-1.
    for(int i = 1; i < n; ++i) {
      total += abs(x[i]-x[i-1]);
    }
    rpvi = total / (n-1);
  } else {
    rpvi = R_NaReal;
  }
  return rpvi;
}


//' @title Normalized pairwise variability index.
//' 
//' Computes the normalized Pairwire Variability Index (nPVI) on a supplied vector of durations.
//' 
//' @author Fredrik Karlsson
//' @export
//' 
//' @param x A vector of durations in arbitrary unit.
//' @param na.rm Boolean indicating whether NA values should be removed before calculating nPVI.
//' 
//' @return A single value reprenting the nPVI for the vector of durations
//' 
//'@references Nolan, F., & Asu, E. L. (2009). The Pairwise Variability Index and Coexisting Rhythms in Language. Phonetica, 66(1-2), 64–77. doi:10.1159/000208931 
//'

// [[Rcpp::export]]
double nPVI(NumericVector x, bool narm) {
  if(narm){
    x = x[!is_na(x)];  
  }
  double npvi = 0;
  double total = 0;
  double ud = 0;
  double ld = 0;
  int n = x.size();
  
  if(n > 1){
    // i goes from 2-n and i-1 goes from 1 to n-1.
    for(int i = 1; i < n; ++i) {
      ud = x[i]-x[i-1];
      ld = (x[i] + x[i-1]) /2;
      total += abs(ud / ld);
    }
    npvi = total / (n-1) * 100;
  } else {
    npvi = R_NaReal;
  }
  return npvi;
}

//' Computes the local jitter of a vector.
//' 
//' @author Fredrik Karlsson
//' @export
//' 
//' @param x The input vector
//' @param min.period The minimum value to be included in the calculation.
//' @param max.period The maximum value to be included in the calculation.
//' @param absolute Should the (local) Jitter value be returned (absolute=FALSE), or the absolute (local) Jitter (absolute=TRUE). In the case of absolute (local) Jitter, the jitter will *not* be devided by the average period.
//' @param na.rm Should missing intervals be removed?
//' 
//' @return A value indicating the (local) jitter (absolute=FALSE) or the absolute (local) jitter (absolute=TRUE).

// [[Rcpp::export]]
double jitter_local(NumericVector x, 
                      int minperiod , 
                      int maxperiod ,
                      bool absolute = false,
                      bool narm = true) {
  if(narm){
    x = x[!is_na(x)];  
  }
  double x1 = 0, x2 = 0;
  double jitt = R_NaReal;
  double totaldev = 0, sum = 0;
  int n = x.size();
  
  if(n > 1){
    sum = x[0];
    // i goes from 2-n and i-1 goes from 1 to n-1.
    for(int i = 1; i < n; ++i) {
      x1 = x[i-1];
      x2 = x[i];
      if(x1 >= minperiod && x1 <= maxperiod && 
        x2 >= minperiod && x2 <= maxperiod ){
        totaldev += std::abs(x2 - x1);
        sum += x2;
      }
    }
    jitt = totaldev / (n-1);
    if(! absolute){
      jitt = jitt / (sum / n);
    }
  } 
  return jitt;
}

//' Computes the Difference of Differences of Periods (DDP) of a vector.
//' 
//' @author Fredrik Karlsson
//' @export
//' 
//' @param x The input vector
//' @param min.period The minimum value to be included in the calculation.
//' @param max.period The maximum value to be included in the calculation.
//'  @param absolute Should the Jitter DDP value be returned (absolute=FALSE), or the absolute Jitter DDP(absolute=TRUE). In the case of absolute Jitter DDP, the jitter will *not* be devided by the average period.
//' @param na.rm Should missing intervals be removed?
//' 
//' @return   //' @return A value indicating the  jitter DDP (in s) (absolute=FALSE) or the absolute jitter DDP (in percent, $1..600%$) (absolute=TRUE).
//' 
//' 
 
// [[Rcpp::export]]
double jitter_ddp(NumericVector x, 
                      int minperiod , 
                      int maxperiod ,
                      bool absolute = false,
                      bool narm = true) {
  if(narm){
    x = x[!is_na(x)];  
  }
  double xp1 = 0, xn1 = 0,xi=0;
  double jitt = R_NaReal;
  double totaldev = 0, sum = 0;
  int n = x.size();
  
  if(n > 3){
    sum = x[0] + x[n-1];
  
    for(int i = 1; i < (n-1); ++i) {
      xn1 = x[i-1];
      xi = x[i];
      xp1 = x[i+1];
      if(xi >= minperiod && xi <= maxperiod ){
        totaldev += std::abs((xp1 - xi) - (xi - xn1 ));
        sum += xi;
      }
    }
    jitt = totaldev / (n-2);
    if(! absolute){
      jitt = jitt / (sum / n);
    }
  } 
  return jitt;
}
//' Computes the Relative Average Perturbation (RAP) of a vector.
//' 
//' @author Fredrik Karlsson
//' @export
//' 
//' @param x The input vector
//' @param min.period The minimum value to be included in the calculation.
//' @param max.period The maximum value to be included in the calculation.
//'  @param absolute Should the Jitter RAP value be returned (absolute=FALSE), or the absolute Jitter RAP(absolute=TRUE). In the case of absolute Jitter RAP, the jitter will *not* be devided by the average period. 
//' @param na.rm Should missing intervals be removed?
//' 
//' @return A list containing the RAP (in percent, $1..200%$) or absolute PPQ5 (\code{absAP}) values (in s) for the vector of values. If the vector contains less than three values, NA is returned.


// [[Rcpp::export]]
double jitter_rap(NumericVector x, 
                    int minperiod , 
                    int maxperiod ,
                    bool absolute = false,
                    bool narm = true) {
  if(narm){
    x = x[!is_na(x)];  
  }
  double xp1 = 0, xn1 = 0,xi=0;
  double jitt = R_NaReal;
  double totaldev = 0, sum = 0;
  int n = x.size();
  
  if(n > 3){
    sum = x[0] + x[n-1];
    
    for(int i = 1; i < (n-1); ++i) {
      xn1 = x[i-1];
      xi = x[i];
      xp1 = x[i+1];
      if(xi >= minperiod && xi <= maxperiod ){
        totaldev += std::abs( xi - ( xn1 + xi + xp1 )/3 );
        sum += xi;
      }
    }
    jitt = totaldev / (n-2);
    if(! absolute){
      jitt = jitt / (sum / n);
    }
  } 
  return jitt;
}

//' Computes the five-point Period Perturbation Quotient (PPQ5) of a vector.
//' 
//' @author Fredrik Karlsson
//' @export
//'  
//' @param x The input vector
//' @param min.period The minimum value to be included in the calculation.
//' @param max.period The maximum value to be included in the calculation.
//'  @param absolute Should the Jitter RAP value be returned (absolute=FALSE), or the absolute Jitter PPQ5 (absolute=TRUE). In the case of absolute Jitter PPQ5, the jitter will *not* be devided by the average period. 
//' @param na.rm Should missing intervals be removed?
//' 
//' @return A list containing the jitter PPQ5 (in percent, 1..400%) or absolute PPQ5 values (in s, 1..4) for the vector of values. If the vector contains less than five values, NA is returned.
  

// [[Rcpp::export]]
double jitter_ppq5(NumericVector x, 
                    int minperiod , 
                    int maxperiod ,
                    bool absolute = false,
                    bool narm = true) {
  if(narm){
    x = x[!is_na(x)];  
  }
  double xn2 = 0, xn1 = 0,xi=0, xp1 = 0, xp2= 0;
  double jitt = R_NaReal;
  double totaldev = 0, sum = 0;
  int n = x.size();
  
  if(n > 4){
    sum = x[0] + x[1] + x[n-1] + x[n-2];
    
    for(int i = 2; i < (n-2); ++i) {
      xn2 = x[i-2];
      xn1 = x[i-1];
      xi = x[i];
      xp1 = x[i+1];
      xp2 = x[i+2];
      
      if(xi >= minperiod && xi <= maxperiod ){
        totaldev += std::abs( xi - (xn2 + xn1 + xi + xp1 + xp2)/5 );
        sum += xi;
      }
    }
    jitt = totaldev / (n-4);
    if(! absolute){
      jitt = jitt / (sum / n);
    }
  } 
  return jitt;
}


// [[Rcpp::export]]
double cppRelstab(NumericVector x,
                  int compstart = 5,
                  int compstop = 12,
                  bool narm = true) {
  if(narm){
    x = x[!is_na(x)];  
  }
  
  if(compstart < 5){
    Rcpp::stop("You cant investigate the stability of a sequence that is within the reference (that is, in the  first four syllables). Pleans provide a compstart > 4.");
  }
  
  double relstab = R_NaReal;
  double compsum = 0, refsum = 0;
  int n = x.size();
  
  if(n >= (compstop - 1)){
    // References from cycles 1-4
    for(int i = 0; i < 4 ; ++i) {
      refsum += x[i];
    }
    
    for(int i = (compstart-1); i < compstop ; ++i) {
      compsum += x[i];
    }

    relstab = compsum / refsum * 100; 
  } 
  return relstab;
}


