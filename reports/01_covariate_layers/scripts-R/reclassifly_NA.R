library(raster)
library(terra)
tiles0 <- raster::stack("reports/01_covariate_layers/data/export_europe_layers_30m_int_256.tif") 

tiles1 <- reclassify(tiles0[[1]], cbind(-256, NA))
tiles2 <- reclassify(tiles0[[2]], cbind(-256, NA))

tiles_final <-stack(tiles1,tiles2)

tile_list <- list()
nlayers(tiles0) 

for (i in 1:nlayers(tiles0)){
  tile <- reclassify(tiles0[[i]], cbind(-256, NA))
  tile_list[[i]] <- tile

}

tiles_stack <- stack(tile_list)
tiles_rast <- terra::rast(tiles_stack)

writeRaster(tiles_rast, "reports/01_covariate_layers/data/test_stack.tif",overwrite=TRUE)
