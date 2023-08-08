## clip tiles for snakemake test

library(raster)


import_tile <- "reports/03_modelling/data/export_uk_layers_30m-0000009216-0000036864.tif"
tile_layers <- raster::stack(import_tile)

e <- as(extent(-4.83903, -2.355368, 54.76412, 57.24778), 'SpatialPolygons')
tile1 <- as(extent(-4.83903, -3.90000, 54.76412, 55.13000), 'SpatialPolygons')
tile2 <- as(extent(-4.83903, -3.90000, 55.13000, 55.50000), 'SpatialPolygons')
tile3 <- as(extent(-3.90000, -3.00000, 54.76412, 55.13000), 'SpatialPolygons')
tile4 <- as(extent(-3.90000, -3.00000, 55.13000, 55.50000), 'SpatialPolygons')

crs(tile1) <- crs(tile_layers, proj = TRUE)
crs(tile2) <- crs(tile_layers, proj = TRUE)
crs(tile3) <- crs(tile_layers, proj = TRUE)
crs(tile4) <- crs(tile_layers, proj = TRUE)

raster1 <- crop(tile_layers, tile1)
raster2 <- crop(tile_layers, tile2)
raster3 <- crop(tile_layers, tile3)
raster4 <- crop(tile_layers, tile4)


writeRaster(raster1, "reports/01_covariate_layers/data/tiles_crop/tile1-1.tif",format="GTiff")
writeRaster(raster2, "reports/01_covariate_layers/data/tiles_crop/tile1-2.tif",format="GTiff")
writeRaster(raster3, "reports/01_covariate_layers/data/tiles_crop/tile1-3.tif",format="GTiff")
writeRaster(raster4, "reports/01_covariate_layers/data/tiles_crop/tile1-4.tif",format="GTiff")
