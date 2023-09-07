#------------------------------------------------------#
# 1. Prepare training data ####
#------------------------------------------------------#


#rm(list=ls()) # clear the workspace
# rep<-"http://cran.rstudio.com/"
# if (!(require(ggplot2))) install.packages('ggplot2', repos=rep)
# library(ggplot2)

library(tidyverse)
library(geojsonsf) 
library(terra) #crs
library(sf) # st_as_sf

args <- commandArgs(trailingOnly=T)
site_layer <- args[1]
gee_data <- args[2]
soc_data <- args[3]
output_gpkg <- args[4]

# site_layer <- "reports/03_modelling/tiles/export_the_wash_ENG.tif"
# gee_data <- "reports/03_modelling/data/2023-08-30_data_covariates_global_native.csv"
# soc_data <- "reports/02_data_process/snakesteps/04_OCD/data_clean_SOCD.csv"
# output_gpkg <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"


############## 1.1 Import data ####################

#### import 1: load 1 raster to get crs of the area on which to predict
site_predictors <- terra::rast(site_layer)

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
                Human_modification, M2Tide, PETdry, PETwarm,
                TSM, maxTemp, minTemp, maxPrecip, minPrecip, popDens, 
                copernicus_elevation, copernicus_slope,
                SLR_zone, ECU,
                .geo,
                Lat_Long) 


GEE_data <- GEE_data_raw %>% # remove rows with any NA
  drop_na() %>% # this should only be ndvi (see test)
  dplyr::select(-Site_name) #will keep the site name from the soc_data dataset

test <- GEE_data_raw %>% 
  filter(is.na(ndvi_med) == TRUE) # samples that are too inland (weren't in bathymask)
nrow(test)
nrow(GEE_data_raw)-nrow(GEE_data)
# unique SiteName: this is 225 samples = 6291 (nrow GEE_data_raw) -6066 (nrow GEE_data) which confirms this is the only column with NAs
# unique LatLong: this is 128 samples = 4315 (nrow GEE_data_raw) -4187 (nrow GEE_data) which confirms this is the only column with NAs


#### import 3: load training data with all original data (Site details and OC, SOM, BD measurements) 

training_data <- read_csv(soc_data) %>%
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" ))

### REMOVE CORES WITH DUPLICATES

# training_data_raw <- read_csv(soc_data) 
# 
# unique_Lat_Long <- training_data_raw %>%
#   mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>%
#   distinct(Lat_Long, .keep_all = TRUE) %>%
#   dplyr::select("Source", "Site_name", "Lat_Long")
# 
# 
# training_data <- left_join(unique_Lat_Long, training_data_raw, by = c("Source", "Site_name"))

############## 1.2 Merge data ####################


## join the two data frames
df1 <- inner_join(training_data,GEE_data, by = c("Lat_Long"))
## note: Latitude is coords.x1 and longitude is coords.x2 from GEE exported data
# GEE adds more precisison to lat and long - we will continue using original lat and long (hence Lat_Long column)

table(df1$Data_type)

############## 1.3 Convert to sf format  ####################

df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
                   crs = terra::crs(site_predictors, proj = TRUE))

# #from geojson
# df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
#                    crs = terra::crs(site_predictors, proj = TRUE))


samplepoints <- df1_sf %>% 
  dplyr::select(geometry) #

coordinates_aes <- st_transform(samplepoints, 
                                crs = crs(site_predictors))


############## 1.4 Create final trainDat  ####################
trainDat <- df1_sf %>% 
  #select(names_pred) # this is so that it matches the layers where we are predicting onto
  dplyr::select(Depth_midpoint_m, ndvi_med, ndvi_stdev,
         Human_modification, M2Tide, PETdry, PETwarm,
         TSM, maxTemp, minTemp, maxPrecip, minPrecip, popDens, 
         copernicus_elevation,
         copernicus_slope, SLR_zone, ECU,
         SOCD_g_cm3) %>% 
  dplyr::rename(response = SOCD_g_cm3)

plot(trainDat$Depth_midpoint_m, trainDat$response)

############## 1.5 export  ####################
st_write(trainDat, output_gpkg, append = FALSE)
