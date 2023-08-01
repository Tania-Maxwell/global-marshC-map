### script combining GEE data from covariate extract and training dataset
##


rm(list=ls()) # clear the workspace
library(raster)
library(sf)
library(terra)
library(CAST) #AOA and CV strategy 
library(viridis) # color map
library(tidyverse)
library(caret)
library(geojsonsf) #geojson_sf
library(geojsonio)
library(fuzzyjoin) #join dfs with slighly different format of lat long

seed <- 1234


#---------------------------------------------------#
#### 1. DATA IMPORTS ####
#---------------------------------------------------#

# #### import 1: load 1 raster to get crs of the area on which to predict
site_predictors <- raster::stack("//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK/export_uk_layers_30m-0000000000-0000036864.tif")
names_pred <- names(site_predictors)

#### import 2: load predicted values of covariate layers for each training data (unique lat and long)
import_geojson <- function(x) {
  print(x)
  as.data.frame(geojson_read(x, what = "sp"))
}

GEE_data_raw <- import_geojson("reports/03_modelling/data/2023-07-17_data_covariates_float.geojson") %>% 
  #only select the variable names extracted using GEE
  dplyr::select(Site_name, 
                ndvi_med, ndvi_stdev,
                evi_med, evi_stdev,
                savi_med, savi_stdev,
                Human_modification, M2Tide, PETdry, PETwarm,
                TSM, maxTemp, minTemp, minPrecip, popDens, 
                copernicus_elevation,
                copernicus_slope, 
                coastalDEM_elevation,
                coastalDEM_slope,
                srtm_elevation,
                srtm_slope,
                merit_elevation,
                merit_slope,
                coords.x1,
                coords.x2,
                Lat_Long) 

## testing no NAs
GEE_data_noNA <- GEE_data_raw %>% 
  drop_na(coastalDEM_elevation, coastalDEM_slope)

test <- anti_join(GEE_data_raw, GEE_data_noNA) 
nrow(test) #186 points with NAs mostly due to NDVI/EVI/SAVI


GEE_data <- GEE_data_raw %>% 
  select(-c(coastalDEM_elevation, coastalDEM_slope)) %>% 
  drop_na()

#### import 3: load training data with all original data (Site details and OC, SOM, BD measurements) 

training_data <- read_csv("reports/02_data_process/data/2023-07-17_data_clean_SOMconv_uniqueSiteName.csv") %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" ))

site_level <- training_data %>% 
  filter(is.na(OC_perc_mean) == FALSE | is.na(SOM_perc_mean) == FALSE) %>% 
  filter(Data_type != "Core-level") %>% 
  distinct(Latitude, Longitude, .keep_all = TRUE)
nrow(site_level)
table(site_level$Country)
#---------------------------------------------------#
#### 2. TRAINING DATA PREP ####
#---------------------------------------------------#

## join the two data frames

df0 <- left_join(training_data,GEE_data, by = c("Site_name","Lat_Long"))
## note: Latitude is coords.x1 and longitude is coords.x2 from GEE exported data
# GEE adds more precisison to lat and long - we will continue using original lat and long (hence Lat_Long column)


##### 2. add OCD columns #####

df05 <- df0 %>% 
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

df1 <- df05 %>% 
  drop_na(ndvi_med, ndvi_stdev,
          evi_med, evi_stdev,
          savi_med, savi_stdev,
          Human_modification, M2Tide, PETdry, PETwarm,
          TSM, maxTemp, minTemp, minPrecip, popDens, 
          copernicus_elevation,
          copernicus_slope,
          srtm_elevation,
          srtm_slope,
          merit_elevation,
          merit_slope)


## if from a .csv
# df1_sf <- st_as_sf(data.frame(df1, geom=geojson_sf(df1$.geo)),
#                    crs = terra::crs(site_predictors, proj = TRUE))

#from geojson
df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
                   crs = terra::crs(site_predictors, proj = TRUE))


samplepoints <- df1_sf %>% 
  dplyr::select(geometry) #

coordinates_aes <- st_transform(samplepoints, 
                                crs = crs(site_predictors, asText = T))
print(coordinates_aes)

##### finalize training data

trainDat <- df1_sf %>% 
  #select(names_pred) # this is so that it matches the layers where we are predicting onto
  select(ndvi_med, ndvi_stdev,
         #evi_med, evi_stdev,
         #savi_med, savi_stdev,
         Human_modification, M2Tide, PETdry, PETwarm,
         TSM, maxTemp, minTemp, minPrecip, popDens, 
         copernicus_elevation,
         copernicus_slope) 
         #coastalDEM_elevation,
        # coastalDEM_slope,
        # srtm_elevation,
        # srtm_slope,
        # merit_elevation,
        # merit_slope)
  
trainDat$Depth_midpoint_m <- df1$Depth_midpoint_m
trainDat$response <- df1$SOCD_g_cm3 # note: rename this to response


n_sites <- length(unique(df1_sf$Site_name))
n_sites #3371 --> once NA removed 1993

n_latlong <- length(unique(df1_sf$Lat_Long))
n_latlong #2581 --> once NA removed 2057


n_location <- length(unique(df1_sf$geometry))
n_location #2581 --> once NA removed 2057

summary(trainDat)

##### 4. Prepare cross validation ####

#### Random - to show NOT to use this 
random_cv <- createFolds(trainDat$response,
                         k=n_latlong,returnTrain=FALSE)
#print(str(random_cv))



#### Leave-Cluster-Out "Spatial" CV

samplepoints_CV <- df1_sf %>% 
  dplyr::select(geometry, Lat_Long) #
spatial_cv <- CreateSpacetimeFolds(samplepoints_CV, spacevar="Lat_Long", k=n_latlong)


