#------------------------------------------------------#
# 3. Train the model ####
#------------------------------------------------------#

rm(list=ls()) # clear the workspace
library(tidyverse)
library(sf)
library(caret)
library(ranger)

args <- commandArgs(trailingOnly=T)
import_data <- args[1]
import_folds <- args[2]
import_folds_nndm <- args[3]
varImp_random <- args[4]
varImp_spatial <- args[5]
varImp_nndm <- args[6]
output_random <- args[7]
output_spatial <- args[8]
output_nndm <- args[9]

# import_data <- "reports/03_modelling/snakesteps/01_trainDat/trainDat.gpkg"
# import_folds <- "reports/03_modelling/snakesteps/02_CV/folds.RDS"
# import_folds_nndm <- "reports/03_modelling/snakesteps/02_CV/nndm_folds.RDS"
# varImp_random <- "reports/03_modelling/snakesteps/03_models/model_random_varImp.png"
# varImp_spatial <- "reports/03_modelling/snakesteps/03_models/model_spatial_varImp.png"
# varImp_nndm <- "reports/03_modelling/snakesteps/03_models/model_nndm_varImp.png"
# output_random <- "reports/03_modelling/snakesteps/03_models/model_random.rds"
# output_spatial <- "reports/03_modelling/snakesteps/03_models/model_spatial.rds"
# output_nndm <- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"


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
tgrid <- expand.grid(
  .mtry = 2:4,
  .splitrule = "variance",
  .min.node.size = c(10, 20)
)

############## 3.2 Train random CV model ####################

model_random <- caret::train(trainDat_formod,
                      trainDat$response,
                      method="ranger",
                      ntree=300,
                      tuneGrid = hyperparameter,
                      trControl = trainControl(method="cv",savePredictions = TRUE),
                      importance = "impurity")
print(model_random)


# model_random <- caret::train(trainDat_formod,
#                       trainDat$response,
#                       method="rf",
#                       ntree=100,
#                       importance=TRUE,
#                       tuneGrid = data.frame("mtry"=2),
#                       trControl = trainControl(method="cv",savePredictions = TRUE))
# model_random  

variable_importance <- varImp(model_random)

plot_model_random <- plot(variable_importance)


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




############## 3.4 Train spatial CV model ####################

i = fold2index(folds)

# model_spatial <- caret::train(x = trainDat_formod,
#                        y = trainDat$response,
#                        method="rf",
#                        ntree=100,
#                        importance=TRUE,
#                        tuneGrid = data.frame("mtry"=2),
#                        trControl = trainControl(method = "cv", number = length(unique(folds)),
#                                                 index = i$index, indexOut = i$indexOut,
#                                                 savePredictions = "final"))


model_spatial <- caret::train(x = trainDat_formod,
                              y = trainDat$response,
                              method="ranger",
                              num.trees =300,
                              tuneGrid = hyperparameter, 
                              trControl = trainControl(method = "cv", number = length(unique(folds)),
                                                       index = i$index, indexOut = i$indexOut,
                                                       savePredictions = "final"),
                              importance = "impurity")
print(model_spatial)

#saveRDS(model_spatial, "reports/03_modelling/output/model_spatial_global.rds")

variable_importance <- varImp(model_spatial)
plot_model_spatial <- plot(variable_importance)


############## 3.4 Train NNDM CV model ####################
nndm_folds <- readRDS(import_folds_nndm)
i_nndm = fold2index(nndm_folds)

model_nndm <- caret::train(x = trainDat_formod,
                              y = trainDat$response,
                              method="ranger",
                              num.trees =300,
                              tuneGrid = hyperparameter, 
                              trControl = trainControl(method = "cv", number = length(unique(nndm_folds)),
                                                       index = i_nndm$index, indexOut = i_nndm$indexOut,
                                                       savePredictions = "final"),
                              importance = "impurity")
print(model_nndm)


variable_importance <- caret::varImp(model_nndm)
plot_model_nndm <- plot(variable_importance)

# pairs(trainDat_formod)
# trainDat_sub1 <- trainDat_formod %>% 
#   select(copernicus_elevation, copernicus_slope)
# 
# pairs(trainDat_sub1)
############## 3.5 export  ####################

#open an png with the right file name
png(filename = varImp_random,
    #res = 120,
    width = 580, height = 481)
plot(plot_model_random)
dev.off()

png(filename = varImp_spatial,
    #res = 120,
    width = 580, height = 481)
plot(plot_model_spatial)
dev.off()

png(filename = varImp_nndm,
    #res = 120,
    width = 580, height = 481)
plot(plot_model_nndm)
dev.off()


saveRDS(model_random, output_random)
saveRDS(model_spatial, output_spatial)
saveRDS(model_nndm, output_nndm)



