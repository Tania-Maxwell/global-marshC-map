## script to visualize data points outside of Tom's extent map


#rm(list=ls()) # clear the workspace
library(tidyverse)

# arguments for snakemake
args <- commandArgs(trailingOnly=T)
import_data <- args[1]
# import_GEE_data <- args[2]
export_file <- args[2]


# import_data <- "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_all.csv"
#  # import_GEE_data <- "reports/03_modelling/data/2023-08-25_data_covariates_global.csv"
# export_file <- "reports/02_data_process/snakesteps/02_checkLocations/data_clean_locationsEdit.csv"

soc_data <- read_csv(import_data)
# 
# 
# ####### GEE points with NAs
# 
# #### import 2: load predicted values of covariate layers (from GEE) for each training data (unique lat and long)
# GEE_data_raw <- read_csv(import_GEE_data) %>% 
#   #only select the variable names extracted using GEE
#   dplyr::select(Site_name, 
#                 ndvi_med, ndvi_stdev,
#                 #evi_med, evi_stdev,
#                 #savi_med, savi_stdev,
#                 Human_modification, M2Tide, PETdry, PETwarm,
#                 TSM, maxTemp, minTemp, minPrecip, popDens, 
#                 copernicus_elevation,
#                 copernicus_slope, 
#                 # coastalDEM_elevation,
#                 #coastalDEM_slope,
#                 # srtm_elevation,
#                 # srtm_slope,
#                 # merit_elevation,
#                 # merit_slope,
#                 .geo,
#                 Lat_Long) 
# 
# 
# 
# colnms <- colnames(GEE_data_raw)
# GEE_data_NAs <- GEE_data_raw %>% # issues with NAs
#   filter_at(vars(all_of(colnms)), any_vars(is.na(.))) %>% 
#   separate(Lat_Long, c("Latitude", "Longitude"), "_") 
# 
# # path_out = 'reports/02_data_process/data/'
# # file_name_GEE <- paste(Sys.Date(),"GEE_export_NAs.csv", sep = "_")
# # export_file_GEE <- paste(path_out, file_name_GEE, sep = '')
# # write.csv(GEE_data_NAs, export_file_GEE, row.names = F)
# #dataNAs0 <- read_csv("reports/02_data_process/data/2023-08-01_GEE_export_NAs.csv") 
# 
# 
# # exclude sites over 60deg N
# dataNAs <- GEE_data_NAs %>% 
#   filter(Latitude <= 60)
# 
# 
# test <- dataNAs %>% 
#   mutate(initials = str_extract(Site_name, pattern = "\\w+")) %>% 
#   filter(initials == "MC")
# test$initials
# 


####### check data outside extent ####

# import_geojson <- function(x) {
#   print(x)
#   as.data.frame(geojson_read(x, what = "sp"))
# }
# 
# data0 <- import_geojson("reports/03_modelling/data/2023-07-17_data_outside_extent.geojson") 
# 
# data_explore <- data0 %>% 
#   group_by(Original_source, Country) %>% 
#   summarise(avg_distance = round(mean(distance), 0) )
# data_explore
# 

########## remove points after check  ###########
soc_locations_edited <- soc_data %>% 
  # Kauffman et al - cores seem to be located in mangroves - likely a location error
  filter(Site_name != "JBK Marisma High 1", Site_name != "JBK Marisma High 2",
         Site_name != "JBK Marisma High 3", Site_name != "JBK Marisma High 4", 
         Site_name != "JBK Marisma Medium 6")

## note: points outside of the bathymask will be removed as they will not have an ndvi value
# this is removed in the script reports/03_modelling/scripts/01_training_data

########## export ###########
write.csv(soc_locations_edited, export_file, row.names = F)
