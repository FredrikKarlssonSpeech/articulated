missing_vec <- function(x,what.na=0){
  if(is.numeric(what.na)){
    if(length(what.na) > 1) stop("You cannot supply more than one cut off value.")
    isNA <- ( x <= what.na) | is.na(x) | is.null(x)
    
  }
  
  if(is.character(what.na)){
    
    isNA <- ( x %in% what.na) | is.na(x) | is.null(x)
    
  }
  return(isNA)
}


missing_frac <- function(x,what.na=0){
  isNA <- superassp::missing_vec(x,what.na=what.na)
  #Here we are exploiting the fact that TRUE sums to 1
  return(sum(isNA) / length(isNA))
} 

left_changepoint <- function(x,what.na=0){
  m <- missing_vec(x,what.na=what.na)
  dm <- base::diff(m,lag=1,differences=1)
  cp <- head(which(abs(dm) > 0,arr.ind=TRUE),1)
  if(length(cp) == 0) {
    cp <- NA
  }
  return(cp  )
}

right_changepoint <- function(x,what.na=0){
  m <- missing_vec(x,what.na=what.na)
  dm <- base::diff(m,lag=1,differences=1)
  cp <- tail(which(abs(dm) > 0,arr.ind=TRUE),1)
  if(length(cp) == 0) {
    cp <- NA
  }
  return(cp  )
}

peak_prominence <- function(inVec,what.na=0){
  missing <- missing_vec(inVec,what.na=what.na)
  not_missing <- inVec[!missing]
  l <- lm(y ~ x, data= data.frame(y=inVec,x=seq_along(inVec)))
  return(max(resid(l)))
}

lm_slope <- function(inVec,what.na=0){
  missing <- missing_vec(inVec,what.na=what.na)
  not_missing <- inVec[!missing]
  l <- lm(y ~ x, data= data.frame(y=inVec,x=seq_along(inVec)))
  slope <- coefficients(l)[["x"]]
  return(slope)
}

