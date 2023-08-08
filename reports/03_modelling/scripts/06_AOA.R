#------------------------------------------------------#
# 5. Calculate area of applicability (AOA) ####
#------------------------------------------------------#

library(CAST)
library(caret)
library(terra)
library(raster)
library(tidyverse)

args <- commandArgs(trailingOnly=T)
import_model <- args[1]
tile_fornames <- args[2]
import_tile <- args[3]
pred_0_30 <- args[4]
pred_30_100 <- args[5]

import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
trainDI <- readRDS("reports/03_modelling/output/aoa_results.rds")
final_model <- readRDS(import_model)
import_tile <- "reports/03_modelling/tiles/tile1-1.tif"
tile_fornames <- "reports/03_modelling/tiles/export_uk_layers_30m-0000000000-0000046080.tif"
import_pred <- "reports/03_modelling/output/pred_0_30cm.tif"

tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)
predictions <- raster::stack(import_pred)

#rename cropped tile from original tile (cropping changed the layer names)
names(tile_layers) <- names(tile_fornames)


###### Depth at 0 m #####

Depth_to_predict_0m <- raster(vals = 0, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0m) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers <- addLayer(tile_layers, Depth_to_predict_0m)



a = CAST::aoa(newdata = predictor_layers, model = final_model, trainDI = trainDI)

saveRDS(a, "reports/03_modelling/output/tile1_1_aoa.rds")

plot(a$AOA)

test_AOA <- a$AOA
test_AOA[test_AOA == 1] = NA

plot(predictions)
plot(test_AOA)
