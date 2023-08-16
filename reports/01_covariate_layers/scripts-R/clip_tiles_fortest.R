## clip tiles for snakemake test

library(raster)


import_tile <- "reports/03_modelling/tiles/export_the_wash_ENG.tif"
tile_layers <- raster::stack(import_tile)

e <- as(extent(-0.002155957, 0.2207161,52.82848, 52.94625), 'SpatialPolygons')
tile1 <- as(extent(-0.002155957, 0.1092801, 52.82848, 52.88737), 'SpatialPolygons')
tile2 <- as(extent(-0.002155957, 0.1092801, 52.88737, 52.94625), 'SpatialPolygons')
tile3 <- as(extent(0.1092801, 0.2207161, 52.82848, 52.88737), 'SpatialPolygons')
tile4 <- as(extent(0.1092801,0.2207161, 52.88737, 52.94625), 'SpatialPolygons')

crs(tile1) <- crs(tile_layers, proj = TRUE)
crs(tile2) <- crs(tile_layers, proj = TRUE)
crs(tile3) <- crs(tile_layers, proj = TRUE)
crs(tile4) <- crs(tile_layers, proj = TRUE)

raster1 <- crop(tile_layers, tile1)
raster2 <- crop(tile_layers, tile2)
raster3 <- crop(tile_layers, tile3)
raster4 <- crop(tile_layers, tile4)


writeRaster(raster1, "reports/03_modelling/tiles/tile1-1.tif",format="GTiff")
writeRaster(raster2, "reports/03_modelling/tiles/tile1-2.tif",format="GTiff")
writeRaster(raster3, "reports/03_modelling/tiles/tile1-3.tif",format="GTiff")
writeRaster(raster4, "reports/03_modelling/tiles/tile1-4.tif",format="GTiff")
