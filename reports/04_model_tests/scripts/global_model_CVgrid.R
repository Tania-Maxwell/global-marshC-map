#### testing the grid size effect on model performance ####


rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(caret)
library(ranger)

import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_folds <- list.files(path = "reports/04_model_tests/02_CV", pattern = "\\.RDS", full.names =TRUE)


for (i in 1:length(import_folds)){
  fold_name0 <- str_extract(import_folds[i], 'folds.*')
  fold_name <- gsub('\\..*', "", fold_name0)
  assign(fold_name, readRDS(import_folds[i]))
}
folds0 <- `folds0-5`

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

# we will do model tuning once the grid is finalized
hyperparameter <- expand.grid(mtry = 3,
                              splitrule = "variance",
                              min.node.size = 5)

trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response) 


train_model_folds <- function(folds, foldsID){
  i = fold2index(folds)
  
  model_spatial <- caret::train(x = trainDat_formod,
                                y = trainDat$response,
                                method="ranger",
                                num.trees =300,
                                tuneGrid = hyperparameter, 
                                trControl = trainControl(method = "cv", number = length(unique(folds)),
                                                         index = i$index, indexOut = i$indexOut,
                                                         savePredictions = "final"),
                                importance = "impurity")
  
  saveRDS(model_spatial, paste0("reports/04_model_tests/models_CV/",  foldsID, ".RDS"))
  return(model_spatial)
}


train_model_folds(folds = `folds0-5`, foldsID = "model_CV_folds0-5")
train_model_folds(folds = folds1, foldsID = "model_CV_folds1")
train_model_folds(folds = folds3, foldsID = "model_CV_folds3")
train_model_folds(folds = folds6, foldsID = "model_CV_folds6")
train_model_folds(folds = folds9, foldsID = "model_CV_folds9")

`model_CV_folds0-5`
model_CV_folds1
model_CV_folds3
model_CV_folds6
model_CV_folds9
