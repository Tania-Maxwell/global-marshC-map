# script to determine the mixing model function to calculate BD from SOM
# T. Maxwell taniamaxwell7@gmail.com
# 14.07.23 


rm(list=ls()) # clear the workspace
library(tidyverse)
library(nimble) #for the nls function
library(propagate) #to predic nls
library(nlstools) # to bootstrap nls

##### 1. DATA IMPORT #####


#import compiled data
input_file01 <- "reports/02_data_process/data/data_clean_SOMconv_uniqueSiteName.csv"

# import 
data0<- read.csv(input_file01) 

data1 <- data0 %>% 
  #remove data with no OC_final data
  filter(is.na(OC_perc_final) == FALSE)

#### 2. Calculating k1 and k2 Mixing Model ####
# k1 and k2 values start from Morris et al 2016
#https://agupubs.onlinelibrary.wiley.com/doi/10.1002/2015EF000334
# BD = 1/[LOI/k1 + (1-LOI)/k2]

###### 2.1 Using measured SOM only #####

##### subset data 
studies_BD_reported_SOM <- data1 %>% 
  filter(is.na(BD_reported_combined) == FALSE) %>% 
  filter(Method == "LOI") %>% 
  #only include SOM measured
  filter(is.na(SOM_perc_combined) == FALSE) %>% 
  mutate(SOM_fraction = SOM_perc_combined/100)


SOM_to_BD <- function(x, k1, k2) {
  1/((x/k1) + ((1-x)/k2))
}

## use the start values for the model from holmquist paper
model_SOM_to_BD <- nls(BD_reported_combined ~ SOM_to_BD(x = SOM_fraction, k1,k2), 
                       data=studies_BD_reported_SOM, 
                       start=list(k1 = 0.098 , k2 = 1.67))
summary(model_SOM_to_BD)


## using bootstrapping 

model_nls_boot <- nlsBoot(model_SOM_to_BD, niter = 1000)
model_nls_boot$estiboot


## extract the coefficient values from the model summary
k1_est <- summary(model_SOM_to_BD)[['coefficients']][[1]]
k2_est <- summary(model_SOM_to_BD)[['coefficients']][[2]]

k1_stderr <- model_nls_boot$estiboot[1,2]
k2_stderr <- model_nls_boot$estiboot[2,2]

###### 2.2 Also including estimated SOM from OC #####

##### subset data 

BD_SOM_df0 <- data1 %>% 
  filter(is.na(BD_reported_combined) == FALSE) %>% 
  filter(Method == "LOI" | Method == "EA") %>% 
  #create a column for the future subset: SOM measured vs. SOM that needs to be estimated from OC
  mutate(SOM_origin = case_when(is.na(SOM_perc_combined) == FALSE ~ "Measured",
                                is.na(SOM_perc_combined) == TRUE & is.na(OC_perc_final) == FALSE ~ "Estimated from OC",
                                TRUE ~ "Other")) 

#subsetting for rows with no SOM measured but OC measured
BD_SOM_df_estimated0 <- BD_SOM_df0 %>% 
  filter(SOM_origin == "Estimated from OC")

#estimating SOM from OC using the polyroot of the equation (data paper)
# OC = 0.000683 * (SOM^2) + 0.410 * SOM
solve_poly <- function(y){
  coeff <- c(0-y,0.410,0.000683) # coefficients from equation
  solution1 <- polyroot(coeff)[1] # calculate polyroot and extract first solution
  real1 <- Re(solution1) # keep only the real element
  round1 <- round(real1, 4) # round to 4 decimal places
  return(round1)
}

# apply the function to the OC_perc_final column in the subsetted dataset
# note: the function won't work if there are NA values in the column
BD_SOM_df_estimated <- BD_SOM_df_estimated0 %>% 
  mutate(SOM_estimated = as.numeric(lapply(OC_perc_final, solve_poly)))

# join the datasets to attach the estimated data to the original data with measured data
BD_SOM_df <- left_join(BD_SOM_df0, BD_SOM_df_estimated)

# create a final dataset with a column for the final SOM values (coming from both measured and esimated values)
studies_BD_SOM_convertedOC <- BD_SOM_df %>% 
  mutate(SOM_final = case_when(SOM_origin == "Measured" ~ SOM_perc_combined,
                               SOM_origin == "Estimated from OC"~ SOM_estimated
  )) %>% 
  mutate(SOM_fraction = SOM_final/100) # SOM fraction for the k1 and k2 calculation


#### evaluate nls model 

## use the start values for the model from holmquist paper
model_SOM_to_BD_withOC <- nls(BD_reported_combined ~ SOM_to_BD(SOM_fraction, k1,k2), 
                              data=studies_BD_SOM_convertedOC, 
                              start=list(k1 = 0.098 , k2 = 1.67))
summary(model_SOM_to_BD_withOC)


## using bootstrapping 

model_nls_boot_withOC <- nlsBoot(model_SOM_to_BD_withOC, niter = 1000)
model_nls_boot_withOC$estiboot

## extract the coefficient values from the model summary
k1_est_withOC <- summary(model_SOM_to_BD_withOC)[['coefficients']][[1]] #0.101
k2_est_withOC <- summary(model_SOM_to_BD_withOC)[['coefficients']][[2]] #1.49

k1_stderr_withOC <- model_nls_boot_withOC$estiboot[1,2]
k2_stderr_withOC <- model_nls_boot_withOC$estiboot[2,2]

#### 3 Run predictions for graph #####

