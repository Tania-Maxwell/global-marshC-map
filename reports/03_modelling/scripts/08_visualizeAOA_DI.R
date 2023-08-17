
#------------------------------------------------------#
# 8. Visualize predictions, AOA, DI ####
#------------------------------------------------------#
library(tidyverse)
library(raster)
library(terra)

args <- commandArgs(trailingOnly=T)
pred_0_30 <- args[1]
pred_0_30 <- args[2]
import_aoa <- args[3]
import_DI <- args[4]
output_figure_0_30  <-  args[5] #output as .png
output_figure_30_100 <-   args[6]

pred_0_30 <-  "reports/03_modelling/snakesteps/04_output/nndm_pred_0_30cm_t_ha_tile1-2.tif"
pred_30_100 <- "reports/03_modelling/snakesteps/04_output/nndm_pred_30_100cm_t_ha_tile1-2.tif"
import_aoa <- "reports/03_modelling/snakesteps/06_AOA/AOA_nndm_tile1-2.tif.rds"
import_DI <- "reports/03_modelling/snakesteps/05_DI/model_nndm_trainDI.rds"
output_figure_0_30 <- "snakesteps/08_figures/pred_AOA_DI_0_30_nndm_tile1-2.png"
output_figure_30_100 <- "snakesteps/08_figures/pred_AOA_DI_30_100_nndm_tile1-2.png"


pred_0_30 <- rast(pred_0_30)
pred_30_100 <- rast(pred_30_100)
aoa <- readRDS(import_aoa)
trainDI <- readRDS(import_DI)

###### 8.1 Visualize DI #####

plot(aoa$AOA)
plot(aoa) # nndm model 

###### 8.2 Visualize AOA #####
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

