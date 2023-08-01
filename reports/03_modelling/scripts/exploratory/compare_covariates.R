# script to decide between DEMs and vegetation indices
# using correlations
# then, only those will be exported from GEE for predictions
## global marsh soil C project
# contact Tania Maxwell, tlgm2@cam.ac.uk
# 25.10.22

rm(list=ls()) # clear the workspace
library(tidyverse)
library(geojsonio) # geojson_read

#---------------------------------------------------#
#### 1. DATA IMPORTS ####
#---------------------------------------------------#

import_geojson <- function(x) {
  print(x)
  as.data.frame(geojson_read(x, what = "sp"))
}

GEE_data <- import_geojson("reports/03_modelling/data/2023-06-19_data_covariates_float.geojson") %>% 
  #only select the variable names extracted using GEE
  dplyr::select(Site_name, 
                maxTemp,ndvi_med, ndvi_stdev,
                Human_modification, M2Tide, PETdry, PETwarm,
                TSM, minTemp, minPrecip,popDens, 
                copernicus_elevation,
                copernicus_slope, 
                merit_elevation,
                merit_slope,
                srtm_elevation, srtm_slope,
                coastalDEM_elevation, coastalDEM_slope,
                evi_med, evi_stdev, savi_med, savi_stdev,
                coords.x1,
                coords.x2) %>% 
  filter(coastalDEM_elevation < 11)

#---------------------------------------------------#
#### 2. CORRELATIONS ####
#---------------------------------------------------#



### vegetation indices
veg_df_med <- GEE_data %>% 
  select(ndvi_med, savi_med, evi_med) %>% 
  drop_na()

pairs(veg_df_med,lower.panel = NULL)


veg_corr <- cor(veg_df_med)

corrplot::corrplot(veg_corr, type = 'upper')


## stdev
veg_df_stdev <- GEE_data %>% 
  select(ndvi_stdev, savi_stdev, evi_stdev) %>% 
  drop_na()

pairs(veg_df_stdev,lower.panel = NULL)


veg_corr_stdev <- cor(veg_df_stdev)

corrplot::corrplot(veg_corr, type = 'upper')







### DEMS
DEM_df_med <- GEE_data %>% 
  dplyr::select( coastalDEM_elevation,  
                  copernicus_elevation, 
                  merit_elevation, # NA = 270
                 srtm_elevation
                 )%>% 
  drop_na()

pairs(DEM_df_med,lower.panel = NULL)

DEM_corr <- cor(DEM_df_med)

corrplot::corrplot(DEM_corr, type = 'upper')



#### SLOPE
slope_df_med <- GEE_data %>% 
  dplyr::select(coastalDEM_slope,
                 copernicus_slope, 
                 merit_slope,
                 srtm_slope)%>% 
  drop_na()


pairs(slope_df_med,lower.panel = NULL)

slope_corr <- cor(slope_df_med)

corrplot::corrplot(slope_corr, type = 'upper')




#### To DO: add correlation with OC density??


#### import : load training data with all original data (Site details and OC, SOM, BD measurements) 

training_data <- read_csv("../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv")


df0 <- inner_join(GEE_data,training_data, by = "Site_name") %>% 
  filter(!grepl("Outlier", Notes, ignore.case = TRUE))  #remove outliers

##### add OCD columns 

df1 <- df0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = (L_depth_m - U_depth_m)/2,
         Depth_thickness_m = L_depth_m - U_depth_m) %>%
  filter(is.na(Depth_midpoint_m) == FALSE) %>% 
  ##converting SOM to OC just for test (this will be done beforehand for final data)
  mutate(SOCD_g_cm3 = BD_reported_combined*OC_perc_combined/100,
         SOCS_g_cm2 = SOCD_g_cm3 * 100 *Depth_thickness_m,
         # 100,000,000 cm2 in 1 ha and 1,000,000 g per tonne
         SOCS_t_ha = SOCS_g_cm2 * (100000000)/1000000) %>% 
  filter(is.na(SOCD_g_cm3) == FALSE)


OCD_corr <- df1  %>% 
  dplyr::select(SOCD_g_cm3,
    coastalDEM_elevation,  
                 copernicus_elevation, 
                 merit_elevation, # NA = 270
                 srtm_elevation
  )%>% 
  drop_na()


pairs(OCD_corr,lower.panel = NULL)

OCD_corr <- cor(OCD_corr)

corrplot::corrplot(DEM_corr, type = 'upper')

