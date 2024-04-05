library(tidyverse)
library(sf) #to map
library(rnaturalearth) #privides map of countries of world
library(viridis) # for map colors
# https://sjmgarnier.github.io/viridis/

data_clean_SOCD <- read.delim("reports/05_figures/paper_figures/Carbon_Points_MEOW.txt", sep = ",")

world <- ne_countries(scale = "medium", returnclass = "sf")

# The palette with grey:
cbPalette <- c("#000000","#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")


fig_paper <- ggplot(data = world) +
  geom_sf() +
  coord_sf(ylim = c(-60, 65), expand = FALSE)+
  theme_bw()+
  geom_point(data = data_clean_SOCD, aes(x = Longitude, y = Latitude, fill = REALM),
             size = 3, shape = 21,  alpha = 0.5)+
  scale_size(range = c(2,8))+
  scale_fill_manual(name = "Realm", values=cbPalette,
                    guide = guide_legend(override.aes = 
                                           list(size = 5, alpha = 1))) +
  # scale_fill_viridis(name = "Realm", discrete = TRUE, option = "D",
  #                    guide = guide_legend(override.aes = list(size = 5,
  #                                                             alpha = 1)))+
  theme(legend.position = "bottom",
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))

fig_paper

# ggsave("reports/05_figures/paper_figures/Figure S1.png", fig_paper, width = 12.30, height = 6.27)



##### averages for paper #### 

unique_loc <- data_clean_SOCD %>% 
  distinct(Latitude, Longitude, .keep_all = TRUE)
nrow(unique_loc)

length(unique(data_clean_SOCD$Country))

loc_aus_uk_usa <-unique_loc %>% 
  filter(Country == "Australia" | Country == "United States" | 
           Country == "UK")

nrow(loc_aus_uk_usa)/nrow(unique_loc)*100

deeper30cm <- data_clean_SOCD %>% 
  filter(Horizon_mi > 30)

nrow(deeper30cm)/nrow(data_clean_SOCD)*100

