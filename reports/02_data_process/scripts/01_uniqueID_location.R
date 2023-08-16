## script to add a unique ID for each core
# note: this is because site_name was only in data paper, so CCRCN data don't have this info

# arguments for snakemake
args <- commandArgs(trailingOnly=T)
import_SaltmarshC <- args[1]
output_csv <- args[2]
output_for_GEE <- args[3]

# import_SaltmarshC <- "../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv"
# output_csv <- "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName.csv"
# output_for_GEE <-  "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName_forGEE.csv"

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


write.csv(data_final, output_csv, row.names = F)


### export for GEE

export_df_GEE <- data_final  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" )) %>% 
  distinct(Site_name, .keep_all = TRUE) # note, this is the same as unique Lat_Long if paste(Latitude, Longitude


write.csv(export_df_GEE, output_for_GEE, row.names = F)

