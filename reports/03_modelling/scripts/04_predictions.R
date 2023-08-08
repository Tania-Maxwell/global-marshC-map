#------------------------------------------------------#
# 4. Run predictions ####
#------------------------------------------------------#

rm(list=ls()) # clear the workspace
library(tidyverse)
library(raster)

args <- commandArgs(trailingOnly=T)
import_model <- args[1]
tile_fornames <- args[2]
import_tile <- args[3]
pred_0_30 <- args[4]
pred_30_100 <- args[5]


# import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# tile_fornames <- "reports/03_modelling/tiles/export_uk_layers_30m-0000000000-0000046080.tif"
# import_tile <- "reports/01_covariate_layers/data/tiles_crop/tile1.tif"
# pred_0_30 <- "reports/03_modelling/snakesteps/04_output/test_prediction_0_30cm_t_ha_global.tif"
# pred_30_100 <- "reports/03_modelling/snakesteps/04_output/test_prediction_30_100cm_t_ha_global.tif"

############## 4.1 Import tiles data ####################
tile_layers <- raster::stack(import_tile)
tile_fornames <- raster::stack(tile_fornames)
names(tile_layers) <- names(tile_fornames)



## first, we need to define the depth at which we want to predict SOC_g_cm3
## then, create a new raster layer (Depth_to_predict) with this value, using the raster info from tile_layers
## and ADD a raster layer of this value to the raster stack of environmental 


############## 4.2 Prepare layers at specific depths ####################

###### Depth at 0 m #####

Depth_to_predict_0m <- raster(vals = 0, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0m) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
tile_layers_forpred_0m <- addLayer(tile_layers, Depth_to_predict_0m)



###### Depth at 0.30 m #####

Depth_to_predict_30m <- raster(vals = 0.3, #depth at which we want to predict
                               nrow = nrow(tile_layers), 
                               ncol = ncol(tile_layers),
                               crs = crs(tile_layers),
                               ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_30m) <- "Depth_midpoint_m"

# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
tile_layers_forpred_30m <- addLayer(tile_layers, Depth_to_predict_30m)
   

###### Depth at 1 m #####

Depth_to_predict_1m <- raster(vals = 1, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_1m) <- "Depth_midpoint_m"

# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
tile_layers_forpred_1m <- addLayer(tile_layers, Depth_to_predict_1m)

############## 4.3 Import model ####################
final_model <- readRDS(import_model)



############## 4.4 Run predictions for SOC density ####################
prediction_0m <- predict(tile_layers_forpred_0m, final_model)

prediction_30m <- predict(tile_layers_forpred_30m, final_model)

prediction_1m <- predict(tile_layers_forpred_1m, final_model)
#plot(prediction_1m)



############## 4.4 Calculate SOC stocks ####################

### 0-30 cm

prediction_0_30cm_avg <- mean(prediction_0m, prediction_30m)

prediction_0_30cm_g_cm2 <- prediction_0_30cm_avg*30 #multiply by 30cm  = layer thickness 

prediction_0_30cm_t_ha <- prediction_0_30cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 


### 30-100 cm

prediction_30_100cm_avg <- mean(prediction_30m, prediction_1m)

prediction_30_100cm_g_cm2 <- prediction_30_100cm_avg*70 #multiply by 30cm  = layer thickness 

prediction_30_100cm_t_ha <- prediction_30_100cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 


#### 0-100 cm

prediction_0_100cm_t_ha <- sum(prediction_0_30cm_t_ha, prediction_30_100cm_t_ha)


############## 4.5 export  ####################

writeRaster(prediction_0_30cm_t_ha, filename = pred_0_30, format = "GTiff")
writeRaster(prediction_30_100cm_t_ha, filename = pred_30_100, format = "GTiff")


