# compare pekel water occurrence with SRTM and MERIT-DEM 
# import data from csv file, exported from GEE

library(tidyverse)
export_UK_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_UK_1.csv") %>% 
  mutate(location = "UK")
str(export_UK_1)

export_EastCoast_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_USEastCoast_1.csv") %>% 
  mutate(location = "East Coast")

export_WestCoast_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_USWestCoastnew_1.csv") %>% 
  mutate(location = "West Coast")

export_Australia_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_australia_1.csv") %>% 
  mutate(location = "Australia")

export_SouthAmerica_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_SouthAmerica_1.csv") %>% 
  mutate(location = "SouthAmerica")

export_Europe_1 <- read_csv("reports/04_data_process/data/export_waterOcc_MERIT_SRTM_Europe_1.csv") %>% 
  mutate(location = "Europe")


export_all <- rbind(export_UK_1, export_EastCoast_1,export_WestCoast_1,
                    export_Australia_1, export_SouthAmerica_1, export_Europe_1 )


srtm_merit <- export_all %>% 
  filter(SRTM_elevation <20) %>%
  ggplot(aes(x = SRTM_elevation, y = MERIT_elevation))+
  geom_point(aes(color = location)) + 
  theme_bw()+
  geom_abline()
srtm_merit

merit_pekel <- export_all %>% 
  filter(MERIT_elevation <20) %>% 
  ggplot(aes(x = MERIT_elevation, y = occurrence))+
  geom_point(aes(color = location)) + 
  theme_bw()
merit_pekel

srtm_pekel <- export_all %>% 
  filter(SRTM_elevation <20) %>% 
  ggplot(aes(x = SRTM_elevation, y = occurrence))+
  geom_point(aes(color = location)) + 
  theme_bw()
srtm_pekel

library(ggpubr)
combined <- ggarrange(srtm_merit, merit_pekel,srtm_pekel)
combined

slope_occ <- export_all %>% 
  filter(MERIT_elevation <20) %>% 
  ggplot(aes(x = MERIT_slope, y = occurrence))+
  geom_point(aes(color = location)) + 
  theme_bw()
slope_occ
