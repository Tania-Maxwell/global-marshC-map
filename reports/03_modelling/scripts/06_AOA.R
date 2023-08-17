#------------------------------------------------------#
# 6. Calculate area of applicability (AOA) ####
#------------------------------------------------------#

library(CAST)
library(caret)
library(terra)
library(raster)
library(tidyverse)

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

# # if doing spatial CV
# import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# import_DI <- "reports/03_modelling/snakesteps/05_DI/model_spatial_trainDI.rds"
# pred_0_30 <-  "reports/03_modelling/snakesteps/04_output/pred_0_30cm_t_ha_tile1-2.tif"
# pred_30_100 <- "reports/03_modelling/snakesteps/04_output/pred_30_100cm_t_ha_tile1-2.tif"
# output_aoa_0_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_0_30_tile1-2.tif.rds"
# output_aoa_30_100 <-"reports/03_modelling/snakesteps/06_AOA/AOA_30_100_tile1-2.tif.rds"
# output_figDI_0_30 <-  "snakesteps/08_figures/DI_0_30_tile1-2.png"
# output_figDI_30_100 <- "snakesteps/08_figures/DI_30_100_tile1-2.png"
# output_figure_0_30 <- "snakesteps/08_figures/pred_AOA_0_30_tile1-2.png"
# output_figure_30_100 <- "snakesteps/08_figures/pred_AOA_30_100_tile1-2.png"


# if doing nndm CV
import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
import_DI <- "reports/03_modelling/snakesteps/05_DI/model_nndm_trainDI.rds"
pred_0_30 <-  "reports/03_modelling/snakesteps/04_output/nndm_pred_0_30cm_t_ha_tile1-2.tif"
pred_30_100 <- "reports/03_modelling/snakesteps/04_output/nndm_pred_30_100cm_t_ha_tile1-2.tif"
output_aoa_0_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_0_30_tile1-2.tif.rds"
output_aoa_30_100 <-"reports/03_modelling/snakesteps/06_AOA/AOA_nndm_30_100_tile1-2.tif.rds"
output_figDI_0_30 <-  "reports/03_modelling/snakesteps/08_figures/DI_0_30_nndm_tile1-2.png"
output_figDI_30_100 <- "reports/03_modelling/snakesteps/08_figures/DI_30_100_nndm_tile1-2.png"
output_figure_0_30 <- "reports/03_modelling/snakesteps/08_figures/pred_AOA_0_30_nndm_tile1-2.png"
output_figure_30_100 <- "reports/03_modelling/snakesteps/08_figures/pred_AOA_30_100_nndm_tile1-2.png"

# # same for both nndm and spatial:
import_tile <- "reports/03_modelling/tiles/tile1-2.tif"
tile_fornames <- "reports/03_modelling/tiles/export_the_wash_ENG.tif"

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
png(filename = output_figure_0_30,
    width = 1242, height = 444)
par(mfrow = c(1, 2))
plot(pred_0_30, main = "SOCS predictions 0-30cm (t ha-1)")
plot(a_0_30$AOA, main = "Area of applicability at 15cm depth")
dev.off()

# 30-100 cm
png(filename = output_figure_30_100,
    width = 1242, height = 444)
par(mfrow = c(1, 2))
plot(pred_30_100, main = "SOCS predictions 30-100cm (t ha-1)")
plot(a_30_100$AOA, main =  "Area of applicability at 65cm depth")
dev.off()


###### 6.5 Export AOA as RDS #####
saveRDS(a_0_30, output_aoa_0_30)
saveRDS(a_30_100, output_aoa_30_100)
