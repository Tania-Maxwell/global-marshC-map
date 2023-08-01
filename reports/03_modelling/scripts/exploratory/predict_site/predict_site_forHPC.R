#script to import layers at the small site 
# trying predictions
# tlgm2@cam.ac.uk
# 07.03.23

library(raster)
library(sf)
library(terra)
library(CAST) #AOA and CV strategy 
library(viridis) # color map
library(tidyverse)
library(caret)

seed <- 1234

#setwd("//wsl.localhost/Ubuntu/home/tlgm2/predict_site")

##### 1. Import predictor rasters from GEE ####
site_predictors0 <- raster::stack("./export_site_all_layers_30m.tif") #
print(site_predictors0)
print(names(site_predictors0))

## remove from site_predictors the coastTyp_mode_mode and minPrecip
# site_predictors <- raster::dropLayer(site_predictors0, 
#                                      c("coastTyp_mode_mode", "minPrecip"))

site_predictors <- dropLayer(site_predictors0, 
                                     c("coastTyp_mode_mode", "minPrecip",
                                       "SRTM_elevation", "evi_stdev", "flowAcc_1",
                                       "ndvi_stdev", "savi_stdev")) #renamed this in GEE - this is the SRTM flow acc

print(names(site_predictors))

#predict not on coastTyp_mode_mode and minPrecip --> same value throughout
# predictornames <- c("Depth_midpoint_m", "SRTM_elevation", "evi_med", "evi_stdev", 
#                     "flowAcc_MERIT", "flowAcc_SRTM",  "gHM_2016", "maxTemp",
#                     "merit_elevation",  "merit_slope",  "minTemp","M2Tide",
#                     "ndvi_med", "ndvi_stdev", "PETdry", "PETwarm", "popDens_change",
#                     "savi_med", "savi_stdev", "SRTM_slope", "TSM", "occurrence")
# names(predictornames) <- predictornames

#site_predictors_brick <- raster::brick(site_predictors)

## area of saltmarsh in site
a <- terra::rast(site_predictors[[1]]) #
site_area_ha <- terra::expanse(a,  unit = "ha") #
print(site_area_ha)
#mcowen saltmarsh area estimated: 5,495,089

#estimate global .tif size compared to site tif
site_tif <- 1660 #KB
global_area_ha <- 5495089 #ha

global_tif_KB <- (site_tif/site_area_ha) *global_area_ha
global_tif_GB <- global_tif_KB/1000000 
print(global_tif_GB)
##### 2. Import sample points ####

df0 <- read.csv("./data_cleaned_SOMconverted.csv")

df1 <- df0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = (L_depth_m - U_depth_m)/2,
         Depth_thickness_m = L_depth_m - U_depth_m) %>% 
  ##converting SOM to OC just for test (this will be done beforehand for final data)
  mutate(OC_perc_estimated = 0.000838*(SOM_perc_combined^2) + 
           0.3953*SOM_perc_combined - 0.5358) %>% 
  mutate(OC_perc_final = coalesce(OC_perc_combined, OC_perc_estimated)) %>%
  filter(OC_perc_final >0) %>% 
  mutate(SOCD_g_cm3 = BD_reported_combined*OC_perc_final/100,
         SOCS_g_cm2 = SOCD_g_cm3 * 100 *Depth_thickness_m,
         # 100,000,000 cm2 in 1 ha and 1,000,000 g per tonne
         SOCS_t_ha = SOCS_g_cm2 * (100000000)/1000000) %>% 
  filter(is.na(SOCD_g_cm3) == FALSE)


#prepare coordinates for sf

#script from Hana Meyer to create a mask for the site area
## MAKE SURE THE FIRST PREDICTOR HAS THE CORRECT EXTENT
mask <- site_predictors[[1]] #extracting 1 layer from raster stack, which is inately the saltmarsh extent
values(mask)[!is.na(values(mask))] <- 1
mask <- st_as_sf(rasterToPolygons(mask,dissolve=TRUE),
                 crs = terra::crs(site_predictors, proj = TRUE)) #NOTE:mask needs the same CRS as samplepoints for the nndm() function

df1_sf <- st_as_sf(df1, coords = c("Longitude", "Latitude"),
                   crs = terra::crs(site_predictors, proj = TRUE))

df1_intersection <- st_intersection(df1_sf, mask) # caution! st_crop only crops a rectangle - NOT by extent

samplepoints <- df1_intersection %>% 
  dplyr::select(geometry) #

print(summary(df1_intersection$SOCD_g_cm3))

coordinates_aes <- st_transform(samplepoints, 
                                crs = crs(site_predictors, asText = T))
print(coordinates_aes)


##### 3. Extract covariate layers at training points ####

