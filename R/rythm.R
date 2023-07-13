
##' A simple utility function to compute the coefficient of variance for values in a vector
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The vector to process.
##' @param na.rm boolean; Should NAs be removed for the computations. Otherwise, an NA will be returned for a vector containing one or more NAs.
##' 
##' @return The standard deviation / mean of a vector


COV <- function(x,na.rm=TRUE){
  
  out <- sd(x,na.rm=na.rm) / mean(x,na.rm=na.rm)
  return(out)
}

##' Computes the coefficient of variance for an interval vector based on the average of the first four elements in the vector of intervals.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' 
##' @param x The input vector containing syllable durations.
##' @param n The number of intervals to include in the computations. Defaults to 20. The vector should not contain missing values.
##' @param return.na boolean;Return NA in the case there are not 8 intervals in the series?
##' @param na.rm Should NA intervals be removed?
##' 
##' @return A single value indicating Relative coefficient of variation in intervals $5..n$ relative to the mean duration of intervals $1..4$.
##' 
##' @references
##' Skodda, S., Lorenz, J., & Schlegel, U. (2012). Instability of syllable repetition in Parkinson's disease—Impairment of automated speech performance? Basal Ganglia, 3(1), 33–37. doi:10.1016/j.baga.2012.11.002
##' Skodda, S., Schlegel, U., Hoffmann, R., & Saft, C. (2013). Impaired motor speech performance in Huntington’s disease. Journal of Neural Transmission, 1–9–9. doi:10.1007/s00702-013-1115-9
##'

COV5_x <- function(x,n=20,return.na=TRUE,na.rm=TRUE){

  N <- length(x)
  if( N < n){
    if(return.na){
      return(NA)
    }else{
      stop(paste("The length of the vector should be at least",n))
    }
  }else{
      mid <- 5:n
      out <- sd(x[mid],na.rm=na.rm) / (mean(x[1:4],na.rm=na.rm) / sqrt(n-4)) * 100
      
  }
  return(out) 
}

##' Computes the "relative pace stability" of a vector of syllable durations.
##' 
##' 
##' The vector must contain at least 20 syllables.
##' 
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector containing syllable durations.
##' @param kind Should the relative stability be computed for intervals $5..12$ (kind = "5_12") or $13..20$ (kind = "13_20").
##' @param omit Should NA intervals be removed before computing the relative pace stability? Please note that one NA value in a syllable duration vector means that relstab(kind="5_12") will compute the stability of syllables 5-13 or 6-13 instead of 5-12 when the NA value is removed, which is  likelly not what you want. 
##' 
##' @return A single numeric value indicating the relative pace stability, or NA if the vector was not long enough.
##' 
##' @references
##' 
##' Skodda, S., Flasskamp, A., & Schlegel, U. (2010). Instability of syllable repetition as a model for impaired motor processing: is Parkinson’s disease a “rhythm disorder?” Journal of Neural Transmission, 117(5), 605–612. doi:10.1007/s00702-010-0390-y
##' 
##' 

relstab <- function(x,kind="5_12",omit=FALSE ){
  
  ps <- switch(kind,
               "5_12" = articulated:::cppRelStab(x,start = 5,end = 12,omit=omit),
               "13_20" = articulated:::cppRelStab(x,start = 13,end = 20,omit=omit)
               )
  if(is.null(ps)) stop("Error: You may only ask for kinds \"5_12\" and \"13_20\".")
  return(ps)
}


##' Computes pace acceleration in  a vector of intervals.
##'
##' Computes the pace acceleration of a DDK sequence according to the definition 
##' in \insertCite{Flasskamp:2011jq}{articulated}.
##' 
##' Please note that one NA value in a syllable duration vector means
##' that the function will compute the %PA of syllables up to the 21st (and
##' not the 20th as was defined in the original publication), which is likelly
##' not what you want. Please use `omit=TRUE` to handle this case. 
##'
##' @author Fredrik Karlsson
##' @export
##'
##' @param x The input vector containing syllable durations.
##' @param return.na boolean;Return NA in the case there are not 20 intervals in
##'   the series?
##' @param omit Should NA intervals be removed before computing the relative
##'   %PA? 
##'
##' @references 
##'   \insertAllCited{}
##'
##' \insertRef{Flasskamp:2011jq}{articulated}
##'
##' 

PA <- function(x,return.na=TRUE,omit=FALSE){
  out <- NA
  ps512 <- relstab(x,kind="5_12",omit=omit)
  ps1320 <- relstab(x,kind="13_20",omit=omit)
  out <-   ps1320 - ps512
  
  if(return.na){
    #Return regardless
    return(out)
  } else {
    if(is.na(out)){
      stop("Unable to compute pace accelleration: At least 20 intervals are required.")
    }
  }

}

