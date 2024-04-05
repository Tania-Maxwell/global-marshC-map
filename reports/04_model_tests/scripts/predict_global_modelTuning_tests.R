# model Tuning for the global model
# tuning the hyperparameter grid

rm(list=ls()) # clear the workspace
library(raster)
library(sf)
library(terra)
library(CAST) #AOA and CV strategy 
library(viridis) # color map
library(tidyverse)
library(caret)
library(geojsonsf) #geojson_sf
library(geojsonio)
library(fuzzyjoin) #join dfs with slighly different format of lat long


set.seed(7353)

import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_folds <- "reports/03_modelling/snakesteps/02_CV/folds.RDS"
import_folds_nndm <- "reports/03_modelling/snakesteps/02_CV/nndm_folds.RDS"
output_hyper_grid <- "reports/04_model_tests/model_tuning/tuning_hyper_grid.csv"
############## Import training data ####################

trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response) 

colnames(trainDat_formod)



############## Import folds ####################


folds <- readRDS(import_folds)

#' Fold to Index
#' @description Creates index and indexOut for caret::trainControl from a fold vector
#'
#' @param folds vector with fold labels
#'
#' @return list, with index and indexOut
#'
#' @import purrr
#' @import dplyr
#'
#' @export
#'
#' @author Marvin Ludwig
#'
#'
#'

fold2index = function(fold){
  
  fold = data.frame(fold = fold)
  
  indOut = fold %>% dplyr::group_by(fold) %>%
    attr('groups') %>% dplyr::pull(.rows)
  
  ind = purrr::map(seq(length(indOut)), function(x){
    s = seq(nrow(fold))
    s = s[!s %in% indOut[[x]]]
    return(s)
  })
  return(
    list(
      index = ind,
      indexOut = indOut
    )
  )
  
}

nndm_folds <- readRDS(import_folds_nndm)
i_nndm = fold2index(nndm_folds)



############## Set model hyperparameters ####################

hyperparameter <- expand.grid(mtry = 3,
                              splitrule = "variance",
                              min.node.size = 5)
tgrid <- expand.grid(
  .mtry = 2:4,
  .splitrule = "variance",
  .min.node.size = c(10, 20)
)

treatment.code = "k_nndm_5"
treatment.desc = "k-NNDM CV with 5 folds"
n_covariates = ncol(trainDat_formod)

hyper_grid <- expand.grid(
  mtry = floor(c (2,3, 4, 5)),
  min.node.size = c(1, 2, 3, 5, 10), 
  # sample.fraction = c(.5, .63, .8), #bag fraction
  ntree = c(100,200,300,400,500),
  rmse = NA,
  Rsquared = NA,
  treatment.code = treatment.code,
  treatment.desc = treatment.desc,
  mtry.default = sqrt(n_covariates),
  nSim = NA
)
nrow(hyper_grid) # 100


for(i in seq_len(nrow(hyper_grid))) {
  # fit model for ith hyperparameter combination
  message(paste('Running caret ranger random forest...', i, 'of', nrow(hyper_grid)))
  
  fit <- caret::train(x = trainDat_formod,
               y = trainDat$response,
               method="ranger",
               num.trees = hyper_grid$ntree[i],
               tuneGrid = expand.grid(mtry = hyper_grid$mtry[i],
                                      splitrule = "variance",
                                      min.node.size = hyper_grid$min.node.size[i]),
               trControl = trainControl(method = "cv", number = length(unique(nndm_folds)),
                                        index = i_nndm$index, indexOut = i_nndm$indexOut,
                                        savePredictions = "final"),
               importance = "permutation")
  
  
  # export error stats
  hyper_grid$nSim[i] <- i
  hyper_grid$rmse[i] <- fit$results$RMSE
  hyper_grid$Rsquared[i] <- fit$results$Rsquared
  rm(fit)
}


hyper_grid_final <- hyper_grid %>% 
  mutate(oobErrorRate = (rmse^2)*100)

min.rmse <- min(hyper_grid_final$rmse)
min.oob <- min(hyper_grid_final$oobErrorRate)

# assess top 10 models
hyper.results <- hyper_grid_final %>%
  mutate(perc_gain_oob =  (min.oob - oobErrorRate)*100,
         perc_gain_rmse = (min.rmse - rmse)*100) %>% 
  arrange(rmse) 
hyper.results

# write to file

write.csv(hyper.results, output_hyper_grid)

