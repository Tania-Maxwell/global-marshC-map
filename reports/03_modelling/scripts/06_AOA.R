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
output_aoa_0_30 <- args[7]
output_aoa_30_100 <- args[8]
output_figDI_0_30 <- args[9]
output_figDI_30_100 <- args[10]
output_figure_0_30 <- args[11]
output_figure_30_100 <- args[12]
output_error_0_30 <- args[13]
output_error_30_100 <- args[14]
output_aoa_0_30_tif <- args[15]
output_aoa_30_100_tif <- args[16]
output_error_0_30_tif <- args[17]
output_error_30_100_tif <- args[18]
source("scripts/DItoErrormetric.R")
source("scripts/func_fig_pred.R")

# ## calculate_AOA_test rule
# import_model <- args[1]
# import_DI <- args[2]
# import_tile <- args[3]
# tile_fornames <- args[4]
# pred_0_30 <- args[5]
# pred_30_100 <- args[6]
# output_aoa_0_30_tif_test <- args[7]
# source("scripts/DItoErrormetric.R")

# # if doing spatial CV
# import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# import_DI <- "reports/03_modelling/snakesteps/05_DI/model_spatial_trainDI.rds"
# pred_0_30 <-  "reports/03_modelling/snakesteps/04_output/pred_0_30cm_t_ha_export_the_wash_ENG.tif"
# pred_30_100 <- "reports/03_modelling/snakesteps/04_output/pred_30_100cm_t_ha_export_the_wash_ENG.tif"
# output_aoa_0_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_0_30_export_the_wash_ENG.tif.rds"
# output_aoa_30_100 <-"reports/03_modelling/snakesteps/06_AOA/AOA_30_100_export_the_wash_ENG.tif.rds"
# output_figDI_0_30 <-  "reports/03_modelling/snakesteps/08_figures/DI_0_30_export_the_wash_ENG.tif.png"
# output_figDI_30_100 <- "reports/03_modelling/snakesteps/08_figures/DI_30_100_export_the_wash_ENG.tif.png"
# output_figure_0_30 <- "reports/03_modelling/snakesteps/08_figures/pred_AOA_0_30_export_the_wash_ENG.tif.png"
# output_figure_30_100 <- "reports/03_modelling/snakesteps/08_figures/pred_AOA_30_100_export_the_wash_ENG.tif.png"

# 
# # if doing nndm CV
# import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
# import_DI <- "reports/03_modelling/snakesteps/05_DI/model_nndm_trainDI.rds"
# pred_0_30 <-  "reports/03_modelling/snakesteps/04_output/nndm_pred_0_30cm_t_ha_export_LA_low_forAndre.tif"
# pred_30_100 <- "reports/03_modelling/snakesteps/04_output/nndm_pred_30_100cm_t_ha_export_LA_low_forAndre.tif"
# output_aoa_0_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_0_30_export_LA_low_forAndre.tif.rds"
# output_aoa_30_100 <-"reports/03_modelling/snakesteps/06_AOA/AOA_nndm_30_100_export_LA_low_forAndre.tif.rds"
# output_figDI_0_30 <-  "reports/03_modelling/snakesteps/08_figures/DI_0_30_nndm_export_LA_low_forAndre.tif.png"
# output_figDI_30_100 <- "reports/03_modelling/snakesteps/08_figures/DI_30_100_nndm_export_LA_low_forAndre.tif.png"
# output_figure_0_30 <- "snakesteps/08_figures/pred_AOA_0_30_nndm_export_LA_low_forAndre.tif.png"
# output_figure_30_100 <- "snakesteps/08_figures/pred_AOA_30_100_nndm_export_LA_low_forAndre.tif.png"
# output_error_0_30 = "reports/03_modelling/snakesteps/07_error/error_0_30_nndm_export_LA_low_forAndre.tif.png"
# output_error_30_100 = "reports/03_modelling/snakesteps/07_error/error_30_100_nndm_export_LA_low_forAndre.tif.png"
# output_aoa_0_30_tif = "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_0_30_export_LA_low_forAndre.tif"
# output_aoa_30_100_tif = "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_30_100_export_LA_low_forAndre.tif"
# output_error_0_30_tif = "reports/03_modelling/snakesteps/07_error/error_0_30_nndm_export_LA_low_forAndre.tif"
# output_error_30_100_tif = "reports/03_modelling/snakesteps/07_error/error_30_100_nndm_export_LA_low_forAndre.tif"
# 
# # # # same for both nndm and spatial:
# import_tile <- "reports/03_modelling/tiles_locations/export_LA_low_forAndre.tif"
# source("reports/03_modelling/scripts/DItoErrormetric.R") 
# source("reports/03_modelling/scripts/func_fig_pred.R")



trainDI <- readRDS(import_DI)
final_model <- readRDS(import_model)
tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)
pred_0_30 <- rast(pred_0_30)
pred_30_100 <- rast(pred_30_100)


###### 6.1 trainDI threshold #####
print(trainDI$threshold)

###### 6.2 Prepare tile for aoa calculation #####

#rename cropped tile from original tile (cropping changed the layer names)
orig_names <- names(tile_fornames)
names(tile_layers) <- orig_names

###### Depth at .15 m = 15cm (halfway for 0-30 cm layer) 