###### 3.1 Our model using measured OC only #####
xBD2_SOM = seq(from = 0.001, to = 1, 
               length.out = 300)


fitted_values_SOM <- SOM_to_BD(xBD2_SOM, k1_est, k2_est)
df_fitted_SOM <- as.data.frame(cbind(xBD2_SOM, fitted_values_SOM))

###### 3.2 Our model using measured and estimated OC #####
fitted_values_SOM_withOC <- SOM_to_BD(xBD2_SOM, k1_est_withOC, k2_est_withOC)
df_fitted_SOM_withOC <- as.data.frame(cbind(xBD2_SOM, fitted_values_SOM_withOC))

###### 3.3 Run predictions from Morris and Holmquist papers #####
fitted_values_Morris <- SOM_to_BD(xBD2_SOM, k1 = 0.085 , k2 = 1.99)
df_fitted_Morris <- as.data.frame(cbind(xBD2_SOM, fitted_values_Morris))

fitted_values_Holmquist <- SOM_to_BD(xBD2_SOM, k1 = 0.098 , k2 = 1.67)
df_fitted_Holmquist <- as.data.frame(cbind(xBD2_SOM, fitted_values_Holmquist))


##### 4. Final graph #####
SOM_to_BD_graph <- ggplot(studies_BD_SOM_convertedOC, aes(x = SOM_fraction, y = BD_reported_combined))+
  geom_point(aes(shape = SOM_origin), alpha = 0.1, col = "black")+
  scale_shape_manual(values = c("Measured" = 16, "Estimated from OC" = 17))+
  theme_bw()+
  labs(x = "Soil organic matter (fraction)", y = "Bulk Density (g cm-3)")+
  #add our model line and text
  geom_line(data = df_fitted_SOM, aes(x = xBD2_SOM, y =fitted_values_SOM), col = "yellow", size = 2, linetype = 2)+
  annotate(geom = "text",  label = paste("yellow dashed BD = 1 / (( SOM /", round(k1_est,3),  
                                         ") + (( 1 - SOM ) / ", round(k2_est,3),
                                         ")) est. from measured SOM only"),
           
           y = 2.4, x = 0.6)+
  
  #add our model line and text (SOM measured and derived from OC)
  geom_line(data = df_fitted_SOM_withOC, aes(x = xBD2_SOM, y =fitted_values_SOM_withOC), col = "yellow", size = 2, linetype = 1)+
  annotate(geom = "text",  label = paste("yellow solid BD = 1 / (( SOM /", round(k1_est_withOC,3),  
                                         ") + (( 1 - SOM ) / ", round(k2_est_withOC,3),
                                         ")) est. from SOM with estimates from OC"),
           
           y = 2.25, x = 0.6)+
  
  #add Morris model k1 and k2 line and text
  geom_line(data = df_fitted_Morris, aes(x = xBD2_SOM, y =fitted_values_Morris), col = "purple", size = 2)+
  annotate(geom = "text",  label = paste("purple MixingMod BD = 1 / (( SOM / 0.085) + (( 1 - SOM ) / 1.99)) from Morris et al. 2016"),
           
           y = 2.1, x = 0.6)+
  
  #add Holmquist model k1 and k2 line and text
  geom_line(data = df_fitted_Holmquist, aes(x = xBD2_SOM, y =fitted_values_Holmquist), col = "purple", size = 2, linetype = 2)+
  annotate(geom = "text",  label = paste("purple dashed BD = 1 / (( SOM / 0.098) + (( 1 - SOM ) / 1.67)) from Holmquist et al. 2018"),
           
           y = 1.95, x = 0.6)

#SOM_to_BD_graph

##### 5. Apply model to data #####
# BD = 1/[LOI/k1 + (1-LOI)/k2]
k1_est_withOC # k1 = 0.101
k2_est_withOC # k2 = 1.487

### join the dataset with the estimated BD to the main dataset
# coalesce the SOM perc measured and SOM estimated from OC (from the BD_SOM_df)
data2 <- left_join(data1, BD_SOM_df) %>% 
  mutate(SOM_coalesce = coalesce(SOM_perc_combined, SOM_estimated),
         SOM_coalesce_fraction = SOM_coalesce/100)

### apply the function to estimate BD from SOM 
data2$BD_estimated <- SOM_to_BD(x = data2$SOM_coalesce_fraction, k1 = k1_est_withOC, k2 = k2_est_withOC)

### coalesce the BD measured and BD estimated 
data3 <- data2 %>% 
  mutate(BD_g_cm3_final = coalesce(BD_reported_combined, BD_estimated)) %>% 
  mutate(BD_origin = case_when(is.na(BD_reported_combined)== FALSE ~ "Measured",
                               TRUE ~ "Estimated from SOM"))
table(data3$BD_origin)
# Estimated from SOM           Measured 
# 4402                          40765 



##### 6. Visualize final BD ####

summary(data3$BD_g_cm3_final)

p <- data3 %>% 
  ggplot(aes(x = OC_perc_final, y = BD_g_cm3_final))+
  geom_point()+
  theme_bw()+
  labs(x = "OC (%)",
       y = "BD (g cm-3)")
p


##### 7. Export #####

data_final <- data3 %>% 
  dplyr::select(-c("SOM_estimated", "BD_estimated", "SOM_coalesce_fraction"))

path_out = 'reports/02_data_process/data/'

file_name <- "data_clean_BDconv.csv"
export_file <- paste(path_out, file_name, sep = '')

write.csv(data_final, export_file, row.names = F)
