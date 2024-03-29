% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vfd.R
\name{vector.space}
\alias{vector.space}
\title{Computes properties for the vowel space constructed by the supplied F1 and F2 formant values.}
\usage{
vector.space(
  f1,
  f2,
  na.rm = TRUE,
  output = c("center", "norms", "angles", "whichvowelcorner", "corners", "meanvectors"),
  center = NULL,
  center.method = "wcentroid",
  minimum.no.vectors = 3
)
}
\arguments{
\item{f1}{A vector of F1 values.}

\item{f2}{A vector of F2 values.}

\item{na.rm}{Boolean value specifying whether missing values should be removed. Defaults to TRUE.}

\item{output}{List of vowel properties to be returned. Could be one or many of "center","norms","angles","whichvowelcorner","corners","meanvectors","areas" or "vsa". All values are returned by default.}

\item{center}{A vector (F2,F1) specifying the vowel space center to be used. If NULL, the center will be calculated using the \code{\link{vowelspace.center}} function.}

\item{center.method}{The method to use in the calculation of vowel space center. See \code{\link{vowelspace.center}} for details.}

\item{minimum.no.vectors}{The minimum number of vectors needed for a mean vector to be computed.}
}
\value{
A list containing the properties specified by the "output" argument.Could be one or many of
\item{F1 center}{Computed vowel space center vowel's F_1 values}
\item{F2 center}{Computed vowel space center vowel's F_2 values}
\item{Vector norms}{Length of all supplied vowel vectors}
\item{Vector angles}{Angles of all supplied vowel vectors}
\item{Which vowel corner}{A factor indicating in which corner of the vowel space each vowel is located.}
\item{Corner vowels}{Data frame of corner vowels F_1 and F_2 values}
\item{Mean vectors}{Data frame of corner vowels as vector norms and angles}
\item{Triangle areas}{Individual triangle areas}
\item{VSA(n)}{Vowel space area. The 'n' indicates the number of corners in the vowel space.}
}
\description{
Computes properties for the vowel space constructed by the supplied F1 and F2 formant values.
}
\examples{

vsdata <- data.frame(F1=c(rnorm(100,mean=300,sd=100),rnorm(100,mean=600,sd=100),rnorm(100,mean=600,sd=100),rnorm(100,mean=300,sd=100)),F2=c(rnorm(100,mean=2200,sd=200),rnorm(100,mean=1700,sd=200),rnorm(100,mean=1000,sd=200),rnorm(100,mean=900,sd=200)),Vowel=rep(c("i","ae","a","u"),c(100,100,100,100)))
outvs <- vector.space(vsdata$F1,vsdata$F2)
summary(outvs)

}
\references{
\insertRef{Karlsson:2012vb}{articulated}
}
\author{
Fredrik Karlsson
}
\keyword{arith}
\keyword{misc}
\keyword{utilities}
