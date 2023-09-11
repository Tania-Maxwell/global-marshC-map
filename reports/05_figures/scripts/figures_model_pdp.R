#------------------------------------------------------#
# Partial dependency plots ####
#------------------------------------------------------#

rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(pdp) # partial() and autoplot()
library(cowplot)# plot_grid
library(ggpubr) 
library(grid) # textGrob
library(gridExtra) #grid.arrange
library(caret)


import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_ffs <- "reports/03_modelling/snakesteps/03_models/model_ffs.rds"

### import models and training data
final_model <- readRDS(import_model)
# ffsModel <- readRDS(import_ffs)

trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response) 

#### run partial dependency plot

partial_dependency <- function(mod, var){
  model_partial <- partial(mod, pred.var = var) 
  p <- autoplot(model_partial)
  return(p)
}


plot_list = list() 

for (i in names(trainDat_formod)){
  message(paste('Running partial dependency for', i, sep = " "))
  
  plot_list[[i]] = partial_dependency(mod = final_model, var = i)
}


# ## for forward feature selection model 
# for (i in ffsModel$selectedvars){
#   message(paste('Running partial dependency for', i, sep = " "))
#   
#   plot_list[[i]] = partial_dependency(mod = ffsModel, var = i)
# }


plot <- plot_grid(plotlist = plot_list)

#create common x and y labels

y.grob <- textGrob("Soil organic carbon density", 
                   gp=gpar(col="black", fontsize=16), rot=90)

x.grob <- textGrob("Predictor variable", 
                   gp=gpar(col="black", fontsize=16))

# title <- textGrob("Importance = \"permutation\" using ranger in caret::train()",
#                   gp=gpar(col="black", fontsize=16))

#add to plot

final_grid <- grid.arrange(arrangeGrob(plot, left = y.grob, bottom = x.grob))

##### export #####

path_out = 'reports/05_figures/predictors/'
export_file <- paste(path_out, "model_dependency_predictors.png", sep = '')
ggsave(export_file, final_grid, width = 15.36, height = 8.14)




