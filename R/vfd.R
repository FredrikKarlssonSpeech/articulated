
##' Computes the center of a vowel space.
##'
##' Two methods are implemented. In the default method, a mean F_1 value are
##' calculated in an initial stage, and separate F_2 means are then computed for
##' points above a line y=mean(F_1), and one mean for values below that line.
##' The F_2 value for the center point is then computed as the mean of the upper
##' and lower mean F_2 values. The "wcentroid" method simply averages the F_2
##' and F_1 values and return that as the center point. The first method is
##' preferable, as vowel spaces in a triangular shape are otherwise quite
##' likely to have center points outside of the vowel triangle.
##'
##' @author Fredrik Karlsson
##' @export
##'
##' @param f1 The F_1 values of vowels.
##' @param f2 The F_2 values of vowels.
##' @param method The method to use. Could be either one of "centroid" or
##'   "twomeans" (the default).
##' @param na.rm Boolean indicating whether NA:s should be removed in the
##'   calculations of mean values.
##'
##' @return A list containing the F_2 and F_1 values of the vowel space center.
##'
##'
##'
##'
##'
##' @references
##' 
##' \insertRef{Karlsson:2012vb}{articulated}
##'
##' @keywords misc utilities

vowelspace.center <- function(f1,f2,method="wcentroid",na.rm=TRUE){
  if(method == "centroid"){
    f2c <- mean(f2,na.rm=na.rm)
    f1c <- mean(f1,na.rm=na.rm)
  }
  
  if(method == "twomeans"){
    #Find yc =
    f1c <- mean(f1,na.rm=na.rm)  
    # Top point in x
    #X
    f2cH <- mean(f2[f1 > f1c ],na.rm=na.rm)
    
    #Bottom point
    #X
    f2cL <- mean(f2[f1 < f1c ],na.rm=na.rm)
    
    f2c = mean(c(f2cH,f2cL))
    #Now we have the center.. xc,xy
  }
  
  if(method == "wcentroid"){
    #Find yc =
    f1c <- mean(f1,na.rm=na.rm)  
    f2c <- mean(f2[f1 < f1c ],na.rm=na.rm)
    #Now we have the center.. xc,xy
  }
  
  return(list("f2"=f2c,"f1"=f1c))
}


##' Computes vector norms for vowels in the vowel space. The vowel space is constructed by the supplied F1 and F2 formant values.
##'
##' @author Fredrik Karlsson
##' @export
##' 
##' @param f1 A vector of F1 values.
##' @param f2 A vector of F2 values.
##' @param na.rm Boolean value specifying whether missing values should be removed. Defaults to TRUE.
##' @param center A vector (F2,F1) specifying the vowel space center to be used. If NULL, the center will be calculated using the \code{\link{vowelspace.center}} function.
##' @param center.method The method to use in the calculation of vowel space center. See \code{\link{vowelspace.center}} for details.
##'
##' @return A vector containing the vector length of each vowel space vector drawn from the origin of teh computed vowel space center coordinates.
##' 
##' @references
##' 
##' \insertRef{Karlsson:2012vb}{articulated}
##' 
##' @examples
##' data(pb)
##' with(pb,vowel.norms(F1,F2))
##'
##' @keywords misc utilities arith
##' @seealso See \code{\link{vector.space}} for details concerning the computations.

vowel.norms <- function(f1,f2,na.rm=TRUE,center=NULL,center.method="wcentroid"){
  
  vs <- vector.space(f1,f2,na.rm=na.rm,center=center,center.method=center.method)
  out <- vs[["Vector norms"]]
  return(out)
}

##' Computes corners of a vowel space. The vowel space is constructed from the supplied F1 and F2 formant values for vowels in the space.

##' @author Fredrik Karlsson
##' @export
##' 
##' @param f1 A vector of F1 values.
##' @param f2 A vector of F2 values.
##' @param na.rm Boolean value specifying whether missing values should be removed. Defaults to TRUE.
##' @param center A vector (F2,F1) specifying the vowel space center to be used. If NULL, the center will be calculated using the \code{\link{vowelspace.center}} function.
##' @param center.method The method to use in the calculation of vowel space center. See \code{\link{vowelspace.center}} for details.
##'
##' @return A vector containing the vector length of each vowel space vector drawn from the origin of teh computed vowel space center coordinates.
##' 
##' @references Karlsson, F., & van Doorn, J. (2012). Vowel formant dispersion as a measure of articulation proficiency. The Journal of the Acoustical Society of America, 132(4), 2633–2641. doi:10.1121/1.4746025
##' 
##' @examples
##' data(pb)
##' with(pb,vowelspace.corners(F1,F2))
##'
##' @keywords misc utilities arith
##' @seealso See \code{\link{vector.space}} for details concerning the computations.