trainDat <- raster::extract(site_predictors,samplepoints, df = TRUE) #
trainDat$Depth_midpoint_m <- df1_intersection$Depth_midpoint_m
trainDat$response <- df1_intersection$SOCD_g_cm3 # note: rename this to response


###### Plot all predictors and points ######
# 
# raster_plot <- function(x, df) {
#   #function to plot all rasters in the stack
#   
#   #step 1 : open an png with the right file name 
#   png(filename = paste("./figures/", 
#                        names(df[[x]]), ".png", sep = ""), 
#       #res = 120,
#       width = 923, height = 465)
#   
#   #plot the layer (x) 
#   plot(df[[x]], 
#        main = names(df[[x]]),
#        xlim = c(xmin(df), xmax(df)),
#        ylim = c(ymin(df), ymax(df)),
#        xlab = "Latitude", 
#        ylab = "Longitude",
#        col= viridis(n = 5, option = "D"))
#   
#   plot(coordinates_aes, pch = 18, col = 'violetred', cex = 2, add = TRUE)
#   
#   dev.off()
# }
# 
# # ## apply the function to all layers 
# sapply(1:nlayers(site_predictors), function(x) raster_plot(x, df = site_predictors))


# ## issue with NAs in TSM? 
# plot(site_predictors$TSM, 
#      main = names(site_predictors$TSM),
#      xlim = c(xmin(site_predictors), xmax(site_predictors)),
#      ylim = c(ymin(site_predictors), ymax(site_predictors)),
#      xlab = "Latitude", 
#      ylab = "Longitude",
#      col= viridis(n = 5, option = "D"))
# plot(coordinates_aes, pch = 18, col = 'violetred', cex = 2, add = TRUE)
# 


##### 4. Prepare cross validation ####

#### Random - to show NOT to use this 
random_cv <- createFolds(trainDat$response,k=41,returnTrain=FALSE)
#print(str(random_cv))



#### Leave-Cluster-Out "Spatial" CV

samplepoints_CV <- df1_intersection %>% 
  dplyr::select(geometry, Site_name) #


# Leave-Cluster-Out "Spatial" CV
# divide training data into 10 fold; in each fold, leave one data from clusterID out
spatial_cv <- CreateSpacetimeFolds(samplepoints_CV, spacevar="Site_name",k=41)
#print(str(spatial_cv))

#### Nearest neighbor Distance Matching 

### prepare coordinate info for nndm 
# need training points as an sf object and the area of prediction (i.e. the site or region)
# both need to have the same crs included

print(st_crs(samplepoints) == st_crs(mask))
print(raster::projection(samplepoints) == raster::projection(mask))
print( "If TRUE, CRS of samplepoints and mask are equal")

class(samplepoints)
class(mask)

# Nearest neighbor Distance Matching
#takes sampling point and the study area (for which are we want to make predictions)
#NNDM_cv <- nndm(coordinates_aes, modeldomain = mask_aes)
NNDM_cv <- nndm(samplepoints, modeldomain = mask, sampling = "regular")

print(NNDM_cv)

# nndm object
# Total number of points: 435
# Mean number of training points: 229.24
# Minimum number of training points: 68



###### 4b. Visualize cv strategies #####

 
dist_random <- plot_geodist(x=samplepoints,cvfolds=random_cv,modeldomain=mask,showPlot = FALSE)

dist_spatial <- plot_geodist(x=samplepoints,cvfolds=spatial_cv$indexOut,
                             modeldomain=mask,showPlot = FALSE)

dist_NNDM <- plot_geodist(x=samplepoints,cvfolds=NNDM_cv$indx_test,
                          cvtrain=NNDM_cv$indx_train,modeldomain=mask,showPlot = FALSE)

random_distance_plot <- dist_random$plot+scale_x_log10(labels=round)+ggtitle("Random CV")
ggsave( "./figures/random_distance_plot.png", random_distance_plot, width = 6.25, height = 4.66)

spatial_distance_plot <- dist_spatial$plot+scale_x_log10(labels=round)+ggtitle("Spatial CV")
ggsave( "./figures/spatial_distance_plot.png", spatial_distance_plot, width = 6.25, height = 4.66)


NNDM_distance_plot <- dist_NNDM$plot+scale_x_log10(labels=round)+ggtitle("NNDM")
ggsave( "./figures/NNDM_distance_plot.png", NNDM_distance_plot, width = 6.25, height = 4.66)


##### 5. Random forest with nndm CV ####

### Nearest neighbor Distance Matching 

