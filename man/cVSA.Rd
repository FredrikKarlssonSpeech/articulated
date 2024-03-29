% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vfd.R
\name{cVSA}
\alias{cVSA}
\title{Compute the Vowel space area using continuously measured formant frequency
values}
\usage{
cVSA(
  F2,
  F1,
  vowel_categories = 5,
  threshold = 0.3,
  center = FALSE,
  scale = FALSE
)
}
\arguments{
\item{F2}{A vector of F2 formant frequency measurements, one for each measure vowel.}

\item{F1}{A vector of F1 formant frequency measurements, one for each measure vowel.}

\item{vowel_categories}{The number of vowel categories we should consider, which translates to the number of gaussian mixture components in the GMM.}

\item{threshold}{The threshold of the likelihood that the vowel formant frequency measurement must meet in order to be included in the convex hull.}

\item{center}{Should the formant frequency measurements be centered using the mean frequency? This was not done in the original implementation.}

\item{scale}{Should the formant frequency measurements be scaled to a 0-1 scale using the standard deviation of the formant frequencies? This was not done in the original implementation.}
}
\value{
The vowel space area (in Hz^2).
}
\description{
This function implements the algorithm proposed by
\insertCite{Sandoval.2013.10.1121/1.4826150}{articulated}, which takes
continous measurements of formant frequencies for a speaker and computes the
vowel space area from the convex hull of them, once spurious measurements
have been removed using a likelihood threshold applied to the result of a
Gaussian mixture model (GMM).
}
\details{
The GMM and convex hull computations are both based on computed euclidean distances between vowels.
}
\references{
\insertAllCited{}
 
 @examples 
 data(pb)
 cVSA(pb[,"F2"],pb[,"F1"]) -> ch
 #Simple but informative plot
 plot(ch,xlab="<-Back / Front -> (F2)",ylab="<-Closed / Open -> (F1)")
}