vowelspace.corners <- function(f1,f2,na.rm=TRUE,center=NULL,center.method="wcentroid"){
  
  vs <- vector.space(f1,f2,na.rm=na.rm,center=center,center.method=center.method)
  out <- vs[["Corner vowels"]]
  return(out)
}


##' Computes vector angles of vowel vectors of vowels.The vowel space is constructed by the supplied F1 and F2 formant values.
##' 
##' @author Fredrik Karlsson
##' @export
##' 
##' @param f1 A vector of F1 values.
##' @param f2 A vector of F2 values.
##' @param na.rm Boolean value specifying whether missing values should be removed. Defaults to TRUE.
##' @param center A vector (F2,F1) specifying the vowel space center to be used. If NULL, the center will be calculated using the \code{\link{vowelspace.center}} function.
##' @param center.method The method to use in the calculation of vowel space center. See \code{\link{vowelspace.center}} for details.
##'
##' @return A vector containing the vector angles of each vowel space vector drawn from the origin of teh computed vowel space center coordinates.
##' 
##' @references
##' 
##' \insertRef{Karlsson:2012vb}{articulated}
##' 
##' @examples
##' data(pb)
##' with(pb,vowel.angles(F1,F2))
##' with(with(pb,data.frame(angle=vowel.angles(F1,F2),vowel=Vowel)),tapply(angle,list(vowel),mean,na.rm=TRUE))
##'
##' @keywords misc utilities arith
##' @seealso See \code{\link{vector.space}} for details concerning the computations.

vowel.angles <- function(f1,f2,na.rm=TRUE,center=NULL,center.method="wcentroid"){
  
  vs <- vector.space(f1,f2,na.rm=na.rm,center=center,center.method=center.method)
  out <- vs[["Vector angles"]]
  return(out)
}

##' Computes properties for the vowel space constructed by the supplied F1 and F2 formant values.
##'
##' @author Fredrik Karlsson
##' @export
##'
##' @param f1 A vector of F1 values.
##' @param f2 A vector of F2 values.
##' @param na.rm Boolean value specifying whether missing values should be removed. Defaults to TRUE.
##' @param output List of vowel properties to be returned. Could be one or many of "center","norms","angles","whichvowelcorner","corners","meanvectors","areas" or "vsa". All values are returned by default.
##' @param center A vector (F2,F1) specifying the vowel space center to be used. If NULL, the center will be calculated using the \code{\link{vowelspace.center}} function.
##' @param center.method The method to use in the calculation of vowel space center. See \code{\link{vowelspace.center}} for details.
##' @param minimum.no.vectors The minimum number of vectors needed for a mean vector to be computed.
##'
##' @return A list containing the properties specified by the "output" argument.Could be one or many of
##' \item{F1 center}{Computed vowel space center vowel's F_1 values}
##' \item{F2 center}{Computed vowel space center vowel's F_2 values}
##' \item{Vector norms}{Length of all supplied vowel vectors}
##' \item{Vector angles}{Angles of all supplied vowel vectors}
##' \item{Which vowel corner}{A factor indicating in which corner of the vowel space each vowel is located.}
##' \item{Corner vowels}{Data frame of corner vowels F_1 and F_2 values}
##' \item{Mean vectors}{Data frame of corner vowels as vector norms and angles}
##' \item{Triangle areas}{Individual triangle areas}
##' \item{VSA(n)}{Vowel space area. The 'n' indicates the number of corners in the vowel space.}
##'
##' @examples
##' 
##' vsdata <- data.frame(F1=c(rnorm(100,mean=300,sd=100),rnorm(100,mean=600,sd=100),rnorm(100,mean=600,sd=100),rnorm(100,mean=300,sd=100)),F2=c(rnorm(100,mean=2200,sd=200),rnorm(100,mean=1700,sd=200),rnorm(100,mean=1000,sd=200),rnorm(100,mean=900,sd=200)),Vowel=rep(c("i","ae","a","u"),c(100,100,100,100)))
##' outvs <- vector.space(vsdata$F1,vsdata$F2)
##' summary(outvs)
##' 
##' @references
##' 
##' \insertRef{Karlsson:2012vb}{articulated}
##' 
##' @keywords misc utilities arith

