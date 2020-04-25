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
  
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  
  tryCatch({
    xL <- length(x)
    x1 <- x[1:(xL-1)]
    x2 <- x[2:xL]
    ud <- ( x2 - x1 )
    ld <- (x2 + x1)/2
    tot <- abs( ud / ld)
    npvi <- sum( tot ) / (xL -1)
    return(100 *npvi)
  },error=function(e) return(NA))
  

}



##' Computes the local jitter of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A list containing 
##'   \item{Jitt}{local Jitt (in percent, \eqn{1..200}{1.200} }
##'   \item{absJitt}{absolute local Jitter values (in s)}
##'   \item{MDVPPathJitt}{the level indicated by MDVP as the threshold for patological voice for Jitt}
##'   \item{NDVPPathabsJitt}{the level indicated by MDVP as the threshold for patological voice for Jitta (absolute local Jitter)}
##'  If the vector contains less than two values, NA is returned.
  



jitter_local <- function(x,min.period=NULL, max.period=NULL,na.rm=TRUE){
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  x <- x[is.null(min.period) || x >= min.period]
  x <- x[is.null(max.period) || x <= max.period]
  
  # jitter(seconds) = ∑i=2N |Ti - Ti-1| / (N - 1)
  xL <- length(x)

  tryCatch({
    xn1 <- x[1:(xL-1)]
    xi <- x[2:xL]
    
    jitt <- sum(abs(xi-xn1))/(xL-1)
    return(list(absJitt=jitt,Jitt=jitt/mean(x),MDVPPathJitt=1.040,NDVPPathabsJitt=0.0000832))
    
  },error=function(e) return(list(absJitt=NA,Jitt=NA,MDVPPathJitt=1.040,NDVPPathabsJitt=0.0000832)))
}

##' Computes theDifference of Differences of Periods (DDP) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A list containing the DDP (in s) and absolute DDP (\code{absDDP}) values (in percent, $1..600%$) for the vector of values. If the vector contains less than three values, NA is returned.
##' 
##' 

jitter_ddp <- function(x,min.period=NULL, max.period=NULL,na.rm=TRUE){
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  x <- x[is.null(min.period) || x >= min.period]
  x <- x[is.null(max.period) || x <= max.period]
  # absDDP(seconds) = ∑i=2N-1 |(Ti+1 - Ti) - (Ti - Ti-1)| / (N - 2)
  xL <- length(x)

  tryCatch({
      xn1 <- x[1:(xL-2)]
      xi <- x[2:(xL-1)]
      xp1 <- x[3:(xL)]
      
      jitt <- sum(abs( (xp1 - xi) - (xi - xn1 )  ))/(xL-2)
      return(list(absDDP=jitt,DDP=jitt/mean(x)))  
      
    },error=function(e) return(list(absDDP=NA,DDP=NA)))
    

  
}


##' Computes the Relative Average Perturbation (RAP) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##' @param na.rm Should missing intervals be removed?
##' 
##' @return A list containing the RAP (in percent, $1..200%$) and absolute PPQ5 (\code{absAP}) values (in s) for the vector of values. If the vector contains less than three values, NA is returned.
##' 
##'
##'

jitter_rap <- function(x,min.period=NULL, max.period=NULL,na.rm=TRUE){
  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  x <- x[is.null(min.period) || x >= min.period]
  x <- x[is.null(max.period) || x <= max.period]
  
  
  # absAP(seconds) = ∑i=2N-1 |Ti - (Ti-1 + Ti + Ti+1) / 3| / (N - 2)
  
  xL <- length(x)
  tryCatch({
      xn1 <- x[1:(xL-2)]
      xi <- x[2:(xL-1)]
      xp1 <- x[3:(xL)]
      
      jitt <- sum(abs(xi - ( xn1 + xi + xp1 )/3 ))/(xL-2)
      return(list(absRAP=jitt,RAP=jitt/mean(x)))
  },error=function(e) return(list(absRAP=NA,RAP=NA)))
    
}

##' Computes the five-point Period Perturbation Quotient (PPQ5) of a vector.
##' 
##' @author Fredrik Karlsson
##' @export
##'  
##' @param x The input vector
##' @param min.period The minimum value to be included in the calculation.
##' @param max.period The maximum value to be included in the calculation.
##' @param na.rm Should missing intervals be removed
##'   
##' @return A list containing the PPQ5 (in percent, 1..400%) and absolute PPQ5 (\code{absPPQ5}) values (in s) for the vector of values. If the vector contains less than five values, NA is returned.
##'   
##'   
##'   

