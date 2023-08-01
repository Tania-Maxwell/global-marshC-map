
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

#### import 1: load 1 raster to get crs of the area on which to predict
site_predictors <- raster::stack("//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK/export_uk_layers_30m-0000000000-0000036864.tif")
names_pred <- names(site_predictors)

#### import 2: load predicted values of covariate layers for each training data (unique lat and long)
import_geojson <- function(x) {
  print(x)
  as.data.frame(geojson_read(x, what = "sp"))
}

GEE_data <- import_geojson("reports/03_modelling/data/2023-06-16_data_uk_test.geojson") %>% 
  #only select the variable names extracted using GEE
  dplyr::select(Site_name, 
                maxTemp,ndvi_med, ndvi_stdev,
                Human_modification, M2Tide, PETdry, PETwarm,
                TSM, minTemp, minPrecip,popDens, 
                copernicus_elevation,
                copernicus_slope, 
                coords.x1,
                coords.x2)

#### import 3: load training data with all original data (Site details and OC, SOM, BD measurements) 

training_data <- read_csv("../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv")



#---------------------------------------------------#
#### 2. TRAINING DATA PREP ####
#---------------------------------------------------#

## join the 

df0 <- inner_join(GEE_data,training_data, by = "Site_name") %>% 
  filter(!grepl("Outlier", Notes, ignore.case = TRUE))  #remove outliers


GEE_data_fortest <- GEE_data %>% 
  rename(Longitude = coords.x2,
         Latitude = coords.x1)

test <- stringdist_join(GEE_data_fortest,training_data, by = c("Latitude", "Longitude")) %>% 
  filter(!grepl("Outlier", Notes, ignore.case = TRUE))  #remove outliers

str(GEE_data_fortest)
str(df0)

##### 2. add OCD columns #####

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
  select(names_pred) 

trainDat$Depth_midpoint_m <- df1$Depth_midpoint_m
trainDat$response <- df1$SOCD_g_cm3 # note: rename this to response


n_sites <- length(unique(df1_sf$Site_name))

##### 4. Prepare cross validation ####

#### Random - to show NOT to use this 
random_cv <- createFolds(trainDat$response,
                         k=n_sites,returnTrain=FALSE)
#print(str(random_cv))



#### Leave-Cluster-Out "Spatial" CV

samplepoints_CV <- df1_sf %>% 
  dplyr::select(geometry, Site_name) #
spatial_cv <- CreateSpacetimeFolds(samplepoints_CV, spacevar="Site_name", k=n_sites)





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

model_spatial <- train(trainDat_formod, 
                       trainDat$response,
                       method="rf",
                       ntree=100,
                       importance=TRUE,
                       tuneGrid = data.frame("mtry"=2),
                       trControl = trainControl(method="cv",
                                                index=spatial_cv$index,
                                                savePredictions = TRUE))

print(model_spatial) # R2 isn't implemented 

variable_importance <- varImp(model_spatial)

plot(variable_importance)

#### 6. Predictions ####

## first, we need to define the depth at which we want to predict SOC_g_cm3
## then, create a new raster layer (Depth_to_predict) with this value, using the raster info from site_predictors
## and ADD a raster layer of this value to the raster stack of environmental 


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
plot(prediction_0m)
str(prediction_0m)

writeRaster(prediction_0m, filename = "reports/03_modelling/output/test_prediction0.tif", format = "GTiff")