Depth_to_predict_0_30cm <- raster::raster(vals = 0.15, #depth at which we want to predict
                                          nrow = nrow(tile_layers), 
                                          ncol = ncol(tile_layers),
                                          crs = crs(tile_layers),
                                          ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_0_30cm) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers_0_30 <- addLayer(tile_layers, Depth_to_predict_0_30cm)


###### Depth at .65 m = 65cm (halfway for 30-100 cm layer) 
Depth_to_predict_30_100cm <- raster::raster(vals = 0.65, #depth at which we want to predict
                                            nrow = nrow(tile_layers), 
                                            ncol = ncol(tile_layers),
                                            crs = crs(tile_layers),
                                            ext = extent(tile_layers))
# rename the raster layer
names(Depth_to_predict_30_100cm) <- "Depth_midpoint_m"


# add the layer to the raster stack tile_layers, to create a tile_layers_forpred (for predictions) 
predictor_layers_30_100 <- addLayer(tile_layers, Depth_to_predict_30_100cm)



###### 6.3 Calculate AOA for each depth horizon #####

#a = readRDS("reports/03_modelling/output/tile1_1_aoa.rds")
a_0_30 = CAST::aoa(newdata = predictor_layers_0_30, model = final_model, trainDI = trainDI)

a_30_100 = CAST::aoa(newdata = predictor_layers_30_100, model = final_model, trainDI = trainDI)


###### 6.4 predictionDI vs trainDI ####

# 0-30 cm
png(filename = output_figDI_0_30,
    #res = 120,
    width = 549, height = 392)
plot(a_0_30, main = "DI for 0-30 cm soil layer")
dev.off()

# 30-100 cm
png(filename = output_figDI_30_100,
    #res = 120,
    width = 549, height = 392)
plot(a_30_100, main = "DI for 30-100 cm soil layer")
dev.off()

###### 6.5 Visualize AOA, predictions ####

# 0-30 cm
p1 <- plot_pred_0_30(pred_0_30)
p2 <- plot_aoa_0_30(a_0_30$AOA)
plot_0_30 <- grid.arrange(p1,p2, ncol = 2)
ggsave(output_figure_0_30, plot_0_30, width = 12.42, height = 4.44)


#30-100cm
p1 <- plot_pred_30_100(pred_30_100)
p2 <- plot_aoa_30_100(a_30_100$AOA)
plot_30_100 <- grid.arrange(p1,p2, ncol = 2)
ggsave(output_figure_30_100, plot_30_100, width = 12.42, height = 4.44)


# # 0-30 cm
# png(filename = output_figure_0_30,
#     width = 1242, height = 444)
# par(mfrow = c(1, 2))
# # plot(pred_0_30, main = "SOCS predictions 0-30cm (t ha-1)")
# plot_pred_0_30(pred_0_30)
# plot(a_0_30$AOA, main = "Area of applicability at 15cm depth", col = c("#D55E00","#009E73"))
# dev.off()

# # 30-100 cm
# png(filename = output_figure_30_100,
#     width = 1242, height = 444)
# par(mfrow = c(1, 2))
# # plot(pred_30_100, main = "SOCS predictions 30-100cm (t ha-1)")
# plot_pred_30_100(pred_30_100)
# plot(a_30_100$AOA, main =  "Area of applicability at 65cm depth", col = c("#D55E00","#009E73"))
# dev.off()


###### 6.5 Export AOA as RDS #####
saveRDS(a_0_30, output_aoa_0_30)
saveRDS(a_30_100, output_aoa_30_100)


#------------------------------------------------------#
# 7. DI to Errormetric ####
#------------------------------------------------------#


###### 7.1 calculate error model and expected error #####

errormodel_0_30 <- DItoErrormetric(final_model, trainDI = a_0_30$parameters, multiCV = FALSE)
expected_error_0_30 <- terra::predict(a_0_30$DI, errormodel_0_30)

errormodel_30_100 <- DItoErrormetric(final_model, trainDI = a_30_100$parameters, multiCV = FALSE)
expected_error_30_100 <- terra::predict(a_30_100$DI, errormodel_30_100)


###### 7.1 export figures #####

# 0-30 cm
png(filename = output_error_0_30,
    width = 950, height = 367)
par(mfrow = c(1, 2), mar = c("bottom" = 5, "left" = 4, "top" = 4, "right" = 6))
plot(errormodel_0_30, main = "Error model 0-30cm")
plot(expected_error_0_30, main = "Expected error 0-30cm")
dev.off()

# 30-100 cm
png(filename = output_error_30_100,
    width = 950, height = 367)
par(mfrow = c(1, 2), mar = c("bottom" = 5, "left" = 4, "top" = 4, "right" = 6))
plot(errormodel_30_100, main = "Error model 30-100cm")
plot(expected_error_30_100, main = "Expected error 30-100cm")
dev.off()

#------------------------------------------------------#
# export TIFs ####
#------------------------------------------------------#
a_0_30_layer <- raster(a_0_30$AOA)
a_30_100_layer <- raster(a_30_100$AOA)

print(a_0_30_layer)
print(a_30_100_layer)
print(paste("GDAL version used in terra = ", terra::gdal()))
print(paste("AOA threshold = ", round(trainDI$threshold, 3)))

terra::writeRaster(a_0_30_layer, filename = output_aoa_0_30_tif, format = "GTiff")
terra::writeRaster(a_30_100_layer, filename = output_aoa_30_100_tif)

terra::writeRaster(expected_error_0_30, filename = output_error_0_30_tif)
terra::writeRaster(expected_error_30_100, filename = output_error_30_100_tif)

