#script to combined tiled exports from Google Earth Engine
# test using small number, to apply to all on HPC
# tlgm2@cam.ac.uk
# 22.05.23

library(raster)
library(terra)
library(gdalUtilities)
library(viridis) # color map


##### trying Florian's script #####

rast_dir <- "//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK"
list_dir <- as_tibble(dir(rast_dir))

tmp <- list_dir
tmp_l <- list() #creating an empty list

for (b in 1:nrow (tmp)){
  tmp_l[b]<- rast (file.path(rast_dir, tmp[b,1])) #filling the list with all tiles in the directory
}

tmp_c <- sprc(tmp_l) # turning into spatRasterCollection




##### 1. import all files ####

# rastlist <- list.files(path = "reports/01_covariate_layers/data/tiles_test/", pattern='.tif$', 
#                        all.files=TRUE, full.names=FALSE)

#note: need to be directory where .tif files live

setwd("C:/Users/Tania/Desktop/tiles_test_desktop/subset")

rastlist <- list.files(pattern='.tif$', 
                       all.files=TRUE, full.names=FALSE)

gdalbuildvrt(gdalfile = rastlist, 
             output.vrt = "tiles_subset.vrt", dryrun =  T)

gdal_translate(src_dataset = "tiles_subset.vrt",
               dst_dataset = "tiles_subset_translate.tif",
               co = "COMPRESS=LZW", dryrun = T)

gdalwarp(srcfile = "tiles_subset.vrt",
               dstfile = "tiles_subset_warp.tif",
               co = "COMPRESS=LZW", dryrun =  T)

# need to get names of 
allrasters <- lapply(rastlist, terra::rast)
layer_names <- names(allrasters[[1]])

merged_raster <- do.call(raster::merge, c(allrasters))
##### 2. import the merged .tif file ####

## from using gdal 
merged_gdal <- raster::stack("tiles_subset.tif")
names(merged_gdal) <- layer_names
print(merged_gdal)


summary(allrasters[[2]]$maxTemp)
summary(merged_gdal$maxTemp)
summary(merged_raster$maxTemp)

raster::plot(merged_gdal$maxTemp, 
          main = names(merged_gdal$maxTemp),
          xlim = c(raster::xmin(merged_gdal), raster::xmax(merged_gdal)),
          ylim = c(raster::ymin(merged_gdal), raster::ymax(merged_gdal)),
          xlab = "Latitude",
          ylab = "Longitude",
          col= viridis(n = 3, option = "D"))


png(filename = "merged_raster_maxTemp.png",
                          res = 120,
                          width = 900, height = 300)

raster::plot(merged_raster$maxTemp, 
             main = names(merged_raster$maxTemp),
             xlim = c(raster::xmin(merged_raster), raster::xmax(merged_raster)),
             ylim = c(raster::ymin(merged_raster), raster::ymax(merged_raster)),
             xlab = "Latitude",
             ylab = "Longitude",
             col= viridis(n = 5, option = "D"))
dev.off()

png(filename = "raster_plot1_maxTemp.png",
                          res = 120,
                          width = 923, height = 465)

raster::plot(allrasters[[1]]$maxTemp,
             main = names(allrasters[[1]]$maxTemp),
             xlim = c(raster::xmin(allrasters[[1]]), raster::xmax(allrasters[[1]])),
             ylim = c(raster::ymin(allrasters[[1]]), raster::ymax(allrasters[[1]])),
             xlab = "Latitude",
             ylab = "Longitude",
             col= viridis(n = 5, option = "D"))

dev.off()


rasters_stack <-lapply(rastlist, raster::stack)

raster_mean <- stackApply(rasters_stack, indices = nlayers(), fun =median )


