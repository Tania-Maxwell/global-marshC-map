#------------------------------------------------------#
# 7. DI to Errormetric ####
#------------------------------------------------------#

library(CAST)
library(caret)
library(sf)
library(terra)
library(tidyverse)

# args <- commandArgs(trailingOnly=T)
# import_model <- args[1]
# import_aoa <- args[2]
# source("scripts/DItoErrormetric.R")  

source("reports/03_modelling/scripts/DItoErrormetric.R")  
import_model<- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# import_trainDI <- readRDS("reports/03_modelling/output/aoa_results.rds")
import_aoa <- "reports/03_modelling/output/tile1_3_aoa.rds"

final_model <- readRDS(import_model)
AOA <- readRDS(import_aoa)

errormodel <- DItoErrormetric(final_model, trainDI = AOA$parameters, multiCV = FALSE, calib = "lm")
plot(errormodel)

expected_error <- terra::predict(AOA$DI, errormodel)
plot(expected_error)

# mask AOA based on new threshold from multiCV
mask_aoa = terra::mask(expected_error, AOA$DI < attr(errormodel, 'AOA_threshold'), maskvalues = 1)
plot(mask_aoa)


predictions <- raster::stack("reports/03_modelling/snakesteps/04_output/pred_0_30cm_t_ha_tile1-3.tif")
names(predictions) <- "pred_0_30cm"

par(mfrow = c(1, 2))
plot(predictions)

plot(mask_aoa, xmin = extent(predictions$pred_0_30cm)[1],
     xmax = extent(predictions$pred_0_30cm)[2],
     ymin = extent(predictions$pred_0_30cm)[3],
     ymax = extent(predictions$pred_0_30cm)[4])
plot(AOA)

