#------------------------------------------------------#
# Figure: predictor values of training data ####
#------------------------------------------------------#

library(tidyverse)
library(sf) #st_read
library(cowplot) # plot_grid
library(grid) # textGrob
library(gridExtra) #grid.arrange

import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response)



plot_predictors <- function(var){
  p <- ggplot(data = trainDat, aes(x = .data[[var]], y = response))+
    geom_point()+
    geom_smooth()+
    theme_bw()+   
    labs(y = "")+
    theme(axis.text = element_text(size = 12, color = 'black'),
          axis.title = element_text(size = 16, color = 'black')) 
  return(p)
}


plot_list = list() 

for (i in names(trainDat_formod)){
  message(paste('Running predictor plot for', i, sep = " "))
  
  plot_list[[i]] = plot_predictors(var = i)
}


plot <- plot_grid(plotlist = plot_list)

y.grob <- textGrob("Soil organic carbon density (g cm-3)", 
                   gp=gpar(col="black", fontsize=16), rot=90)

title <- textGrob("Relationship between predictors and model response for training data",
                  gp=gpar(col="black", fontsize=16))

#add to plot

final_grid <- grid.arrange(arrangeGrob(plot,  left = y.grob, top = title))

##### export #####

path_out = 'reports/05_figures/predictors/'
export_file <- paste(path_out, "trainDat_predictors.png", sep = '')
ggsave(export_file, final_grid, width = 15.36, height = 8.14)
