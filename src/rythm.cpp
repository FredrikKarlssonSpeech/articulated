#include <Rcpp.h>
using namespace Rcpp;

/* This is the Rcpp versions of of rythm measures.
 * 
 * 
 */ 

// [[Rcpp::export]]
double cpprPVI(NumericVector x, bool narm) {
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

// [[Rcpp::export]]
double cppnPVI(NumericVector x, bool narm) {
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

// [[Rcpp::export]]
double cppJitterLocal(NumericVector x, 
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


 

// [[Rcpp::export]]
double cppJitterDDP(NumericVector x, 
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
  
  if(n > 1){
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