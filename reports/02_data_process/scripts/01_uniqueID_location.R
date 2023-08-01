## script to add a unique ID for each core
# note: this is because site_name was only in data paper, so CCRCN data don't have this info


#---------------------------------------------------#
#### 1. IMPORTS ####
#---------------------------------------------------#


rm(list=ls()) # clear the workspace
library(tidyverse)

data0 <- read_csv("../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv") %>% 
  filter(!grepl("Outlier", Notes, ignore.case = TRUE))


#---------------------------------------------------#
#### 2. DATA CHECKS ####
#---------------------------------------------------#

data_paper <- data0 %>% 
  filter(Source != "CCRCN")%>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  mutate(Test = case_when(is.na(Core) == FALSE ~ paste(Original_source, Core),
                               is.na(Plot) == FALSE ~ paste(Original_source, Plot)))

## a few cores have the same lat and long
length(unique(data_paper$Lat_Long)) #2380
length(unique(data_paper$Site_name)) #3503
length(unique(data_paper$Test)) # note there are core or plot IDs the same

CCRCN <- data0 %>% 
  filter(Source == "CCRCN") %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  mutate(Site_name = paste(Original_source, Core))

## unique CCRCN locations - note: many unique cores have the same lat,long
length(unique(CCRCN$Lat_Long)) #2031
length(unique(CCRCN$Site_name)) #2789

table(is.na(data0$Latitude))
table(is.na(data0$Longitude))
# one location with NA for Lat and LOng (from He et al)
  
#---------------------------------------------------#
  #### 2. EXPORTS ####
#---------------------------------------------------#
  
### export for modelling 
data_final <- data0 %>% 
  mutate(Site_name = case_when(Source == "CCRCN" ~ paste(Original_source, Core),
                               Source != "CCRCN" ~ Site_name)) %>% 
  filter(is.na(Latitude) == FALSE & is.na(Longitude) == FALSE)


path_out = 'reports/02_data_process/data/'

file_name <- "data_clean_SOMconv_uniqueSiteName.csv"
export_file <- paste(path_out, file_name, sep = '')

write.csv(data_final, export_file, row.names = F)


### export for GEE

export_df_GEE <- data_final  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  distinct(Site_name, .keep_all = TRUE) # note, this is the same as unique Lat_Long if paste(Latitude, Longitude


file_name_GEE <- paste(Sys.Date(),"data_clean_SOMconv_uniqueSiteName_forGEE.csv", sep = "_")
export_file_GEE <- paste(path_out, file_name_GEE, sep = '')

write.csv(export_df_GEE, export_file_GEE, row.names = F)

