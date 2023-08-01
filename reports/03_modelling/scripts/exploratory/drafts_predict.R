
#### OLD SCRIPTS ####

##### trying Florian's script to load TIFs ########
setwd("//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK")

rast_dir <- "//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK"
list_dir <- as_tibble(dir(rast_dir))

tmp <- list_dir
tmp_l <- list() #creating an empty list

for (b in 1:nrow (tmp)){
  tmp_l[b]<- rast (file.path(rast_dir, tmp[b,1])) #filling the list with all tiles in the directory
}

tmp_c <- sprc(tmp_l) # turning into spatRasterCollection

#first import all files in a single folder as a list 
rastlist <- list.files(path = "//wsl.localhost/Ubuntu/home/tlgm2/tiles_test/tiles_UK", pattern='.tif', 
                       all.files=TRUE, full.names=FALSE)

rastlist_subset <- rastlist[5:10]

#import all raster files in folder using lapply
allrasters <- lapply(rastlist_subset, raster::stack)

#to check the index numbers of all imported raster list elements
allrasters


##### predictions test on 1 raster#####

#load the training model (just from the site)
model_nndm <- readRDS("~/07_Cam_postdoc/global-marshC-map/reports/03_modelling/data/model_nndm_site_v_1_4.rds")

#
Depth_to_predict_0m <- raster(vals = 0, #depth at which we want to predict
                              nrow = nrow(raster_test), 
                              ncol = ncol(raster_test),
                              crs = crs(raster_test),
                              ext = extent(raster_test))
prediction_1m <- predict(site_predictors_forpred_1m, model_nndm)


#################

setwd("//wsl.localhost/Ubuntu/home/tlgm2/tiles_test?")

##### 1. Import predictor rasters from GEE ####
# get_names <- raster::stack("reports/03_modelling/data/export_europe_layers_30m-0000009216-0000027648.tif") #
# names(get_names)

#predictors0 <- raster::stack("tiles_europe.tif") #


predictors0 <- raster::stack("reports/03_modelling/data/export_europe_layers_30m-0000009216-0000027648.tif") #

#test <- terra::rast("reports/03_modelling/data/export_europe_layers_30m-0000009216-0000027648.tif")

#names(predictors0)[]<-names(get_names)
names(predictors0)
print(predictors0)

site_predictors <- predictors0

# x <- "maxTemp"
# 
# raster::plot(predictors0$maxTemp, 
#              main = names(predictors0$maxTemp),
#              xlim = c(raster::xmin(predictors0), raster::xmax(predictors0)),
#              ylim = c(raster::ymin(predictors0), raster::ymax(predictors0)),
#              xlab = "Latitude",
#              ylab = "Longitude",
#              col= viridis(n = 3, option = "D"))


## area of saltmarsh in site
a <- terra::rast(site_predictors[[1]]) #
site_area_ha <- terra::expanse(a,  unit = "ha") #
print(site_area_ha)



##### 2. Import sample points ####

df0 <- read.csv("../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv")  %>% 
  filter(!grepl("Outlier", Notes, ignore.case = TRUE)) 

df1 <- df0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = (L_depth_m - U_depth_m)/2,
         Depth_thickness_m = L_depth_m - U_depth_m) %>% 
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


##### training
# df0 <- read.csv("reports/03_modelling/data/2023-06-16_data_uk_test.csv")%>% 
#   filter(!grepl("Outlier", Notes, ignore.case = TRUE))  #remove outliers
