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
