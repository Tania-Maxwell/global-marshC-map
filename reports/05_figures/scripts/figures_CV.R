

rm(list=ls()) # clear the workspace
library(tmap)
library(sf)
library(viridis)
library(tidyverse)
library(terra) #crs()
library(CAST)
library(geojsonsf)
library(patchwork)



############## Global Spatial CV Folds ##################
source("reports/05_figures/scripts/geodist.R") # from https://github.com/HannaMeyer/CAST/blob/e5c4b4e672578016f55a8ce29f41dfe9f36595c5/R/geodist.R
import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_grid <- "reports/04_model_tests/02_CV/spatial_folds_grid6.gpkg"
import_folds <- "reports/04_model_tests/02_CV/folds6.RDS"
import_global <- "reports/03_modelling/data/global_sample_5k.csv"
output_folds <- "reports/04_model_tests/02_CV/spatialCV_folds_6deg.pdf"
output_samples <- "reports/04_model_tests/02_CV/spatialCV_samples_6deg.pdf"
output_distance <- "reports/04_model_tests/02_CV/spatialCV_distance_6deg.pdf"

trainDat <- st_read(import_data, quiet = TRUE)

training_samples <- trainDat %>% 
  mutate(long = unlist(map(trainDat$geom,1)),
         lat = unlist(map(trainDat$geom,2)),
         lat_long = paste(lat, long, sep = "_"))

global_grid = st_read(import_grid, quiet = TRUE)

cvfolds <- readRDS(import_folds)

global_csv <- read_csv(import_global) 

global_sample <- st_as_sf(data.frame(global_csv, geom = geojson_sf(global_csv$.geo)))


########### Figure a: folds in grid ##############


# tmap setup
countries = rnaturalearth::countries110 %>%
  st_as_sf() %>%
  filter(geounit != "Antarctica") %>%
  st_transform("+proj=eqearth") %>% 
  st_union()

# reproject
training_samples = st_transform(training_samples, "+proj=eqearth", crs = terra::crs(countries))
global_grid = st_transform(global_grid, "+proj=eqearth", crs = terra::crs(countries))



col_pal = c("#7FFFD4", "#FFE4C4", "#FF7F00", "#FF3030", "#1E90FF",
            "#999999", "#C0FF3E", "#698B22", "#27408B", "#EE82EE")
names(col_pal) = seq(0,9,1)

sla_folds = tm_shape(countries)+
  tm_borders()+
  tm_shape(global_grid)+
  tm_polygons(title = "Fold", col = "fold", style = "cat", pal = col_pal, lwd = 0.2)+
  tm_layout(legend.show = TRUE,
            bg.color = "white",
            frame = FALSE,
            panel.show = FALSE,
            earth.boundary = c(-180, -88, 180, 88),
            earth.boundary.color = "transparent")
sla_folds
#tmap_save(sla_folds, filename = output_folds, width = 15, height = 10, units = "cm")


########### Figure b: n samples in grid ##############

global_grid$samples = lengths(st_intersects(global_grid, training_samples))
global_grid = global_grid %>% filter(samples != 0)


sla_samples = tm_shape(countries)+
  tm_borders()+
  tm_shape(global_grid)+
  tm_polygons(title = "Training Samples [n]", col = "samples", style = "log10", pal = viridis(50), 
              legend.is.portrait=FALSE, lwd = 0.2)+
  tm_layout(legend.show = TRUE,
            bg.color = "white",
            frame = FALSE,
            panel.show = FALSE,
            earth.boundary = c(-180, -88, 180, 88),
            earth.boundary.color = "transparent")
sla_samples
#tmap_save(sla_samples,filename = output_samples, width = 15, height = 10, units = "cm")




########### Figure c: geographic distance ##############

cvfolds = data.frame(fold = cvfolds)

cvfolds = cvfolds %>% dplyr::group_by(fold) %>%
  attr('groups') %>% dplyr::pull(.rows)

distance <- "geo"
modeldomain <- global_sample

training_samples_unique <- training_samples %>% 
  distinct(lat_long, .keep_all = TRUE)

sample_to_sample = sample2sample(x = training_samples_unique, type = "geo")

sample_to_prediction = sample2prediction(x = training_samples_unique,
                                                modeldomain = global_sample,
                                         type = "geo")

between_folds = cvdistance(x = training_samples_unique,
                                  cvfolds = cvfolds,
                           cvtrain = NULL, type = "geo")


result = rbind(sample_to_sample,sample_to_prediction, between_folds)

xlabs <- "log10(geographic distances (m))"

plot_distance <- ggplot2::ggplot(data=result, aes(x=log10(dist), group=what, fill=what)) +
  ggplot2::geom_density(adjust=1.5, alpha=.4, stat="density") +
  ggplot2::scale_fill_discrete(name = "distance function") +
  ggplot2::scale_x_continuous(name = "Geographic distances (m)", breaks = c(0,2,4,6), 
                              labels = c(10, expression(10^2),expression(10^4), expression(10^6)))+
  ggplot2::scale_y_continuous(name = "Density")+
  ggplot2::theme(legend.position="bottom",
                 plot.margin = unit(c(0,0.5,0,0),"cm"),
                 axis.title = element_text(size = 14),
                 axis.text = element_text(size = 12, color = "black"),
                 legend.title = element_text(size = 14),
                 legend.text = element_text(size = 12, color = "black"))
plot_distance

ggsave(output_distance, plot_distance, width = 9.14, height = 6.20)

########### Figure 1: COMBINE ##############

folds_grob <- tmap_grob(sla_folds)
samples_grob <- tmap_grob(sla_samples)

# #note: patchwork doesn't work for tmap
# layout <- "
# AA##
# AACC
# BBCC
# BB##
# "
# folds_grob + samples_grob + plot_distance + patchwork::plot_layout(design = layout)


p <- plot_grid(folds_grob, samples_grob)

