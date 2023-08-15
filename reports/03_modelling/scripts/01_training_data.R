#------------------------------------------------------#
# 1. Prepare training data ####
#------------------------------------------------------#


#rm(list=ls()) # clear the workspace
# rep<-"http://cran.rstudio.com/"
# if (!(require(ggplot2))) install.packages('ggplot2', repos=rep)
# library(ggplot2)

library(tidyverse)
#library(geojsonio) #geojson_read
library(geojsonsf) 
library(terra) #crs
library(sf) # st_as_sf

args <- commandArgs(trailingOnly=T)
site_layer <- args[1]
gee_data <- args[2]
soc_data <- args[3]
output_gpkg <- args[4]

# site_layer <- "reports/03_modelling/data/export_uk_layers_30m-0000009216-0000036864.tif"
# gee_data <- "reports/03_modelling/data/2023-07-31_data_covariates_global.csv"
# soc_data <- "reports/02_data_process/data/data_clean_SOCD.csv"
# # output_gpkg <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"


############## 1.1 Import data ####################

#### import 1: load 1 raster to get crs of the area on which to predict
site_predictors <- raster::stack(site_layer)

# 
# import_geojson <- function(x) {
#   print(x)
#   as.data.frame(geojson_read(x, what = "sp"))
# }


#### import 2: load predicted values of covariate layers (from GEE) for each training data (unique lat and long)
GEE_data_raw <- read_csv(gee_data) %>% 
  #only select the variable names extracted using GEE
  dplyr::select(Site_name, 
                ndvi_med, ndvi_stdev,
                #evi_med, evi_stdev,
                #savi_med, savi_stdev,
                Human_modification, M2Tide, PETdry, PETwarm,
                TSM, maxTemp, minTemp, minPrecip, popDens, 
                copernicus_elevation,
                copernicus_slope, 
               # coastalDEM_elevation,
                #coastalDEM_slope,
               # srtm_elevation,
               # srtm_slope,
               # merit_elevation,
               # merit_slope,
                .geo,
                Lat_Long) 


GEE_data <- GEE_data_raw %>% # issues with NAs
  drop_na()


#### import 3: load training data with all original data (Site details and OC, SOM, BD measurements) 

training_data <- read_csv(soc_data) %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" ))

############## 1.2 Merge data ####################


## join the two data frames
df1 <- inner_join(training_data,GEE_data, by = c("Site_name","Lat_Long"))
## note: Latitude is coords.x1 and longitude is coords.x2 from GEE exported data
# GEE adds more precisison to lat and long - we will continue using original lat and long (hence Lat_Long column)

############## 1.3 Convert to sf format  ####################

df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
                   crs = terra::crs(site_predictors, proj = TRUE))

# #from geojson
# df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
#                    crs = terra::crs(site_predictors, proj = TRUE))


samplepoints <- df1_sf %>% 
  dplyr::select(geometry) #

coordinates_aes <- st_transform(samplepoints, 
                                crs = crs(site_predictors, asText = T))


############## 1.4 Create final trainDat  ####################
trainDat <- df1_sf %>% 
  #select(names_pred) # this is so that it matches the layers where we are predicting onto
  dplyr::select(Depth_midpoint_m, ndvi_med, ndvi_stdev,
         Human_modification, M2Tide, PETdry, PETwarm,
         TSM, maxTemp, minTemp, minPrecip, popDens, 
         copernicus_elevation,
         copernicus_slope,
         SOCD_g_cm3) %>% 
  dplyr::rename(response = SOCD_g_cm3)

############## 1.5 export  ####################
st_write(trainDat, output_gpkg, append = FALSE)
