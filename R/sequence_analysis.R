##' Identify missing or invalid values
##'
##' High-performance implementation using Rcpp to identify values that are 
##' NA, NULL, or below/equal to a threshold.
##'
##' @param x Numeric or character vector
##' @param what.na For numeric: threshold value (values <= this are considered missing). 
##'   For character: vector of strings to consider missing.
##' @return Logical vector indicating missing values
##' @export
##' @examples
##' x <- c(1.2, 0, 1.5, NA, -1, 2.0)
##' missing_vec(x, what.na = 0)
missing_vec <- function(x, what.na = 0){
  if(is.numeric(what.na)){
    if(length(what.na) > 1) stop("You cannot supply more than one cut off value.")
    return(cpp_missing_vec_numeric(x, what_na = what.na))
  }
  
  if(is.character(what.na)){
    return(cpp_missing_vec_character(x, what_na = what.na))
  }
  
  stop("what.na must be numeric or character")
}


##' Compute fraction of missing values
##'
##' High-performance implementation using Rcpp to calculate the proportion 
##' of values that are missing or invalid.
##'
##' @param x Numeric vector
##' @param what.na Threshold for missing values (default: 0)
##' @return Fraction of missing values (0 to 1)
##' @export
##' @examples
##' x <- c(1.2, 0, 1.5, NA, -1, 2.0)
##' missing_frac(x)
missing_frac <- function(x, what.na = 0){
  cpp_missing_frac(x, what_na = what.na)
} 

##' Find first changepoint in sequence
##'
##' High-performance implementation using Rcpp to identify the index of 
##' the first transition between missing and non-missing values.
##'
##' @param x Numeric vector
##' @param what.na Threshold for missing values (default: 0)
##' @return Index of first changepoint (1-based) or NA if no changepoint
##' @export
##' @examples
##' x <- c(0, 0, 1.2, 1.5, 2.0)
##' left_changepoint(x)  # Returns 3
left_changepoint <- function(x, what.na = 0){
  cpp_left_changepoint(x, what_na = what.na)
}

##' Find last changepoint in sequence
##'
##' High-performance implementation using Rcpp to identify the index of 
##' the last transition between missing and non-missing values.
##'
##' @param x Numeric vector
##' @param what.na Threshold for missing values (default: 0)
##' @return Index of last changepoint (1-based) or NA if no changepoint
##' @export
##' @examples
##' x <- c(0, 0, 1.2, 1.5, 0, 0)
##' right_changepoint(x)  # Returns 5
right_changepoint <- function(x, what.na = 0){
  cpp_right_changepoint(x, what_na = what.na)
}

##' Compute peak prominence
##'
##' High-performance implementation using Rcpp to fit a linear regression 
##' and return the maximum positive residual (peak above trend line).
##'
##' @param inVec Numeric vector
##' @param what.na Threshold for missing values (default: 0)
##' @return Maximum residual or NA if insufficient data
##' @export
##' @examples
##' y <- c(1.0, 1.5, 3.0, 2.0, 2.5)  # Peak at index 3
##' peak_prominence(y)
peak_prominence <- function(inVec, what.na = 0){
  cpp_peak_prominence(inVec, what_na = what.na)
}

##' Compute linear model slope
##'
##' High-performance implementation using Rcpp to fit a simple linear 
##' regression and return the slope coefficient.
##'
##' @param inVec Numeric vector
##' @param what.na Threshold for missing values (default: 0)
##' @return Slope coefficient or NA if insufficient data
##' @export
##' @examples
##' y <- c(1.0, 1.5, 2.0, 2.3, 3.0)
##' lm_slope(y)
lm_slope <- function(inVec, what.na = 0){
  cpp_lm_slope(inVec, what_na = what.na)
}

