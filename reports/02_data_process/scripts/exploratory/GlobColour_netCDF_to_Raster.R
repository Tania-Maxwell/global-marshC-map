# load package
library(sp)
library(raster)
library(ncdf4)

setwd("C:/Users/Tania/Desktop/For_GEE_upload/GlobColour/files")

rlist=list.files(getwd(), pattern="nc$", full.names=FALSE)
rlist <- data.frame(rlist)

rlist$year <- as.numeric(as.character(substr(rlist$rlist, 5, 8)))   

# read ncdf file

yrs <- unique(rlist$year)

for(j in 1:9){
  
  rlist_sub <- subset(rlist, year == yrs[j]) 
  
  out<-list()
  
  for(i in 1:nrow(rlist_sub)){
    
    
    fn <- (rlist_sub[i,1])
    nc<-nc_open(fn)
    
    out[[i]] <- raster(fn, varname = "TSM_mean")
    
  }
  
  files_stack <- stack(out)
  meanSST = calc(files_stack, mean, na.rm = T)
  
  nm <- paste0("GlobColourMeanTSM_",yrs[j],".tif")
  
  setwd("C:/Users/Tania/Desktop/For_GEE_upload/GlobColour/years")
  writeRaster(meanSST, filename = nm)
  setwd("C:/Users/Tania/Desktop/For_GEE_upload/GlobColour/files")
  
}



# load package
library(sp)
library(raster)

setwd("C:/Users/Tania/Desktop/For_GEE_upload/GlobColour/years")

rlist0=list.files(getwd(), pattern="tif$", full.names=FALSE)
rlist1 <- data.frame(rlist0)
rlist2 <- rlist1[-10,]
rlist <- data.frame(rlist2)


out<-list()

for(i in 1:nrow(rlist)){
  
  out[[i]] <- raster(as.character(rlist[i,1]))
  
}

files_stack <- stack(out)
meanTSM = calc(files_stack, mean, na.rm = T)  

setwd("C:/Users/Tania/Desktop/For_GEE_upload/GlobColour")

writeRaster(meanTSM, filename = "GlobColoursMeanTSM_2003_2011.tif")


