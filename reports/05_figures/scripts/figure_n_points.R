## script to generate the 
# tlgm2@cam.ac.uk
# 30.08.23

library(tidyverse)

#import final SOCD data
input_file01 <- "reports/02_data_process/snakesteps/04_OCD/data_clean_SOCD.csv"

data0 <- read.csv(input_file01) 


input_file02 <- "reports/03_modelling/data/2023-08-30_data_covariates_global.csv"

covariates <- read.csv(input_file02) 
plot(covariates$minTemp, covariates$maxTemp)
cor.test(covariates$minTemp, covariates$maxTemp)

plot(covariates$minPrecip, covariates$maxPrecip)
cor.test(covariates$minPrecip, covariates$maxPrecip)

plot(covariates$PETdry, covariates$PETwarm)
cor.test(covariates$PETdry, covariates$PETwarm)




data1 <- data0 %>%
  distinct(Latitude, Longitude, .keep_all = TRUE) %>% 
  mutate(Dataset_source = case_when(Source == "CCRCN" ~ "CCRCN", 
                                    TRUE ~ "MarSOC")) %>% 
  mutate(Lat_Long = paste(Latitude, Longitude, sep = "_"))

library(sf) #to map
library(rnaturalearth) #privides map of countries of world
library(viridis) # for map colors
# https://sjmgarnier.github.io/viridis/
library(hexbin)
world <- ne_countries(scale = "medium", returnclass = "sf")


h <- hexbin(x=data1$Longitude, y=data1$Latitude, xbins=20, shape=1, IDs=TRUE)
hexdf <- data.frame (hcell2xy (h),  hexID = h@cell, counts = h@count)


fig_paper <- ggplot(data = world) +
  geom_sf() +
  coord_sf(ylim = c(-60, 80), expand = FALSE)+
  theme_bw()+
  geom_hex(data = hexdf, aes(x = x,
                             y = y,
                             fill = counts, hexID = hexID),
           stat = "identity",
           binwidth = c(3, 3))+
  theme(legend.position = "bottom",
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))

fig_paper


fig_paper <- ggplot(data = world) +
  geom_sf() +
  coord_sf(ylim = c(-60, 80), expand = FALSE)+
  theme_bw()+
  theme(plot.title = element_text(size = 18, hjust = 0.5))+
  geom_hex(data = data1, aes(x = Longitude,
                             y = Latitude,
                             fill = stat(cut(log(count),
                                             breaks = log(c(0,1,5,10,15,Inf)),
                                             labels = F, right = T, include.lowest = T))),
           binwidth = c(3, 3))+
  # geom_point(data = data1, aes(x = Longitude, y = Latitude,
  #                                          fill = Dataset_source), size = 3, shape = 21, alpha = 0.5)+
  # #scale_size(range = c(2,8))+
  scale_fill_viridis(name = "Number of data locations:", option = "D", 
                     labels = c('1','5','10','15', '+' ))+
  theme(legend.position = "bottom",
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))

fig_paper


##### export Fig. 1 n points ####
path_out = 'reports/05_figures/paper_figures/'


fig_name <- "n_points"
export_file <- paste(path_out, fig_name, ".png", sep = '')

ggsave(export_file, fig_paper, width = 11.26, height = 6.11)