model_nndm <- train(trainDat[, -c(1,ncol(trainDat))], #remove ID column (1st) and response (last column)
                    trainDat$response,
                    method="rf",
                    ntree=100,
                    importance=TRUE,
                    tuneGrid = data.frame("mtry"=2), # reduced tuning to make this faster 
                    trControl = trainControl(method="cv",
                                             index=NNDM_cv$indx_train,
                                             indexOut=NNDM_cv$indx_test,
                                             savePredictions = TRUE))
print(model_nndm) # R2 isn't implemented 

### model training with a classic spatial CV
model_spatial <- train(trainDat[, -c(1,ncol(trainDat))],
                       trainDat$response,
                       method="rf",
                       ntree=100,
                       importance=TRUE,
                       tuneGrid = data.frame("mtry"=2),
                       trControl = trainControl(method="cv",
                                                index=spatial_cv$index,
                                                savePredictions = TRUE))
 
print(model_spatial) # R2 isn't implemented 

# Warning message:
# In nominalTrainWorkflow(x = x, y = y, wts = weights, info = trainInfo,  :
#                           There were missing values in resampled performance measures.

varim_nndm <- varImp(model_nndm)

importance_nndm <- plot(varim_nndm)

png(filename = "./figures/importance_nndm.png", 
    #res = 120,
    width = 533, height = 620)

plot(varim_nndm)

dev.off()

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

prediction_0m <- predict(site_predictors_forpred_0m, model_nndm)
#plot(prediction_0m)

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
print(names(site_predictors_forpred_30m))                                    

prediction_30m <- predict(site_predictors_forpred_30m, model_nndm)
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
print(names(site_predictors_forpred_1m))                                    

prediction_1m <- predict(site_predictors_forpred_1m, model_nndm)
#plot(prediction_1m)


###### C stocks  #####

### 0-30 cm

prediction_0_30cm_avg <- mean(prediction_0m, prediction_30m)

prediction_0_30cm_g_cm2 <- prediction_0_30cm_avg*30 #multiply by 30cm  = layer thickness 

prediction_0_30cm_t_ha <- prediction_0_30cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 
#plot(prediction_0_30cm_t_ha)

# plot
png(filename = "./figures/prediction_0_30cm_t_ha.png", 
    #res = 120,
    width = 692, height = 426)
plot(prediction_0_30cm_t_ha, 
     main = "SOC stocks (t ha-1) to 0-30cm")
dev.off()



### 30-100 cm

prediction_30_100cm_avg <- mean(prediction_30m, prediction_1m)

prediction_30_100cm_g_cm2 <- prediction_30_100cm_avg*70 #multiply by 30cm  = layer thickness 

prediction_30_100cm_t_ha <- prediction_30_100cm_g_cm2 *100 # convert g per cm2 to Tonnes per Hectare 
#plot(prediction_30_100cm_t_ha)



png(filename = "./figures/prediction_30_100cm_t_ha.png", 
    #res = 120,
    width = 692, height = 426)
plot(prediction_30_100cm_t_ha, 
     main = "SOC stocks (t ha-1) to 30-100cm")
dev.off()


#### 0-100 cm

prediction_0_100cm_t_ha <- sum(prediction_0_30cm_t_ha, prediction_30_100cm_t_ha)


#plot the predictions
# plot(prediction_0_100cm_t_ha, 
#      main = "SOC stocks (t ha-1) to 1m")

png(filename = "./figures/prediction_0_100cm_t_ha.png", 
    #res = 120,
    width = 692, height = 426)
plot(prediction_0_100cm_t_ha, 
     main = "SOC stocks (t ha-1) to 1m")
dev.off()

#### 7. Area of acceptability ####

#need to remove depth
model_nndm$trainingData <- model_nndm$trainingData %>% 
  dplyr::select(-Depth_midpoint_m) #


AOA <- aoa(site_predictors_forpred_30m,
           trainDI = model_nndm$trainingData,
            model=model_nndm)
#plot(AOA, replace = TRUE)

print(str(AOA$parameters$train))
print(str(AOA$parameters$weight))

print(AOA$parameters$threshold) # everything larger than this threshold will be outside of aoa

#plot(AOA$DI)
#plot(AOA$AOA, legend = FALSE)# just have inside (1) or outside (0) the AOA
print(str(AOA$AOA))

#compare <- stack(prediction_0_100cm_t_ha, AOA$AOA)

png(filename = "./figures/AOA.png", 
    #res = 120,
    width = 692, height = 426)
plot(AOA$AOA, 
     legend = FALSE, 
     main = "Area of Acceptability")
dev.off()

print("The whole code ran successfully")

##### Mask predictions to AOA #####
# 
# AOA_prediction_0_100cm_t_ha <- mask(prediction_0_100cm_t_ha,
#                                     AOA$AOA,
#                                     maskvalue=0)

#plot(AOA_prediction_0_100cm_t_ha)
