#------------------------------------------------------#
# 2. Prepare cross validation folds ####
#------------------------------------------------------#

rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(caret)
library(CAST)


# args <- commandArgs(trailingOnly=T)
# import_data <- args[1]
# output_grid <- args[2]
# output_folds <- args[3]
import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
output_grid <- "reports/03_modelling/snakesteps/02_CV/spatial_folds_grid.gpkg"
output_folds <- "reports/03_modelling/snakesteps/02_CV/folds.RDS"
gridsize = 6 

############## 2.1 Import training data ####################
trainDat <- st_read(import_data, quiet = TRUE)

trainDat_sep <- trainDat %>% 
  mutate(long = unlist(map(trainDat$geom,1)),
         lat = unlist(map(trainDat$geom,2)),
         lat_long = paste(lat, long, sep = "_"))
length(unique(trainDat_sep$lat_long))


############## 2.2 Random CV ####################

#### Random - to show NOT to use this 
# random_cv <- createFolds(trainDat_sep$response,
#                          k = length(unique(trainDat_sep$lat_long)),returnTrain=FALSE)
# 

############## 2.3 Spatial CV basic (Leave-Cluster-Out) ####################


# samplepoints_CV <- trainDat_sep %>%
#   dplyr::select(geometry, lat_long) #
# 
# spatial_cv <- CreateSpacetimeFolds(samplepoints_CV, spacevar="lat_long",
#                                    k=length(unique(trainDat_sep$lat_long)))



############## 2.4 Spatial CV advanced (from Ludwig et al) ####################

#' @author Marvin Ludwig
world_grid = function(extent = c(-180, -90, 180, 90), cellsize = 1, crs = 4326){
  world = sf::st_multipoint(x = matrix(extent, ncol = 2, byrow = TRUE)) %>%
    sf::st_sfc(crs = crs)
  world_grid = sf::st_make_grid(world, cellsize = cellsize)
  world_grid = sf::st_sf(fold = seq(length(world_grid)), world_grid)
  
  return(world_grid)
}

seed = 11
n_folds = 10
training_samples <- trainDat_sep

#' @author Marvin Ludwig from  create_folds_spatial function
grid = world_grid(cellsize = gridsize)

# spatially match points
# remove grid cells without points
grid = grid[lengths(st_intersects(grid, training_samples)) > 0,]

# randomly create groups
grid$fold = seq(nrow(grid)) %% n_folds
set.seed(seed)
grid$fold = sample(grid$fold)


spatial_folds = st_join(training_samples, grid, left = TRUE)
table(spatial_folds$fold)
spatial_folds = spatial_folds[!duplicated(spatial_folds$lat_long),] %>% pull(fold)


#### export tests

#gridsize <- "0-5"
# test_grid_name <- paste("reports/04_model_tests/02_CV/spatial_folds_grid", gridsize, ".gpkg", sep = "")
# test_folds_name <- paste("reports/04_model_tests/02_CV/folds", gridsize, ".RDS", sep = "")
# 
# st_write(grid, test_grid_name, append = FALSE)
# saveRDS(spatial_folds, test_folds_name)

############## 2.4 Export ####################
st_write(grid, output_grid, append = FALSE) # grid 
saveRDS(spatial_folds, output_folds)
