## script to visualize data points outside of Tom's extent map


rm(list=ls()) # clear the workspace
library(tidyverse)
library(geojsonsf) #geojson_sf
library(geojsonio)

import_geojson <- function(x) {
  print(x)
  as.data.frame(geojson_read(x, what = "sp"))
}

data0 <- import_geojson("reports/03_modelling/data/2023-07-17_data_outside_extent.geojson") 

data_explore <- data0 %>% 
  group_by(Original_source, Country) %>% 
  summarise(avg_distance = round(mean(distance), 0) )
data_explore



gee_data <- "reports/03_modelling/data/2023-07-31_data_covariates_global.csv"

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



colnms <- colnames(GEE_data_raw)
GEE_data_NAs <- GEE_data_raw %>% # issues with NAs
  filter_at(vars(all_of(colnms)), any_vars(is.na(.))) %>% 
  separate(Lat_Long, c("Latitude", "Longitude"), "_") 

# path_out = 'reports/02_data_process/data/'
# file_name_GEE <- paste(Sys.Date(),"GEE_export_NAs.csv", sep = "_")
# export_file_GEE <- paste(path_out, file_name_GEE, sep = '')
# write.csv(GEE_data_NAs, export_file_GEE, row.names = F)