###### 4b. Visualize cv strategies #####
## Note: need to add mask here

# dist_random <- plot_geodist(x=samplepoints,cvfolds=random_cv,modeldomain=mask,showPlot = FALSE)
# random_distance_plot <- dist_random$plot+scale_x_log10(labels=round)+ggtitle("Random CV")
# 
# dist_spatial <- plot_geodist(x=samplepoints,cvfolds=spatial_cv$indexOut,
#                              modeldomain=mask,showPlot = FALSE)
# spatial_distance_plot <- dist_spatial$plot+scale_x_log10(labels=round)+ggtitle("Spatial CV")
# 

##### 5. Random forest with nndm CV ####

### model training with a classic spatial CV

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  select(-geometry, -response) 

summary(trainDat_formod)  
summary(trainDat$response)

ncol(trainDat_formod)


model_random <- train(trainDat_formod,
                      trainDat$response,
                      method="rf",
                      ntree=100,
                      importance=TRUE,
                      tuneGrid = data.frame("mtry"=2),
                      trControl = trainControl(method="cv",savePredictions = TRUE))
model_random  



# model_spatial <- train(trainDat_formod, 
#                        trainDat$response,
#                        method="rf",
#                        ntree=100,
#                        importance=TRUE,
#                        tuneGrid = data.frame("mtry"=2),
#                        trControl = trainControl(method="cv",
#                                                 index=spatial_cv$index,
#                                                 savePredictions = TRUE))
#saveRDS(model_spatial, "reports/03_modelling/output/model_spatial_global.rds")

model_spatial <- readRDS("reports/03_modelling/output/model_spatial_global.rds")

print(model_spatial) # R2 isn't implemented 

variable_importance <- varImp(model_spatial)

plot(variable_importance)


model_spatial$finalModel

#### 6. Predictions ####

## first, we need to define the depth at which we want to predict SOC_g_cm3
## then, create a new raster layer (Depth_to_predict) with this value, using the raster info from site_predictors
## and ADD a raster layer of this value to the raster stack of environmental 

Sys.time()
###### Depth at 0 m #####

Depth_to_predict_0m <- raster(vals = 0, #depth at which we want to predict
                              nrow = nrow(site_predictors), 
                              ncol = ncol(site_predictors),
                              crs = crs(site_predictors),
                              ext = extent(site_predictors))
# rename the raster layer
names(Depth_to_predict_0m) <- "Depth_midpoint_m"


# add the layer to the raster stack site_predictors, to create a site_predictors_forpred (for predictions) 
site_predictors_forpred_0m <- addLayer(site_predictors, Depth_to_predict_0m)
print(names(site_predictors_forpred_0m))                                    

prediction_0m <- predict(site_predictors_forpred_0m, model_spatial)
prediction_0m_CI <- raster::predict(site_predictors_forpred_0m, model_spatial$finalModel, interval = "confidence")



##example
m<- caret::train(mpg ~ poly(hp, 2), data=mtcars, method="lm")
caretNewdata <- caretTrainNewdata(m, mtcars)
preds <- predict(m$finalModel, caretNewdata, interval = "confidence")
head(preds, 3)
#writeRaster(prediction_0m_CI, filename = "reports/03_modelling/output/test_prediction0_global_CI.tif", format = "GTiff")


###### Depth at 0.30 m #####

Depth_to_predict_30m <- raster(vals = 0.3, #depth at which we want to predict
                               nrow = nrow(site_predictors), 
                               ncol = ncol(site_predictors),
                               crs = crs(site_predictors),
                               ext = extent(site_predictors))
# rename the raster layer
names(Depth_to_predict_30m) <- "Depth_midpoint_m"

# add the layer to the raster stack site_predictors, to create a site_predictors_forpred (for predictions) 
site_predictors_forpred_30m <- addLayer(site_predictors, Depth_to_predict_30m)
names(site_predictors_forpred_30m)                                    

prediction_30m <- predict(site_predictors_forpred_30m, model_spatial)
#plot(prediction_30m)


###### Depth at 1 m #####

Depth_to_predict_1m <- raster(vals = 1, #depth at which we want to predict
                              nrow = nrow(site_predictors), 
                              ncol = ncol(site_predictors),
                              crs = crs(site_predictors),
                              ext = extent(site_predictors))
# rename the raster layer
names(Depth_to_predict_1m) <- "Depth_midpoint_m"

# add the layer to the raster stack site_predictors, to create a site_predictors_forpred (for predictions) 
site_predictors_forpred_1m <- addLayer(site_predictors, Depth_to_predict_1m)
names(site_predictors_forpred_1m)                                    

prediction_1m <- predict(site_predictors_forpred_1m, model_spatial)
#plot(prediction_1m)


###### C stocks  #####

### 0-30 cm

prediction_0_30cm_avg <- mean(prediction_0m, prediction_30m)

prediction_0_30cm_g_cm2 <- prediction_0_30cm_avg*30 #multiply by 30cm  = layer thickness 

prediction_0_30cm_t_ha <- prediction_0_30cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 
#plot(prediction_0_30cm_t_ha)


### 30-100 cm

prediction_30_100cm_avg <- mean(prediction_30m, prediction_1m)

prediction_30_100cm_g_cm2 <- prediction_30_100cm_avg*70 #multiply by 30cm  = layer thickness 

prediction_30_100cm_t_ha <- prediction_30_100cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 
#plot(prediction_30_100cm_t_ha)


#### 0-100 cm

prediction_0_100cm_t_ha <- sum(prediction_0_30cm_t_ha, prediction_30_100cm_t_ha)
Sys.time()
#writeRaster(prediction_0_100cm_t_ha, filename = "reports/03_modelling/output/test_prediction_0_100cm_t_ha_global.tif", format = "GTiff")