vector.space <- function(f1,f2,na.rm=TRUE,output=c("center","norms","angles","whichvowelcorner","corners","meanvectors"),center=NULL,center.method="wcentroid",minimum.no.vectors=3){
  
  if(is.null(center)){
    center <- vowelspace.center(f2,f1,method=center.method)
  }
  f2c <- center$f2
  f1c <- center$f1
  
  Rnorm <- sqrt( (f1-f1c)^2 + (f2-f2c)^2)
  Rangle <- atan2( (f1-f1c), (f2-f2c) )
  
  #Now compute mean vectors
  df <- data.frame(f1=f1,f2=f2,norm=Rnorm,angle=Rangle)
  names(df) <- c("f1","f2","norm","angle")
  df <- na.omit(df)
  
  vowelcorners <- cut(df$angle,breaks=c(-pi,-pi/2,0,pi/2,pi),labels=c("[u]-corner","[i]-corner","[ae]-corner","[a]-corner"),include.lowest = TRUE)
  vowelcorners <- as.factor(vowelcorners)
  cornersDF <- data.frame("f2"=c(),"f1"=c())
  meanVectors <- data.frame("norm"=c(),"angle"=c())
  areas <- c()
  prevNorm <- NULL
  prevAngle <- NULL
  for(currcorner in levels(vowelcorners)){
    cornerSel <- as.character(vowelcorners) == as.character(currcorner)
    selAngles <- df$angle[cornerSel]
    #Now, check where they are on a normal distribution
    selAnglesP <- pnorm( selAngles,sd=sd(selAngles),mean=mean(selAngles))
    #GEt mean vectors
    if(length(selAngles[ abs(selAnglesP - 0.5) < 0.25] ) > 0){
      #THIS IS WRONG!
      #Do not compute a mean vector if the number of vectors is < minimum.no.vectors
      #  print(length(cornerSel[cornerSel]))
      if(length(cornerSel[cornerSel]) > minimum.no.vectors){
        norm <- mean(df$norm[cornerSel ],na.rm=TRUE)
        angle <- mean(df$angle[cornerSel],na.rm=TRUE)
        #Store the mean vectors
        meanVectors <- rbind(meanVectors,c(norm,angle))
        #Compute points for the vowel quadrilateral
        cornersDF <- rbind(cornersDF,c(norm * cos(angle) + f2c ,norm * sin(angle) + f1c))
      }
      
    }
  }
  
  if(length(cornersDF) > 0){
    names(cornersDF) <- c("f2","f1")
  }
  if(length(meanVectors) > 0){ 
    names(meanVectors) <- c("norm","angle")
  }
  
  center <- list("F1 center"=f1c,"F2 center"=f2c)
  norms <- list("Vector norms"=Rnorm)
  angles <- list("Vector angles"=Rangle)
  whichvowelcorner <- list("Which vowel corner"=vowelcorners)
  meanvectors <-list("Mean vectors"=meanVectors)
  corners <-list("Corner vowels"=cornersDF)
  
  
  #Prepare output
  out <- list()
  for(curr in output){
    #Explicity
    if(curr %in% c("center","norms","angles","whichvowelcorner","corners","meanvectors" )){
      out <- c(out,get(curr))
    } 
  }
  
  return(out)
  
}


#' Compute the Vowel space density from formant values
#' 
#' This function computes the Vowel space density from a vector of F_1 and F_2 measurements based on the algorithm of 
#' \insertCitation{Story.2017.10.1121/1.4983342}{articulated}.
#'
#' @param F2 A vector of F2 formant frequency measurements, one for each measure vowel.
#' @param F1 A vector of F1 formant frequency measurements, one for each measure vowel.
#' @param resolution The distance on the normalized F2-F1 space within which vowels will be counted towards the tally of vowels in close proximity for the point. 
#' @param grid.res The spectral resolution of the analysis.
#' @param density.threshold The fraction of the maximum density of vowels below which the density will be considered zero.
#' 
#'
#' @return
#' An object of class [geometry::convhulln] consisting of 
#' \begin{description}
#'  \item{p}{A matrix of median normalized vowel space coordinates (F2,F1)}
#'  \item{hull}{An n x 2 matrix giving the indicies of vowels in [p] which form the points holding up the convex hull}
#'  \item{area}{The computed area of the convex hull around the vowel space made up of portions of the vowel space with a high enough distribution of vowels}
#'  \item{vol}{The computed vowlume of the shape around the vowel space distribution}
#' \end{description}
#' @export
#' @references 
#'  \insertAllCited{}
#'  
#'  @examples 
#'  data(pb)
#'  VSD(pb[,"F2"],pb[,"F1"]) -> ch
#'  #Simple but informative plot
#'  plot(ch,xlab="<-Back / Front -> (F2)",ylab="<-Closed / Open -> (F1)")

