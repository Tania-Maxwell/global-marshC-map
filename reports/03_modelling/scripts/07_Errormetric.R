#------------------------------------------------------#
# 7. DI to Errormetric ####
#------------------------------------------------------#

library(CAST)
library(caret)
library(sf)
library(terra)
library(tidyverse)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
args <- commandArgs(trailingOnly=T)
import_model <- args[1]
import_aoa_0_30 <- args[2]
import_aoa_30_30 <- args[3]
output_error_0_30 <- args[4]
output_error_30_100 <- args[5]
source("scripts/DItoErrormetric.R")  

# source("reports/03_modelling/scripts/DItoErrormetric.R")  
# import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
# import_aoa_0_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_0_30_tile1-2.tif.rds"
# import_aoa_30_30 <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_30_100_tile1-2.tif.rds"
# output_error_0_30 <- "reports/03_modelling/snakesteps/08_figures/error_0_30_nndm_tile1-2.png"
# output_error_30_100 <- "reports/03_modelling/snakesteps/08_figures/error_30_100_nndm_tile1-2.png"

final_model <- readRDS(import_model)
aoa_0_30 <- readRDS(import_aoa_0_30)
aoa_30_100 <- readRDS(import_aoa_30_30)

###### 7.1 calculate error model and expected error #####

errormodel_0_30 <- DItoErrormetric(final_model, trainDI = aoa_0_30$parameters, multiCV = FALSE)
expected_error_0_30 <- terra::predict(aoa_0_30$DI, errormodel)

errormodel_30_100 <- DItoErrormetric(final_model, trainDI = aoa_30_100$parameters, multiCV = FALSE)
expected_error_30_100 <- terra::predict(aoa_30_100$DI, errormodel)


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

