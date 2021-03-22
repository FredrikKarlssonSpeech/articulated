hz2st <- function(f){
  st <- 12*log2(f / 16.352)
  return(st)
}

fonetogram <- function(soundFile){
  #soundFile <- "~/Desktop/F+A.wav"
  wrassp::ksvF0(soundFile,toFile = FALSE) -> f0
  pitch <- f0$F0
  pitch[pitch == 0] <- NA
  wrassp::rmsana(soundFile,toFile=FALSE,linear=FALSE) -> rms
  binz <- 5
  st <-  round(hz2st(pitch)/binz,digits = 0) * binz
  rms <- round(rms$rms[,1]/binz,digits = 0) * binz
  
  dat <- data.frame(amp=rms,pitch=st)
  dat %>%
    filter(!is.na(pitch)) %>%
    group_by(amp,pitch) %>%
    summarise(n=n()) %>%
    ggplot(.,aes(y=amp,x=pitch)) +
    geom_tile(aes(fill=n)) +
    geom_convexhull(alpha=0.5,fill="lightgrey") +
    theme_bw() +
    labs(fill="",x="Pitch (Semitones)",y="Amplitude (dB)")
  
  
  
}