VSD <-  function(F2, F1,resolution=0.05,grid.res=0.01,density.threshold=0.25){
  F1med <- median(F1,na.rm=TRUE)
  F2med <- median(F2,na.rm=TRUE)
  
  F1adj <- (F1 - F1med) / F1med
  F2adj <- (F2 - F2med) / F2med
  nVowels <- length(F1adj)
  
  
  #Place a point in the center of a grid of "grid.res" size
  gridx <- seq(-1+(grid.res/2),1.5,grid.res)
  gr <- expand.grid(F1=gridx,F2=gridx)
  #Get distance matrix between the points in the two different vectors
  d <- Rfast::dista(data.frame(F2adj,F1adj), gr[,c("F2","F1")],type="euclidean") 
  gr$count <- apply(d,2,function(x,res=resolution) {sum(x <=res,na.rm=TRUE) })
  #Normalize to 0-1 to get a dist
  gr$count <- gr$count / max(gr$count)
  gr$count <- ifelse(gr$count >= density.threshold, gr$count, NA)    
  gr <- na.omit(gr)
  
  if(nrow(gr) > 0){
    ch <- geometry::convhulln(gr[c("F2","F1")],output.options=c("p","hull","area"), options="FA")
    
  }else{
    ch <- NA
  }
  return(ch)
}

#' Compute the Vowel space area using continuously measured formant frequency
#' values
#'
#' This function implements the algorithm proposed by
#' \insertCite{Sandoval.2013.10.1121/1.4826150}{articulated}, which takes
#' continous measurements of formant frequencies for a speaker and computes the
#' vowel space area from the convex hull of them, once spurious measurements
#' have been removed using a likelihood threshold applied to the result of a
#' Gaussian mixture model (GMM).
#' 
#' The GMM and convex hull computations are both based on computed euclidean distances between vowels.
#'
#' @param F2 A vector of F2 formant frequency measurements, one for each measure vowel.
#' @param F1 A vector of F1 formant frequency measurements, one for each measure vowel.
#' @param vowel_categories The number of vowel categories we should consider, which translates to the number of gaussian mixture components in the GMM. 
#' @param threshold The threshold of the likelihood that the vowel formant frequency measurement must meet in order to be included in the convex hull.
#' @param center Should the formant frequency measurements be centered using the mean frequency? This was not done in the original implementation.
#' @param scale Should the formant frequency measurements be scaled to a 0-1 scale using the standard deviation of the formant frequencies? This was not done in the original implementation.
#'
#' @return
#' An object of class [geometry::convhulln] consisting of 
#' \begin{description}
#'  \item{p}{A matrix of median normalized vowel space coordinates (F2,F1)}
#'  \item{hull}{An n x 2 matrix giving the indicies of vowels in [p] which form the points holding up the convex hull}
#'  \item{area}{The computed area of the convex hull around the vowel space made up of portions of the vowel space with a high enough distribution of vowels}
#'  \item{vol}{The computed vowlume of the shape around the vowel space distribution}
#' \end{description}
#' @export
#' @references 
#'  \insertAllCited{}
#'  
#'  @examples 
#'  data(pb)
#'  cVSA(pb[,"F2"],pb[,"F1"]) -> ch
#'  #Simple but informative plot
#'  plot(ch,xlab="<-Back / Front -> (F2)",ylab="<-Closed / Open -> (F1)")

cVSA <- function(F2, F1, vowel_categories=5,threshold=0.3,center=FALSE,scale=FALSE){
  fdf <- data.frame("F2"=F2,"F1"=F1)
  if(center | scale){
    fdf <- ClusterR::center_scale(fdf, center=center,scale=scale)  
  }
  
  clo <- ClusterR::GMM(fdf,gaussian_comps = vowel_categories, dist_mode="eucl_dist")
  #This predicts clusters too, but that is not needed now.
  #pr = ClusterR::predict_GMM(fdf, clo$centroids, clo$covariance_matrices, clo$weights)
  #Keep only measurements with a likelihood above the threshold (0.3 in the original publication)
  fVector <- exp(clo$Log_likelihood) >= threshold*exp(clo$Log_likelihood)
  #Filter out unwanted vowel measurements
  gr <- na.omit(fdf[fVector,])

  if(nrow(gr) > 0){
    ch <- geometry::convhulln(gr[c("F2","F1")],output.options=c("p","hull","area"), options="FA")
    
  }else{
    ch <- NA
  }
  return(ch)
}
