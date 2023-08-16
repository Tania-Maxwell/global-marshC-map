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

# # if doing spatial CV
# import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# import_DI <- "reports/03_modelling/snakesteps/05_DI/model_spatial_trainDI.rds"
# output_aoa <- "reports/03_modelling/snakesteps/06_AOA/AOA_spatial_tile1-3.rds"

# # # if doing nndm CV
# import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
# import_DI <- "reports/03_modelling/output/aoa_results.rds"
# output_aoa <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_tile1-3.rds"

# # # same for both nndm and spatial: 
# import_tile <- "reports/03_modelling/tiles/tile1-3.tif"
# tile_fornames <- "reports/03_modelling/tiles/export_the_wash_ENG.tif"

trainDI <- readRDS(import_DI)
final_model <- readRDS(import_model)
tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)


###### 6.1 Visualize different trainDI #####

# trainDI$threshold # 0.18 
# trainDI_nndm$threshold #0.58
# 
# plot(trainDI)
# plot(trainDI_nndm)


###### 6.2 Prepare tile for aoa calculation #####

#rename cropped tile from original tile (cropping changed the layer names)
orig_names <- names(tile_fornames)
names(tile_layers) <- orig_names

###### Depth at .10 m = 10cm 

Depth_to_predict_0m <- raster::raster(vals = 0.15, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0m) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers <- addLayer(tile_layers, Depth_to_predict_0m)



###### 6.3 Calculater AOA #####

#a = readRDS("reports/03_modelling/output/tile1_1_aoa.rds")
a = CAST::aoa(newdata = predictor_layers, model = final_model, trainDI = trainDI)

#a_nndm = CAST::aoa(newdata = predictor_layers, model = final_model_nndm, trainDI = trainDI_nndm)



###### 6.4 Visualize AOA #####


###### 6.5 Visualize AOA #####
# # plot prediction DI vs train DI 
# plot(a) # spatial model (grids)
# plot(a_nndm) # nndm model 
# 
# 
# test_AOA <- a$AOA
# test_AOA[test_AOA == 1] = NA
#  
# par(mfrow = c(1, 3))
# plot(predictions)
# plot(a$AOA, xmin = extent(predictions)[1],
#      xmax = extent(predictions)[2],
#      ymin = extent(predictions)[3],
#      ymax = extent(predictions)[4])
# 
# plot(a_nndm$AOA, xmin = extent(predictions)[1],
#      xmax = extent(predictions)[2],
#      ymin = extent(predictions)[3],
#      ymax = extent(predictions)[4])
# dev.off()
# ### seems like the entire area is outside the AOA 



###### 6.6 Export #####
aoa_layer <- a$AOA

saveRDS(a, output_aoa)
#raster::writeRaster(x = aoa_layer, filename = output_aoa_tif)



