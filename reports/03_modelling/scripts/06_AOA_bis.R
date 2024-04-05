#------------------------------------------------------#
# 6. Calculate area of applicability (AOA) ####
#------------------------------------------------------#

library(CAST)
library(caret)
library(terra)
library(raster)
library(tidyverse)
library(rgdal)
library(rasterVis)
library(scales)
library(gridExtra)

print(sessionInfo())

args <- commandArgs(trailingOnly=T)
import_model <- args[1]
import_DI <- args[2]
import_tile <- args[3]
tile_fornames <- args[4]
pred_0_30 <- args[5]
pred_30_100 <- args[6]
output_figure_0_30 <- args[7]
output_figure_30_100 <- args[8]
output_error_0_30 <- args[9]
output_error_30_100 <- args[10]
output_aoa_0_30_tif <- args[11]
output_aoa_30_100_tif <- args[12]
output_error_0_30_tif <- args[13]
output_error_30_100_tif <- args[14]
source("scripts/DItoErrormetric.R")
source("scripts/func_fig_pred.R")


# ## calculate_AOA_worldrule
# import_model <- args[1]
# import_DI <- args[2]
# import_tile <- args[3]
# output_aoa_0_30_tif <- args[4]
# output_aoa_30_100_tif <- args[5]
# output_error_0_30_tif <- args[6]
# output_error_30_100_tif <- args[7]
# source("../../03_modelling/scripts/DItoErrormetric.R")
# source("../../03_modelling/scripts/func_fig_pred.R")

# # # if doing nndm CV
# import_model<- "snakesteps/03_models/model_nndm.rds"
# import_DI <- "snakesteps/05_DI/model_nndm_trainDI.rds"
# import_tile <- "../../03_modelling/tiles_locations/export_LA_low_forAndre.tif"

# output_aoa_0_30_tif = "snakesteps/06_AOA/AOA_nndm_0_30_export_LA_low_forAndre.tif"
# output_aoa_30_100_tif = "snakesteps/06_AOA/AOA_nndm_30_100_export_LA_low_forAndre.tif"
# output_error_0_30_tif = "snakesteps/07_error/error_0_30_nndm_export_LA_low_forAndre.tif"
# output_error_30_100_tif = "snakesteps/07_error/error_30_100_nndm_export_LA_low_forAndre.tif"



trainDI <- readRDS(import_DI)
final_model <- readRDS(import_model)
# tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)
pred_0_30 <- rast(pred_0_30)
pred_30_100 <- rast(pred_30_100)


###### 6.1 trainDI threshold #####
print(trainDI$threshold)

###### 6.2 Prepare tiles for aoa calculation #####

#rename cropped tile from original tile (cropping changed the layer names)
# orig_names <- names(tile_fornames)
# names(tile_layers) <- orig_names

###### Depth at 0cm

Depth_to_predict_0cm <- raster::raster(vals = 0, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0cm) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers_0 <- addLayer(tile_layers, Depth_to_predict_0cm)


###### Depth at 0cm

Depth_to_predict_30cm <- raster::raster(vals = 0.3, #depth at which we want to predict
                              nrow = nrow(tile_layers), 
                              ncol = ncol(tile_layers),
                              crs = crs(tile_layers),
                              ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_30cm) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers_30 <- addLayer(tile_layers, Depth_to_predict_30cm)


###### Depth at .65 m = 65cm (halfway for 30-100 cm layer) 
Depth_to_predict_100cm <- raster::raster(vals = 1, #depth at which we want to predict
                                      nrow = nrow(tile_layers), 
                                      ncol = ncol(tile_layers),
                                      crs = crs(tile_layers),
                                      ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_100cm) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers_100 <- addLayer(tile_layers, Depth_to_predict_100cm)



###### 6.3 Calculate AOA for each depth horizon #####

#a = readRDS("reports/03_modelling/output/tile1_1_aoa.rds")
a_0 = CAST::aoa(newdata = predictor_layers_0, model = final_model, trainDI = trainDI)

a_30 = CAST::aoa(newdata = predictor_layers_30, model = final_model, trainDI = trainDI)

a_100 = CAST::aoa(newdata = predictor_layers_100, model = final_model, trainDI = trainDI)


#------------------------------------------------------#
# calculate averages ####
#------------------------------------------------------#


AOA_0_30 = mean(a_0$AOA, a_30$AOA)

a_0_layer <- raster(a_0$AOA)
a_30_layer <- raster(a_30$AOA)
a_100_layer <- raster(a_100$AOA)

AOA_0_30 = mean(a_0_layer, a_30_layer)
AOA_30_100 = mean(a_30_layer, a_100_layer)


print(AOA_0_30)
print(AOA_30_100)
print(paste("GDAL version used in terra = ", terra::gdal()))
print(paste("AOA threshold = ", round(trainDI$threshold, 3)))


###### 6.4 Visualize AOA, predictions ####

# 0-30 cm
p1 <- plot_pred_0_30(pred_0_30)
p2 <- plot_aoa_0_30(AOA_0_30)
plot_0_30 <- grid.arrange(p1,p2, ncol = 2)
ggsave(output_figure_0_30, plot_0_30, width = 12.42, height = 4.44)


#30-100cm
p1 <- plot_pred_30_100(pred_30_100)
p2 <- plot_aoa_30_100(AOA_30_100)
plot_30_100 <- grid.arrange(p1,p2, ncol = 2)
ggsave(output_figure_30_100, plot_30_100, width = 12.42, height = 4.44)


#------------------------------------------------------#
# 7. DI to Errormetric ####
#------------------------------------------------------#


###### 7.1 calculate error model and expected error #####

errormodel_0 <- DItoErrormetric(final_model, trainDI = a_0$parameters, multiCV = FALSE)
expected_error_0 <- terra::predict(a_0$DI, errormodel_0)

errormodel_30 <- DItoErrormetric(final_model, trainDI = a_30$parameters, multiCV = FALSE)
expected_error_30 <- terra::predict(a_30$DI, errormodel_30)

errormodel_100 <- DItoErrormetric(final_model, trainDI = a_100$parameters, multiCV = FALSE)
expected_error_100 <- terra::predict(a_100$DI, errormodel_100)

#------------------------------------------------------#
# calculate averages ####
#------------------------------------------------------#

######## expected error 
## need to multply expected error of organic carbon density by
# x [30 or 70] cm (thickness of horizon) x 100 (to convert to tonnes per hectare)

expected_error_0_30 = mean(expected_error_0, expected_error_30)*3000

expected_error_30_100 = mean(expected_error_30, expected_error_100)*7000

###### 7.1 export figures #####

# 0-30 cm
png(filename = output_error_0_30,
    width = 500, height = 367)
plot(expected_error_0_30, main = "Expected error 0-30cm (t ha-1)")
dev.off()

# 30-100 cm
png(filename = output_error_30_100,
    width = 500, height = 367)
plot(expected_error_30_100, main = "Expected error 30-100cm (t ha-1)")
dev.off()



#------------------------------------------------------#
# export TIFs ####
#------------------------------------------------------#


terra::writeRaster(AOA_0_30, filename = output_aoa_0_30_tif, format = "GTiff")
terra::writeRaster(AOA_30_100, filename = output_aoa_30_100_tif)

terra::writeRaster(expected_error_0_30, filename = output_error_0_30_tif)
terra::writeRaster(expected_error_30_100, filename = output_error_30_100_tif)

