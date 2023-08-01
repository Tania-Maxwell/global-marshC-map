# script to create polygon mask of saltmarsh extent
# import 

library(raster)
library(terra)

mask_europe <- raster("reports/03_modelling/data/europe_mask.tif")

#mask_europe <- site_for_mask[[1]] #extracting 1 layer from raster stack, which is inately the saltmarsh extent
#values(mask_europe)[!is.na(values(mask_europe))] <- 1
mask_final <- st_as_sf(rasterToPolygons(mask_europe, fun=function(x){x==1}, dissolve=TRUE))

                 crs = terra::crs(site_predictors, proj = TRUE)) #NOTE:mask needs the same CRS as samplepoints for the nndm() function
