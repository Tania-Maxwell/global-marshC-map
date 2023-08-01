#------------------------------------------------------#
# 3. Train the model ####
#------------------------------------------------------#

rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(caret)

# args <- commandArgs(trailingOnly=T)
# import_data <- args[1]
# import_random <- args[2]
# import_spatial <- args[3]
# import_folds <- args[4]
# output_random <- args[5]
# output_spatial <- args[6]
# 
import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
import_random <- "reports/03_modelling/snakesteps/02_CV/random_cv.rds"
import_spatial <- "reports/03_modelling/snakesteps/02_CV/spatial_cv.rds"
import_folds <- "reports/03_modelling/snakesteps/02_CV/folds.RDS"
output_random <- "reports/03_modelling/snakesteps/03_models/model_random.rds"
output_spatial <- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"

set.seed(7353)
############## 3.1 Import training data ####################

trainDat <- st_read(import_data, quiet = TRUE) %>% 
  drop_na()

trainDat_formod <- trainDat %>% 
  as.data.frame() %>% 
  dplyr::select(-geom, -response) 

colnames(trainDat_formod)
############## 3.2 Set model hyperparameters ####################

hyperparameter <- expand.grid(mtry = 3,
                             splitrule = "variance",
                             min.node.size = 5)


############## 3.2 Train random CV model ####################

# 
# model_random <- caret::train(trainDat_formod,
#                       trainDat$response,
#                       method="ranger",
#                       ntree=100,
#                       importance=TRUE,
#                       tuneGrid = hyperparameter,
#                       trControl = trainControl(method="cv",savePredictions = TRUE))
# model_random

model_random <- caret::train(trainDat_formod,
                      trainDat$response,
                      method="rf",
                      ntree=100,
                      importance=TRUE,
                      tuneGrid = data.frame("mtry"=2),
                      trControl = trainControl(method="cv",savePredictions = TRUE))
model_random  


############## 3.3 Import folds for CV model ####################

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

i = fold2index(folds)


############## 3.4 Train spatial CV model ####################


model_spatial <- caret::train(x = trainDat_formod,
                       y = trainDat$response,
                       method="rf",
                       ntree=100,
                       importance=TRUE,
                       tuneGrid = data.frame("mtry"=2),
                       trControl = trainControl(method = "cv", number = length(unique(folds)),
                                                index = i$index, indexOut = i$indexOut,
                                                savePredictions = "final"))
#saveRDS(model_spatial, "reports/03_modelling/output/model_spatial_global.rds")

#model_spatial <- readRDS("reports/03_modelling/output/model_spatial_global.rds")

variable_importance <- varImp(model_spatial)

p <- plot(variable_importance)
p
############## 3.4 export  ####################

saveRDS(model_random, output_random)
# saveRDS(model_spatial, output_spatial)

# fake file
saveRDS(model_random, output_spatial)



