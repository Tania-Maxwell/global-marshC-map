## script to add a unique ID for each core
# note: this is because site_name was only in data paper, so CCRCN data don't have this info

# arguments for snakemake
args <- commandArgs(trailingOnly=T)
import_SaltmarshC <- args[1]
output_csv <- args[2]
output_for_GEE <- args[3]

# import_SaltmarshC <- "../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv"
# output_csv <- "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_all.csv"
# output_for_GEE <-  "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_uniqueLatLong_forGEE.csv"

#---------------------------------------------------#
#### 1. IMPORTS ####
#---------------------------------------------------#


#rm(list=ls()) # clear the workspace
library(tidyverse)

data0 <- read_csv(import_SaltmarshC) %>% 
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
length(unique(data_paper$Lat_Long)) #2360
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
  filter(is.na(Latitude) == FALSE & is.na(Longitude) == FALSE) %>% 
  mutate(DOI = case_when(Source == "Fuchs et al 2018" ~ "Conference",
                         TRUE ~ DOI)) 

write.csv(data_final, output_csv, row.names = F)


### export for GEE

export_df_GEE <- data_final  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  distinct(Lat_Long, .keep_all = TRUE) %>% 
  mutate(Point_ID = paste0("P", row_number())) %>% 
  relocate(Point_ID, .before = Source)

write.csv(export_df_GEE, output_for_GEE, row.names = F)


# unique_Lat_Long <- data_final  %>% 
#   mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
#   distinct(Lat_Long, .keep_all = TRUE) %>% 
#   dplyr::select("Source", "Site_name","Lat_Long")
# 
# 
# data_final_export <- left_join(unique_Lat_Long, data_final, by = c("Source", "Site_name"))
# write.csv(data_final_export, output_csv, row.names = F)
#---------------------------------------------------#
#### 3. TESTS ####
#---------------------------------------------------#

ncores <- data_final %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  filter(U_depth_m == 0) #6096

duplicates <- data_final %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  filter(U_depth_m == 0) %>% 
  group_by(Lat_Long) %>% 
  filter(n()>1) #2835

onelocation <- data_final %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  filter(U_depth_m == 0) %>% 
  group_by(Lat_Long) %>% 
  filter(n()==1) #3261


export_df_GEE_Lat_Long <- data_final  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  distinct(Lat_Long, .keep_all = TRUE) # note, this is the same as unique Lat_Long if paste(Latitude, Longitude

length(unique(export_df_GEE_Lat_Long$Lat_Long)) #4387
table(export_df_GEE_Lat_Long$Country)

export_df_GEE_Site_name <- data_final  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  distinct(Site_name, .keep_all = TRUE) # note, this is the same as unique Lat_Long if paste(Latitude, Longitude

diff <- anti_join(export_df_GEE_Site_name, export_df_GEE_Lat_Long)
table(diff$Source)
table(diff$Country)
