#------------------------------------------------------#
# 5. Train difference index for area of applicability (AOA) ####
#------------------------------------------------------#

#' from https://hannameyer.github.io/CAST/articles/cast03-AOA-parallel.html
#' For better performances, it is recommended to compute the AOA in two steps. 
#' First, the DI of training data and the resulting DI threshold is computed 
#' from the model or training data with the function trainDI. The result from 
#' trainDI is usually the first step of the aoa function, however it can be skipped 
#' by providing the trainDI object in the function call


#rm(list=ls()) # clear the workspace
library(tidyverse)
library(CAST)
library(caret)
set.seed(7353)


args <- commandArgs(trailingOnly=T)
import_model <- args[1]
output_DI <- args[2]
source("scripts/trainDI.R")

# source("reports/03_modelling/scripts/trainDI.R")
# import_model<- "reports/03_modelling/snakesteps/03_models/model_nndm.rds"
# output_DI <- "reports/03_modelling/snakesteps/05_DI/model_nndm_trainDI.rds"


############## 5.1 Import model ####################
final_model <- readRDS(import_model)

#final_model_trainDI <- CAST::trainDI(final_model)

model <- final_model
variables = "all"
method = "L2"


# trainDI <- function(model = NA,
#                     train = NULL,
#                     variables = "all",
#                     weight = NA,
#                     CVtest = NULL,
#                     CVtrain = NULL,
#                     method="L2",
#                     useWeight=TRUE)

# using script from the function instead of the actual function
  
  # get parameters if they are not provided in function call-----
train = aoa_get_train(model)
variables = aoa_get_variables(variables, model, train)
weight = aoa_get_weights(model, variables = variables)
  # get CV folds from model or from parameters
  folds <-  aoa_get_folds(model,CVtrain,CVtest)
  CVtest <- folds[[2]]
  CVtrain <- folds[[1]]
  
  # reduce train to specified variables
  train <- train[,na.omit(match(variables, names(train)))]
  
  train_backup <- train
  
  # convert categorial variables
  catupdate <- aoa_categorial_train(train, variables, weight)
  
  train <- catupdate$train
  weight <- catupdate$weight
  
  # scale train
  train <- scale(train)
  
# save scale param for later
  scaleparam <- attributes(train)
  
  
  # multiply train data with variable weights (from variable importance)
  if(!inherits(weight, "error")&!is.null(unlist(weight))){
    train <- sapply(1:ncol(train),function(x){train[,x]*unlist(weight[x])})
  }
  
  
  # calculate average mean distance between training data
  
  trainDist_avrg <- c()
  trainDist_min <- c()
  
  if(method=="MD"){
    if(dim(train)[2] == 1){
      S <- matrix(stats::var(train), 1, 1)
    } else {
      S <- stats::cov(train)
    }
    S_inv <- MASS::ginv(S)
  }
  
  for(i in seq(nrow(train))){
    
    # distance to all other training data (for average)
    trainDistAll   <- .alldistfun(t(train[i,]), train,  method, S_inv=S_inv)[-1]
    trainDist_avrg <- append(trainDist_avrg, mean(trainDistAll, na.rm = TRUE))
    
    # calculate  distance to other training data:
    trainDist      <- matrix(.alldistfun(t(matrix(train[i,])), train, method, sorted = FALSE, S_inv))
    trainDist[i]   <- NA
    
    
    # mask of any data that are not used for training for the respective data point (using CV)
    whichfold <- NA
    if(!is.null(CVtrain)&!is.null(CVtest)){
      whichfold <-  as.numeric(which(lapply(CVtest,function(x){any(x==i)})==TRUE)) # index of the fold where i is held back
      if(length(whichfold)!=0){ # in case that a data point is never used for testing
        trainDist[!seq(nrow(train))%in%CVtrain[[whichfold]]] <- NA # everything that is not in the training data for i is ignored
      }
      if(length(whichfold)==0){#in case that a data point is never used for testing, the distances for that point are ignored
        trainDist <- NA
      }
    }
    
    #######################################
    
    if (length(whichfold)==0){
      trainDist_min <- append(trainDist_min, NA)
    }else{
      trainDist_min <- append(trainDist_min, min(trainDist, na.rm = TRUE))
    }
  }
  trainDist_avrgmean <- mean(trainDist_avrg,na.rm=TRUE)
  
  
  
  # Dissimilarity Index of training data -----
  TrainDI <- trainDist_min/trainDist_avrgmean
  
  
  # AOA Threshold ----
  threshold_quantile <- stats::quantile(TrainDI, 0.75,na.rm=TRUE)
  threshold_iqr <- (1.5 * stats::IQR(TrainDI,na.rm=T))
  thres <- threshold_quantile + threshold_iqr
  
  # note: previous versions of CAST derived the threshold this way:
  #thres <- grDevices::boxplot.stats(TrainDI)$stats[5]
  
  
  # Return: trainDI Object -------
  
  aoa_results = list(
    train = train_backup,
    weight = weight,
    variables = variables,
    catvars = catupdate$catvars,
    scaleparam = scaleparam,
    trainDist_avrg = trainDist_avrg,
    trainDist_avrgmean = trainDist_avrgmean,
    trainDI = TrainDI,
    threshold = thres,
    method = method
  )
  
  class(aoa_results) = "trainDI"
  
  # done ----



############## 5.2 Export DI ####################
#saveRDS(final_model_trainDI, output_DI)
saveRDS(aoa_results, output_DI)
  
