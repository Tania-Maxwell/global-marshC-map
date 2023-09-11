#------------------------------------------------------#
# varImp with backwards feature selection ####
#------------------------------------------------------#


rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(caret)
library(ranger)
library(CAST)

import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_folds_nndm <- "reports/03_modelling/snakesteps/02_CV/nndm_folds.RDS"
source("reports/03_modelling/scripts/fold2index.R")

trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response) 

colnames(trainDat_formod)

hyperparameter <- expand.grid(mtry = 3,
                              splitrule = "variance",
                              min.node.size = 5)

############ checking how model runs compares ##########
nndm_folds <- readRDS(import_folds_nndm)
i_nndm = fold2index(nndm_folds)

mod <- rfe(x = trainDat_formod,
           y = trainDat$response, sizes = 4,
           rfeControl = rfeControl(functions = caretFuncs, 
                                   method = "boot",
                                   number = 10),
           ## pass options to train(), 
           tuneGrid = hyperparameter,
           method = "ranger",
           trControl = trainControl(method = "cv", number = length(unique(nndm_folds)),
                                    index = i_nndm$index, indexOut = i_nndm$indexOut,
                                    savePredictions = "final"),
           importance = "permutation")


order_list <- mod$variables %>% 
  filter(Variables == max(mod$variables$Variables)) %>% 
  filter(Resample == "Resample01") 

mod_importance <- mod$variables %>% 
  filter(Variables == 14) %>% 
  group_by(Resample) %>% 
  mutate(var = factor(var, levels = order_list$var, ordered = T)) %>% 
  ungroup()


p <- ggplot(data = mod_importance, aes(x = var, y = Overall, group = Resample)) +
  geom_point()+
  scale_x_discrete(limits = rev)+
  coord_flip()+
  theme_bw()
p


##### export #####

path_out = 'reports/05_figures/predictors/'
export_file <- paste(path_out, "varImp_rfe_10.png", sep = '')
ggsave(export_file, p, width = 7.40, height = 5.91)

