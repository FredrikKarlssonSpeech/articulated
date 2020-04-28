
##' Computes the center of a vowel space.
##'
##' @author Fredrik Karlsson
##' @export
##' 
##' @param x The F_2 values of vowels.
##' @param y The F_1 values of vowels.
##' @param method The method to use. Could be either one of "centroid" or "twomeans" (the default).
##' @param na.rm Boolean indicating whether NA:s should be removed in teh caluclations of mean values.
##'
##' @return A vector containing the F_2 and F_1 values of the vowel space center.
##'
##' @note Two methods are implemented. In the default method, a mean F_1 value are calculated in an initial stage, and separate F_2 means are then computed for points above a line y=mean(F_1), and one mean for values below that line. The F_2 value for the center point is then computed as the mean of the upper and lower mean F_2 values. The "wcentroid" method simply averages the F_2 and F_1 values and return that as the center point. The first method is preferable, as vowel spaces in a triangular shape are otherviwe quite likelly to have center points outside of the vowel triangle.
##' 
##' @references Karlsson, F., & van Doorn, J. (2012). Vowel formant dispersion as a measure of articulation proficiency. The Journal of the Acoustical Society of America, 132(4), 2633–2641. doi:10.1121/1.4746025
##'
##'
##' @keywords misc utilities

vowelspace.center <- function(x,y,method="wcentroid",na.rm=TRUE){
  if(method == "centroid"){
    xc <- mean(x,na.rm=na.rm)
    yc <- mean(y,na.rm=na.rm)
  }
  
  if(method == "twomeans"){
    #Find yc =
    yc <- mean(y,na.rm=na.rm)  
    # Top point in x
    #X
    xcH <- mean(x[y > yc ],na.rm=na.rm)
    
    #Bottom point
    #X
    xcL <- mean(x[y < yc ],na.rm=na.rm)
    
    xc = mean(c(xcH,xcL))
    #Now we have the center.. xc,xy
  }
  
  if(method == "wcentroid"){
    #Find yc =
    yc <- mean(y,na.rm=na.rm)  
    xc <- mean(x[y < yc ],na.rm=na.rm)
    #Now we have the center.. xc,xy
  }
  
  return(c(xc,yc))
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
##' @references Karlsson, F., & van Doorn, J. (2012). Vowel formant dispersion as a measure of articulation proficiency. The Journal of the Acoustical Society of America, 132(4), 2633–2641. doi:10.1121/1.4746025
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
##' @references Karlsson, F., & van Doorn, J. (2012). Vowel formant dispersion as a measure of articulation proficiency. The Journal of the Acoustical Society of America, 132(4), 2633–2641. doi:10.1121/1.4746025
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
##' @keywords misc utilities arith

vector.space <- function(f1,f2,na.rm=TRUE,output=c("center","norms","angles","whichvowelcorner","corners","meanvectors"),center=NULL,center.method="wcentroid",minimum.no.vectors=3){
  
  if(is.null(center)){
    center <- vowelspace.center(f2,f1,method=center.method)
  }
  f2c <- center[1]
  f1c <- center[2]
  
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


