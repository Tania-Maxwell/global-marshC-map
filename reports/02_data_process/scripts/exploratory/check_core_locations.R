### export information from papers 

rm(list=ls()) # clear the workspace
library(tidyverse)

#### import data ####
input_file01 <- "reports/04_data_process/data/data_cleaned.csv"

data0<- read.csv(input_file01)

str(data0)

data1 <- data0 %>% 
  filter(Source != "CCRCN")

test <- data1 %>% 
  filter(Source == "Rovai compiled" | 
           Source == "Rovai compiled, reference cited in Chmura (2003) and in Ouyang and Lee (2014)" | 
           Source == "Rovai compiled, reference cited in Ouyang and Lee (2014)" |
            Source == "Rovai compiled, reference cited in Ouyang and Lee (2020)")

#### 1. explore plot vs core columns ####
# 
# # grouping by to get number of layers per 
# plot_by_plot <- data1 %>% 
#   filter(is.na(Plot) == FALSE) %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Original_source, Source, Plot, GPS_combined) %>% 
#   dplyr::summarise(n_layers = n())
# 
# plot_by_core <- data1 %>% 
#   filter(is.na(Core) == FALSE) %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Original_source, Source, Plot, GPS_combined) %>% 
#   dplyr::summarise(n_layers = n())
# 
# 
# plot_by_site_name <- data1 %>% 
#   filter(is.na(Plot) == FALSE) %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Original_source, Source, Site_name) %>% 
#   dplyr::summarise(n_layers = n())
# 
# 
# test1 <- anti_join(plot_by_site_name, plot_by_plot)
# # need to improve plot name (add rep) for Gonzalez-Alcaraz et al 2012 - done
# 
# ## now for cores
# #by core
# core_by_core <- data1 %>% 
#   filter(is.na(Core) == FALSE) %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Original_source, Source, Core,GPS_combined) %>% 
#   dplyr::summarise(n_layers = n())
# 
# # by site
# core_by_site_name <- data1 %>% 
#   filter(is.na(Core) == FALSE) %>% 
#   group_by(Original_source, Source, Site_name) %>% 
#   dplyr::summarise(n_layers = n())
# 
# 
# # by GPS
# core_by_site_name_GPS <- data1 %>% 
#   filter(is.na(Core) == FALSE) %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Original_source, Source, Site_name, GPS_combined) %>% 
#   dplyr::summarise(n_layers = n())
# 
# test1 <- anti_join(core_by_core, core_by_site_name)
# test1 <- anti_join(core_by_site_name_GPS, core_by_site_name)
# 
# table(test$Source)


### this is how to check the data
data_all_GPS <- data1 %>% 
  mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
  group_by(Original_source, Source, Site_name)  %>% 
  dplyr::summarise(distinct_location = n_distinct(GPS_combined))


data_all_core_GPS <- data1 %>% 
  mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
  mutate(Core_plot = coalesce(Core, Plot)) %>% 
  group_by(Original_source, Source, Site_name, Core_plot)  %>% 
  dplyr::summarise(distinct_location = n_distinct(GPS_combined))


test_all <- anti_join(data_all_core_GPS, data_all_GPS)

# ## testing all studies with this code: 
# test <-  input_data04 %>% 
#   mutate(GPS_combined = paste(Latitude, Longitude)) %>% 
#   group_by(Source, Site_name, Plot)  %>% 
#   dplyr::summarise(distinct_location = n_distinct(GPS_combined))
