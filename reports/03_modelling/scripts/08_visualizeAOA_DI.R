
import_pred <- "reports/03_modelling/snakesteps/04_output/pred_0_30cm_t_ha_tile1-3.tif" # this is just to visualize

trainDI <- readRDS(import_DI)
final_model <- readRDS(import_model)
tile_fornames <- raster::stack(tile_fornames)
tile_layers <- raster::stack(import_tile)

#predictions <- raster::stack(import_pred)


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

