## script to visualize data points outside of Tom's extent map


#rm(list=ls()) # clear the workspace
library(tidyverse)

# arguments for snakemake
args <- commandArgs(trailingOnly=T)
import_data <- args[1]
import_unique <- args[2]
import_buffer5km <- args[3]
import_buffer10km <- args[4]
export_file <- args[5]


# import_data <- "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_all.csv"
# import_unique <- "reports/02_data_process/snakesteps/01_uniqueID/data_clean_SOMconv_uniqueLatLong_forGEE.csv"
# import_buffer5km <- "reports/02_data_process/data/TidalMarsh_Training_Buffer_5km.txt"
# import_buffer10km <- "reports/02_data_process/data/TidalMarsh_Training_Buffer_10km.txt"
# export_file <- "reports/02_data_process/snakesteps/02_checkLocations/data_clean_locationsEdit.csv"

soc_data <- read_csv(import_data)  %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_" ))

soc_unique <- read_csv(import_unique)

buffer_5km <- read_csv(import_buffer5km) %>% 
  rename(keep_5km = KEEP) %>% 
  select(Point_ID, keep_5km)

buffer_10km <- read_csv(import_buffer10km)%>% 
  rename(keep_10km = KEEP) %>% 
  select(Point_ID, keep_10km)


####### check data outside extent ####

buffer_5km_join <- left_join(soc_unique, buffer_5km, by = "Point_ID")

buffer_all <- left_join(buffer_5km_join, buffer_10km, by = "Point_ID") %>% 
  relocate(keep_5km, keep_10km, .after = Point_ID)


data_outside5km <- buffer_all %>%
  filter(keep_5km == 0)
table(data_outside5km$Country) #313 locations removed

data_outside10km <- buffer_all %>%
  filter(keep_10km == 0)
table(data_outside10km$Country) #209 locations removed

data_diff_buffer <- anti_join(data_outside5km, data_outside10km)

#### keep only data within the 10km buffer

data_keep_in_10km_unique <- buffer_all %>% 
  filter(keep_10km == 1) %>% 
  select(keep_10km, Lat_Long)

data_keep_in_10km <- inner_join(soc_data, data_keep_in_10km_unique, by = "Lat_Long")
print(paste("samples within 10km from extent:", table(data_keep_in_10km$keep_10km)))

########## remove points after check  ###########
soc_locations_edited <- data_keep_in_10km %>% 
  # Kauffman et al - cores seem to be located in mangroves - likely a location error
  filter(Site_name != "JBK Marisma High 1", Site_name != "JBK Marisma High 2",
         Site_name != "JBK Marisma High 3", Site_name != "JBK Marisma High 4", 
         Site_name != "JBK Marisma Medium 6") %>% 
  filter(Latitude <= 60) %>% 
  dplyr::select(-keep_10km)
## these were already removed by being more than 10km from the extent


## note: points outside of the bathymask will be removed as they will not have an ndvi value
# this is removed in the script reports/03_modelling/scripts/01_training_data

########## export ###########

write.csv(soc_locations_edited, export_file, row.names = F)
