#script following Hanna Meyer Rmd casy study code from OpenGeoHub 2022 summer school
# applying to site 

library(virtualspecies)
library(caret)
library(CAST) #AOA and CV strategy 
library(viridis)
library(sf)
library(raster)
library(knitr)
library(tidyverse)
library(geojsonsf) # geojson_sf() function
library(sf) #st_coordinates() function

seed <- 1234


#### import data ####

GEE_data <- read_csv("reports/05_modelling/data/export_site_v_1_4.csv") %>% 
  mutate(Plot = as.factor(Plot)) %>% 
  dplyr::select(Site_name, 
                coastTyp_mode_mode, #not now that only 1 level?
                SRTM_elevation, #SRTM elevation
                evi_med, evi_stdev,
                flowAcc, flowAcc_1, gHM_2016 , maxTemp,
                merit_elevation, 
                merit_slope, 
                minPrecip , minTemp, M2Tide,
                ndvi_med, ndvi_stdev, PETdry, PETwarm,
                popDens_change, savi_med, savi_stdev, SRTM_slope,
                TSM, occurrence,
                .geo) %>% 
  dplyr::rename(coastTyp = coastTyp_mode_mode)
#and the response variables
#SOCD_g_cm3) 


training_data <- read_csv("reports/04_data_process/data/data_cleaned_SOMconverted.csv")

df0 <- inner_join(GEE_data,training_data, by = "Site_name")


df1 <- df0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = (L_depth_m - U_depth_m)/2,
         Depth_thickness_m = L_depth_m - U_depth_m) %>% 
  ##converting SOM to OC just for test (this will be done beforehand for final data)
  mutate(OC_perc_estimated = 0.000838*(SOM_perc_combined^2) + 
           0.3953*SOM_perc_combined - 0.5358) %>% 
  mutate(OC_perc_final = coalesce(OC_perc_combined, OC_perc_estimated)) %>%
  mutate(SOCD_g_cm3 = BD_reported_combined*OC_perc_final/100,
         SOCS_g_cm2 = SOCD_g_cm3 * 100 *Depth_thickness_m,
         # 100,000,000 cm2 in 1 ha and 1,000,000 g per tonne
         SOCS_t_ha = SOCS_g_cm2 * (100000000)/1000000) %>% 
  filter(is.na(SOCD_g_cm3) == FALSE)

str(df1)





#### 2. subset data for traindat ####

## for the sf package, need to have 2 separate files
# the response-predictor matrix and the coordinates matrix (cols = x,y)


#subset the predictor and response variables 
predictors <- df1 %>% 
#should have 22 
  dplyr::select(Depth_midpoint_m , 
               # coastTyp, #not now that only 1 level?
                SRTM_elevation, #SRTM elevation
                evi_med, evi_stdev,
                flowAcc, flowAcc_1, gHM_2016 , maxTemp,
                merit_elevation, 
                merit_slope, 
                #minPrecip , 
                minTemp, M2Tide,
                ndvi_med, ndvi_stdev, PETdry, PETwarm,
                popDens_change, savi_med , savi_stdev , SRTM_slope,
                TSM, occurrence
                ) %>% 
  dplyr::rename(flowAcc_MERIT = flowAcc,
                flowAcc_SRTM = flowAcc_1)  
  #mutate(coastTyp = as.factor(coastTyp))


response <- df1 %>%
  dplyr::select(SOCD_g_cm3) %>%  #and the response variables
  dplyr::rename(OC = SOCD_g_cm3)

summary(response$OC)

str(predictors)


############# 3. visualize data ###########

hist(df1$SRTM_elevation)

df_viz <- df1 %>% 
  #should have 22 
  dplyr::select(Depth_midpoint_m , 
                coastTyp, #not now that only 1 level?
                SRTM_elevation, #SRTM elevation
                evi_med, evi_stdev,
                flowAcc, flowAcc_1, gHM_2016 , maxTemp,
                merit_elevation, 
                merit_slope, 
                minPrecip , minTemp, M2Tide,
                ndvi_med, ndvi_stdev, PETdry, PETwarm,
                popDens_change, savi_med , savi_stdev , SRTM_slope,
                TSM, occurrence, SOCD_g_cm3
  ) %>% 
  dplyr::rename(flowAcc_MERIT = flowAcc,
                flowAcc_SRTM = flowAcc_1) %>% 
  mutate(coastTyp = as.factor(coastTyp))



d = reshape2::melt(df_viz, id.vars = "SOCD_g_cm3")

xyplot(SOCD_g_cm3 ~ value | variable, data = d, pch = 21, fill = "lightblue",
       col = "black", ylab = "response (SOCD_g_cm3)", xlab = "predictors",
       scales = list(x = "free",
                     tck = c(1, 0),
                     alternating = c(1, 0)),
       strip = strip.custom(bg = c("white"),
                            par.strip.text = list(cex = 1.2)),
       panel = function(x, y, ...) {
         panel.points(x, y, ...)
         panel.loess(x, y, col = "salmon", span = 0.5)
       })



#### 4. preparing different CVs (random, spatial, nndm) ####

#### RANDOM
random_cv <- createFolds(response$OC,k=10,returnTrain=FALSE)
str(random_cv)

#### Leave-Cluster-Out "Spatial" CV

