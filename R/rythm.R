##' Raw pairwise variability index.
##' 
##' Computes the raw Pairwire Variability Index (rPVI) on a supplied vector of durations.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x A vector of durations in arbitrary unit.
##' @param na.rm Boolean indicating whether NA values should be removed before calculating rPVI.
##' 
##' @return A single value reprenting the rPVI for the vector of durations
##' 
##'@references Nolan, F., & Asu, E. L. (2009). The Pairwise Variability Index and Coexisting Rhythms in Language. Phonetica, 66(1-2), 64–77. doi:10.1159/000208931 
##'

rPVI <- function(x,na.rm=TRUE){
 
  rpvi <- cpprPVI(x,na.rm)
  return(rpvi)
}



##' Normalized pairwise variability index.
##' 
##' Computes the normalized Pairwire Variability Index (nPVI) on a supplied vector of durations.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x A vector of durations in arbitrary unit.
##' @param na.rm Boolean indicating whether NA values should be removed before calculating nPVI.
##' 
##' @return A single value reprenting the nPVI for the vector of durations
##' 
##'@references Nolan, F., & Asu, E. L. (2009). The Pairwise Variability Index and Coexisting Rhythms in Language. Phonetica, 66(1-2), 64–77. doi:10.1159/000208931 
##'

nPVI <- function(x,na.rm=TRUE){
  
  npvi <- cppnPVI(x,na.rm)
  return(npvi)
}



##' Computes the local jitter of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##' @param absolute Should the (local) Jitter value be returned (absolute=FALSE), or the absolute (local) Jitter (absolute=TRUE). In the case of absolute (local) Jitter, the jitter will *not* be devided by the average period.
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A value indicating the (local) jitter (absolute=FALSE) or the absolute (local) jitter (absolute=TRUE).

  



jitter_local <- function(x,
                         min.period=-.Machine$integer.max, 
                         max.period=.Machine$integer.max,
                         absolute = FALSE,
                         na.rm=TRUE){

  jitt <- cppJitterLocal(x,min.period,max.period,absolute,na.rm)
  return(jitt)
}

##' Computes the Difference of Differences of Periods (DDP) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##'  @param absolute Should the Jitter DDP value be returned (absolute=FALSE), or the absolute Jitter DDP(absolute=TRUE). In the case of absolute Jitter DDP, the jitter will *not* be devided by the average period.
##' @param na.rm Should missing intervals be removed?
##' 
##' @return   ##' @return A value indicating the  jitter DDP (in s) (absolute=FALSE) or the absolute jitter DDP (in percent, $1..600%$) (absolute=TRUE).
##' 
##' 

jitter_ddp  <- function(x,
                         min.period=-.Machine$integer.max, 
                         max.period=.Machine$integer.max,
                         absolute = FALSE,
                         na.rm=TRUE){
  
  jitt <- cppJitterDDP(x,min.period,max.period,absolute,na.rm)
  return(jitt)
}


##' Computes the Relative Average Perturbation (RAP) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##'  @param absolute Should the Jitter RAP value be returned (absolute=FALSE), or the absolute Jitter RAP(absolute=TRUE). In the case of absolute Jitter RAP, the jitter will *not* be devided by the average period. 
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A list containing the RAP (in percent, $1..200%$) or absolute PPQ5 (\code{absAP}) values (in s) for the vector of values. If the vector contains less than three values, NA is returned.
##' 
##'
##'

jitter_rap <- function(x,
                       min.period=-.Machine$integer.max, 
                       max.period=.Machine$integer.max,
                       absolute = FALSE,
                       na.rm=TRUE){
  
  jitt <- cppJitterRAP(x,min.period,max.period,absolute,na.rm)
  return(jitt)
}

##' Computes the five-point Period Perturbation Quotient (PPQ5) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##'  
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##'  @param absolute Should the Jitter RAP value be returned (absolute=FALSE), or the absolute Jitter PPQ5 (absolute=TRUE). In the case of absolute Jitter PPQ5, the jitter will *not* be devided by the average period. 
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A list containing the jitter PPQ5 (in percent, 1..400%) or absolute PPQ5 values (in s, 1..4) for the vector of values. If the vector contains less than five values, NA is returned.
##'   
##'   
##'   
##'   

jitter_ppq5 <- function(x,
                                   min.period=-.Machine$integer.max, 
                                   max.period=.Machine$integer.max,
                                   absolute = FALSE,
                                   na.rm=TRUE){
  
  jitt <- cppJitterPPQ5(x,min.period,max.period,absolute,na.rm)
  return(jitt)
}


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

##' Computes the Pace stability from a vector of syllable durations.
##' The vector must contain at least 20 syllables.
##' 
##' The function computes the mean of intervals mid and final parts of sequence and relates that to the mean of intervals 1-4 The two means are returned as separate mean fractions (*100). If n is specified, only n syllables are included.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @inheritParams COV5_x
##' 
##' @return A vector of 2 values, one for the pace stability of intervals $5..12$ and one for $13..20$.
##' 
##' @references
##' 
##' Skodda, S., Flasskamp, A., & Schlegel, U. (2010). Instability of syllable repetition as a model for impaired motor processing: is Parkinson’s disease a “rhythm disorder?” Journal of Neural Transmission, 117(5), 605–612. doi:10.1007/s00702-010-0390-y
##' 
##' 

pace.stability <- function(x,kind=c("5_12","13_20"),return.na=TRUE,na.rm=FALSE ){
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  
  xL <- length(x)

  first <- 1:4
  mid <- 5:12
  rest <- 13:20
  indicies <- FALSE
  # print(N)
  if(kind == "5_12" & xL >= 12 ){
    indicies <- mid
  } 
  if (kind == "13_20" & xL >= 20){
    indicies <- rest
  } 

  out <- (mean(x[indicies],na.rm=na.rm) / mean(x[first],na.rm=na.rm)) * 100
  
  if(! is.na(out)) {
    return(out)
  }else{
    if(return.na){
      return(NA)
    }else{
      stop("Error! Not enough syllables to compute pace stability in accordance with the specification.")
    }    
  }

}


##' Computes Pace accelleration in  a vector of intervals.
##' 
##' The acceleration is computed based on 
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @inheritParams COV5_x
##' 
##' 
##' @references
##' 
##' Flasskamp, A., Kotz, S. A., Schlegel, U., & Skodda, S. (2012). Acceleration of syllable repetition in Parkinson’s disease is more prominent in the left-side dominant patients. Parkinsonism & Related Disorders, 18(4), 343–347. doi: 10.1016/j.parkreldis.2011.11.021
##' 
##'

pace.acceleration <- function(x,n=20,return.na=TRUE,na.rm=TRUE){
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  ps512 <- pace.stability(x,n=n,kind="5_12",return.na)
  ps1320 <- pace.stability(x,n=n,kind="13_20",return.na)
  out <-  ps512  - ps1320
  if(is.na(out) && return.na){
    return(out) 
  }else{
    stop("Unable to compute pace accelleration: too few intervals.")
  }

}

