#------------------------------------------------------#
# 6. Calculate area of applicability (AOA) ####
#------------------------------------------------------#

library(CAST)
library(caret)
#library(terra)
library(raster)
library(tidyverse)

print(sessionInfo())

args <- commandArgs(trailingOnly=T)
import_model <- args[1]
import_DI <- args[2]
import_tile <- args[3]
tile_fornames <- args[4]
output_aoa <- args[5]

# import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# import_DI <- "reports/03_modelling/snakesteps/05_DI/model_spatial_trainDI.rds"
# import_tile <- "reports/03_modelling/tiles/tile1-3.tif"
# tile_fornames <- "reports/03_modelling/tiles/export_uk_layers_30m-0000000000-0000046080.tif"
# import_pred <- "reports/03_modelling/snakesteps/04_output/pred_0_30cm_t_ha_tile1-3.tif" # this is just to visualize
# output_aoa <- "reports/03_modelling/snakesteps/06_AOA/tile1_1_aoa.rds"
# 
# import_DI <- "reports/03_modelling/output/aoa_results.rds"
# output_aoa <- "reports/03_modelling/output/tile1_3_aoa.rds"
#output_aoa <- "reports/03_modelling/output/tile1_3_aoa.tif"

trainDI <- readRDS(import_DI)
final_model <- readRDS(import_model)
tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)
#predictions <- raster::stack(import_pred)

#rename cropped tile from original tile (cropping changed the layer names)
orig_names <- names(tile_fornames)
names(tile_layers) <- orig_names

###### Depth at .10 m = 10cm #####

Depth_to_predict_0m <- raster::raster(vals = 0.15, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0m) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers <- addLayer(tile_layers, Depth_to_predict_0m)



#a = readRDS("reports/03_modelling/output/tile1_1_aoa.rds")
a = CAST::aoa(newdata = predictor_layers, model = final_model, trainDI = trainDI)

#saveRDS(a, output_aoa)


aoa_layer <- a$AOA
writeRaster(x = aoa_layer, filename = output_aoa, format = "GTiff")

# plot(a$AOA)

# test_AOA <- a$AOA
# test_AOA[test_AOA == 1] = NA
# 
# par(mfrow = c(1, 2))
# plot(predictions)
# plot(test_AOA, xmin = extent(predictions$pred_0_30cm)[1],
#      xmax = extent(predictions$pred_0_30cm)[2],
#      ymin = extent(predictions$pred_0_30cm)[3],
#      ymax = extent(predictions$pred_0_30cm)[4])
# 