jitter_ppq5 <- function(x,min.period=NULL, max.period=NULL,na.rm=TRUE){

  if(na.rm){
    x <- as.vector(na.exclude(x))
  }else{
    x <- as.vector(x)
  }
  x <- x[is.null(min.period) || x >= min.period]
  x <- x[is.null(max.period) || x <= max.period]

  # absPPQ5(seconds) = ∑i=3N-2 |Ti - (Ti-2 + Ti-1 + Ti + Ti+1 + Ti+2) / 5| / (N - 4)
  
  xL <- length(x)

  tryCatch({
    xn2 <- x[1:(xL-4)]
    xn1 <- x[2:(xL-3)]
    xi <- x[3:(xL-2)]
    xp1 <- x[4:(xL-1)]
    xp2 <- x[5:(xL)]
    
    
    jitt <- sum(abs(xi - (xn2 + xn1 + xi + xp1 + xp2)/5 ))/(xL-4)
    return(list(absPPQ5=jitt,PPQ5=jitt/mean(x)))
  },error=function(e) return(list(absPPQ5=NA,PPQ5=NA)))

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

##' An implementation of the Enveolope Modulation Spectrum (EMS) for speech analysis
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param file File to be analysed.
##' @param plot.ems boolean; should the resulting EMS be plotted when it has been computed?
##' @param plot.oscillogram boolean; should the signal be plotted after having been downsampled to 80Hz?
##' @param fftw boolean; use the fftw package be used when computing the power spectrum. This package needs to be installed then.
##' @return a matrix containing the computed EMS.
##' 
##' @references 
##' Liss, J. M. M., LeGendre, S., & Lotto, A. J. (2010). Discriminating Dysarthria Type From Envelope Modulation Spectra. Journal of Speech, Language and Hearing Research, 53(5), 1246–10. http://doi.org/10.1044/1092-4388(2010/09-0121)
##' 

EMS <- function(file,plot.ems=TRUE,plot.oscillogram=FALSE,fftw=TRUE){
  # require(seewave)
  # require(tuneR)
  readWave(file) -> samp
  resamp(samp,g=80,output="Wave") -> samp80
  env(samp80,plot=plot.oscillogram,norm=TRUE) -> sampenv80
  if(! plot.ems){
    spec(sampenv80^2,f=80,plot=FALSE,norm=TRUE,fftw=fftw) -> sampspec 
  }else{
    spec(sampenv80^2,f=80,norm=TRUE,fftw=fftw) -> sampspec
  }

  return(sampspec)
  
}

emsPeak <- function(inSpec,output.components=c("freq","amp")){
  if(!class(inSpec) %in%c ("matrix","data.frame")){
    stop("The spectrum needs to be a matrix or a data.frame object!")
  }
  mean(inSpec[,2],na.rm=TRUE) -> mamp
  fpeaks(out,plot=FALSE) -> specP
  subset(as.data.frame(specP),amp==max(amp),select=output.components) -> out
  #Normalize by average amp in the spectrum
  out$amp <- out$amp / mamp
  return(as.list(out))
}

# The present study calculated the modulation spec- tra for amplitude envelopes extracted from the full sig- nal and seven octave bands (center frequencies of 125, 250, 500, 1000, 2000, 4000, and 8000). From each of these eight modulation spectra, six variables were computed (see Table 1). These 48 dependent variables (8 envelopes × 6 metrics) can be calculated from any signal using a fully automated program developed in MATLAB (Mathworks). The signal is filtered into the octave bands (pass-band eighth-order Chebyshev digital filters), and the ampli- tude envelope is extracted (half-wave rectified, followed by 30-Hz low-pass fourth-order Butterworth filter) and downsampled (to 80 Hz, mean subtracted). The power spectrum of each down-sampled envelope is calculated with a 512-point fast Fourier transform using a Tukey window and converted to decibels for frequencies up to 10 Hz (normalized to maximum autocorrelation). The six EMS metrics are then computed from the resulting spec- trum for each band (and the full signal).

##' A utility function to split labels
##' 
##' The function assumes that numbers in the label indicate a count. Text parts of the label (numbers removed) are then used as labels in \code{count} repetitions of the row, with the interval between \code{starttime} and \code{endtime} split into \code{count} intervals.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param labels A vector of labels. If \code{counts} is not set, numbers in the labels will be interpreted as counts, e.g. "C3" or "3C" will be interpreted as "a C interval to be split into 3 intervals".
##' @param starttime A vector of start times for the labels.
##' @param endtime A vector of end times for the labels.
##' @param counts An optional vector indicating the number of partitions to make of each inteval. If not included, numbers will be extracted from the labels instead.
##' 
##' @return A data frame containing columns \code{label}, \code{endtime} and \code{endtime}, with intervals split as indicated.
##' 


expandCVn <- function(labels,starttime,endtime, counts=NULL){
  if(length(labels) != length(starttime) | length(starttime) != length(endtime) | length(labels) != length(endtime)   ){
    stop("The supplied vectors are not of the same length.")
  }
  if(!is.null(counts)){
    numbers <- counts
    nLabs <- labels
  }else{
    numbers <- gsub("[^1-9]+","",labels)
    numbers <- as.numeric(numbers)
    nLabs <- gsub("[1-9]+","",labels)
  }
  
  deltas <- (endtime - starttime) / numbers
  #Now, work only with numbers, nLabs, starttime and endtime
  #df <- data.frame(labels=nLabs,num=numbers,starttime=starttime,endtime=endtime)
  out <- data.frame(label=list(),starttime=list(),endtime=list())
  for(i in seq_along(labels)){
    currstart <- 0
    for(count in 1:(numbers[i])){
      currstart <- starttime[i]+ (deltas[i] * (count-1))
      if((currstart + 1.5*deltas[i]) > endtime[i]){
        currend <- endtime[i]
      }else{
        currend <- starttime[i] + (deltas[i] * (count))
      }
      row <- data.frame(label=nLabs[i],starttime=currstart,endtime=currend)
      out <- rbind(out,row)
    }
  }
  return(out)
}