coords_forsf <- st_as_sf(data.frame(df1, geom=geojson_sf(df1$.geo))) 

#how to extract coordinates from geometry column in df
coords = sf::st_coordinates(coords_forsf) %>%
  as.data.frame %>%
  dplyr::rename(x = X, y = Y)

samplepoints = cbind(coords, df1$Site_name) %>% 
  dplyr::rename(Site_name = 'df1$Site_name')


# Leave-Cluster-Out "Spatial" CV
# divide training data into 10 fold; in each fold, leave one data from clusterID out
spatial_cv <- CreateSpacetimeFolds(samplepoints, spacevar="Site_name",k=10)
str(spatial_cv)
#training is in the index, data left out is indexOut 


#### Nearest neighbor Distance Matching 

### prepare coordinate info for nndm 
# need training points as an sf object and the area of prediction (i.e. the site or region)
# both need to have the same crs included

### for the nndm function, you also need the area of prediction
#https://gis.stackexchange.com/questions/403977/sf-create-polygon-from-minimum-x-and-y-coordinates
lon = c(0.6621003481445342, 0.9882569643554717) # min and max (corners)
lat = c(51.67979880621543, 51.78951129583516) # min and max (corners)

pol = st_polygon(
  list(
    cbind(
      lon[c(1,2,2,1,1)], 
      lat[c(1,1,2,2,1)])
  ))

site_polygon = st_sfc(pol, crs = 32611)



samplepoints_fornndm = sf::st_as_sf(samplepoints, coords = c("x", "y"), crs = 32611) %>% 
  dplyr::select(-Site_name)


# Nearest neighbor Distance Matching
#takes sampling point and the study area (for which are we want to make predictions)
NNDM_cv <- nndm(samplepoints_fornndm, modeldomain = site_polygon)
print(NNDM_cv)



#### 5. random forest with different CVs (random, spatial, nndm) ####


## model training with default random CV

model_random <- train(predictors,
                    response$OC,
                    method="rf")
model_random


### model training with a classic spatial CV
model_spatial <- train(predictors,
                       response$OC,
                       method="rf",
                       ntree=100,
                       importance=TRUE,
                       tuneGrid = data.frame("mtry"=2),
                       trControl = trainControl(method="cv",
                                                index=spatial_cv$index,
                                                savePredictions = TRUE))
model_spatial 


### 
varim_sp <- varImp(model_spatial)

plot(varim_sp)



### Nearest neighbor Distance Matching 

model_nndm <- train(predictors,
                    response$OC,
                    method="rf",
                    ntree=100,
                    importance=TRUE,
                    tuneGrid = data.frame("mtry"=2), # reduced tuning to make this faster 
                    trControl = trainControl(method="cv",
                                             index=NNDM_cv$indx_train,
                                             indexOut=NNDM_cv$indx_test,
                                             savePredictions = TRUE))
model_nndm # R2 isn't implemented 

varim_nndm <- varImp(model_nndm)

plot(varim_nndm)

#### EXPORT MODEL ####
# export the nndm model

#saveRDS(model_nndm, "reports/05_modelling/data/model_nndm_site_v_1_4.rds")


#### 6. further model tests ####


## trying to remove srtm variables

predictors_noSRTM <- predictors %>% 
  #should have 22 
  dplyr::select(-SRTM_elevation, #SRTM elevation
                -flowAcc_SRTM, -SRTM_slope)

model_spatial_noSRTM <- train(predictors_noSRTM,
                       response$OC,
                       method="rf",
                       ntree=100,
                       importance=TRUE,
                       tuneGrid = data.frame("mtry"=2),
                       trControl = trainControl(method="cv",
                                                index=spatial_cv$index,
                                                savePredictions = TRUE))
model_spatial_noSRTM

varim_sp <- varImp(model_spatial_noSRTM)

plot(varim_sp)



#### 7. trying forward feature selection ####
#forward feature selection: a wrapper around the model training
model_ffs <- ffs(predictors_noSRTM,
                 response$OC,
                 method="rf",
                 ntree=100,
                 importance=TRUE,
                 tuneGrid = data.frame("mtry"=2),
                 trControl = trainControl(method="cv",
                                          index=spatial_cv$index, #here, used spatial_cv because 10-fold is faster than 300-fold in the nndm approach (although if had time she would do this)
                                          savePredictions = TRUE),
                 verbose=FALSE)
model_ffs
model_ffs$selectedvars

# 02.02.23 "evi_med"       "TSM"           "M2Tide"        "flowAcc_MERIT" "maxTemp"    
plot_ffs(model_ffs)

#see which variables are selected by the variable strategy
plot_ffs(model_ffs, plotType = "selected")



### do cross-validation again with NNDM using selected variables only
model_nndm_ffs <- train(predictors_noSRTM[,model_ffs$selectedvars], # train only with selected variables
                    response$OC,
                    method="rf",
                    ntree=100,
                    importance=TRUE,
                    tuneGrid = data.frame("mtry"=2),
                    trControl = trainControl(method="cv",
                                             index=NNDM_cv$indx_train,
                                             indexOut=NNDM_cv$indx_test,
                                             savePredictions = TRUE))

model_nndm_ffs # odd - RMSE is HIGHER here 0.02033 compared to previous model_nndm is 0.01695

