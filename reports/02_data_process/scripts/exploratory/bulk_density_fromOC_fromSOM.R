## script to estimate Bulk density from Organic carbon
## using double inverse exponential function
## global marsh soil C project
# contact Tania Maxwell, tlgm2@cam.ac.uk
# 25.10.22

rm(list=ls()) # clear the workspace
library(tidyverse)
library(mosaic)
library(nimble) #for the nls function
library(propagate) #to predic nls
library(nlstools) # to bootstrap nls


#import compiled data
input_file01 <- "reports/02_data_process/data/2023-07-31_data_clean_SOMconv_uniqueSiteName.csv"

# import 
data0<- read.csv(input_file01) 

data1 <- data0 %>% 
  #remove data with no OC_final data
  filter(is.na(OC_perc_final) == FALSE)

data_OC_details <-data1 %>% 
  mutate(Source = case_when(Source == "CCRCN" ~ "CCRCN",
                           TRUE ~ "Global dataset")) %>% 
  group_by(Source, OC_obs_est) %>% 
  count()
table(data1$OC_obs_est)

table(data_OC_details$Source)
#### 1. explore data ####

##### a. studies with  BD reported #####
studies_BD_reported <- data1 %>% 
  filter(is.na(BD_reported_combined) == FALSE)

## percent
nrow(studies_BD_reported)/nrow(data1)*100
##~90% have BD reported! 

##number of studies without BD reported
nmissing_BD <- (nrow(data1))-(nrow(studies_BD_reported))
nmissing_BD

###### a1. BD reported and OC (original) ######

studies_BD_reported_OC <- studies_BD_reported %>% 
  filter(Method != "LOI") %>% 
  #only include OC measured (not estimated)
  filter(is.na(OC_perc_combined) == FALSE) %>% 
  mutate(SOM_fraction = SOM_perc_combined/100)

##number of values = 17065
nrow(studies_BD_reported_OC)

#42% of data has BD reported and OC
nrow(studies_BD_reported_OC)/nrow(data1)*100

yesBD_yesOC <- studies_BD_reported_OC %>% 
  ggplot(aes(x = OC_perc_combined, y = BD_reported_combined))+
  geom_point()+
  theme_bw()+
  labs(x = "OC (%)",
       y = "BD (g cm-3)")
yesBD_yesOC

###### a2. BD reported and SOM ######

studies_BD_reported_SOM <- studies_BD_reported %>% 
  filter(Method == "LOI") %>% 
  #only include SOM measured
  filter(is.na(SOM_perc_combined) == FALSE) %>% 
  mutate(SOM_fraction = SOM_perc_combined/100)

yesBD_yesSOM <- studies_BD_reported_SOM %>% 
  ggplot(aes(x = SOM_fraction, y = BD_reported_combined))+
  geom_point(aes(color = Original_source))+
  theme_bw()+
  labs(x = "SOM (fraction)",
       y = "BD (g cm-3)")
yesBD_yesSOM



##### b. studies no BD yes OC ####

studies_noBD_yesOC <- data1 %>% 
  filter(is.na(BD_reported_g_cm3) == TRUE &
           is.na(OC_perc_combined) == FALSE)

## number of studies
nrow(studies_noBD_yesOC)

## left to account for: 
nmissing_BD - (nrow(studies_noBD_yesOC))


##### c. studies no BD yes SOM #####

studies_noBD_yesSOM <- data1 %>% 
  filter(is.na(BD_reported_g_cm3) == TRUE &
           is.na(OC_perc_combined) == TRUE &
           is.na(SOM_perc_combined) == FALSE)

## number of studies
nrow(studies_noBD_yesSOM)

## left to account for: 
nmissing_BD - (nrow(studies_noBD_yesSOM)) - (nrow(studies_noBD_yesOC))


##### d. studies no BD yes OC yes SOM #####

studies_noBD_yesSOM_yesOC <- data1 %>% 
  filter(is.na(BD_reported_g_cm3) == TRUE &
           is.na(OC_perc_combined) == FALSE &
           is.na(SOM_perc_combined) == FALSE)

## number of studies
nrow(studies_noBD_yesSOM_yesOC)
# 384

#### 2. Full  model from elemental analysis OC data ####

#model structure based on Sanderman et al. 2018 Scientific Reports

OC_to_BD <- function(x, a, b, c , d, f) {
  a + (b*exp(-c*x)) + (d*exp(-f*x))
}

start_vec <- c(a=0.0906, b=0.8757, c=0.0786, d=0.6528, f =1.0975)

## use the start values for the model from sanderman paper
model_OC_to_BD <- nls(BD_reported_combined ~ OC_to_BD(OC_perc_combined, a, b, c, d, f), 
              data=studies_BD_reported_OC, 
              start= start_vec)

summary(model_OC_to_BD)

## extract the coefficient values from the model summary
a_est <- summary(model_OC_to_BD)[['coefficients']][[1]]
b_est <- summary(model_OC_to_BD)[['coefficients']][[2]]
c_est <- summary(model_OC_to_BD)[['coefficients']][[3]]
d_est <- summary(model_OC_to_BD)[['coefficients']][[4]]
f_est <- summary(model_OC_to_BD)[['coefficients']][[5]]

## calculated the predicted values at the random x values with the coefficient 
#and full function

xBD2 = seq(from = 0.001, to = 50, 
          length.out = 100)


fitted_values <- OC_to_BD(xBD2, a_est, b_est, c_est, d_est, f_est)

df_fitted <- as.data.frame(cbind(xBD2, fitted_values))


plot(residuals(model_OC_to_BD))


#http://127.0.0.1:20501/graphics/plot_zoom_png?width=1536&height=814
##### graphs #####
OC_to_BD_graph <- ggplot(studies_BD_reported_OC, aes(x = OC_perc_combined, y = BD_reported_combined))+
  geom_point(aes(color = Original_source))+
  theme_bw()+
  labs(x = "Organic carbon (%)", y = "Bulk Density (g cm-3)")+
  geom_line(data = df_fitted, aes(x = xBD2, y =fitted_values), col = "blue", size = 1)+
  #annotate("text", x=60, y=4, label= "0.065 + (0.59*exp(-0.056*OC)) + (0.77*exp(-0.58*OC))", color="blue")
  # annotate(geom = "text",  label = paste("BD =", round(a_est,3), "±", round(a_std,3), 
  #                                      "+", round(b_est,3), "±", round(b_std,3),
  #                                      "exp(", round((c_est*-1),3), "±", round(c_std,3)),
  #                                       "*OC) +", round(d_est,3), "±", round(d_std,3),
  #                                       "exp(", round((f_est*-1),3), "±", round(f_std,3),
  #          
  #        y = 50, x = 30)
  annotate(geom = "text",  label = paste("BD =", round(a_est,3),  
                                         "+", round(b_est,3),
                                         "exp(", round((c_est*-1),3), 
           "*OC ) +", round(d_est,3), 
           "exp( ", round((f_est*-1),3), "*OC )"),
           
           y = 3, x = 30)

OC_to_BD_graph

# random effect? 
library(lme4)
model_randomeffect <- lmer(BD_reported_combined ~ exp(OC_perc_combined) 
                           + (1|Original_source), 
                           data = studies_BD_reported_OC)

test <- lmer(BD_reported_combined ~ OC_to_BD(OC_perc_combined)
             + (1|Original_source), 
             data = studies_BD_reported_OC)

## 3. Fit the same model with a user-built function:
## a. Define formula
nform <- ~(a + (b*exp(-c*x)) + (d*exp(-f*x)))
## b. Use deriv() to construct function:
nfun <- deriv(nform,namevec=c("a","b","c", "d", "f"),
              function.arg=c("x","a","b","c", "d", "f"))


test<- nlmer(BD_reported_combined ~ OC_to_BD(OC_perc_combined, a, b, c, d, f) 
             ~ a|Original_source, 
             data=studies_BD_reported_OC, 
             start=start_vec)


summary(model_randomeffect)
confint(model_randomeffect)

library(lmerTest)
anova(model_randomeffect)
model_OC_to_BD <- nls(BD_reported_combined ~ OC_to_BD(OC_perc_combined, a, b, c, d, f), 
data=studies_BD_reported_OC, 
start=list(a=0.0906, b=0.8757, c=0.0786, d=0.6528, f =1.0975))
summary(model_OC_to_BD)


##### predictions ####
# 
# predictions <- predictNLS(full_model, newdata = data.frame(OC_perc = xBD2),
#                       interval="pred")
# predictions$summary
# 
# plot(input_data_model$OC_perc, input_data_model$BD_reported_g_cm3)
# lines(xBD2, fitted_values, col="red")
# lines(xBD2, predictions$summary$`Sim.2.5%`, col="red", lty=2)
# lines(xBD2, predictions$summary$`Sim.97.5%`, col="red", lty=2)
# 
# 
# test <- input_data01 %>% 
#   filter(OC_perc > 40 & BD_reported_g_cm3 >1)
# 



#### 3. Full model from LOI SOM data ####

# k1 and k2 values start from Morris et al 2016
#https://agupubs.onlinelibrary.wiley.com/doi/10.1002/2015EF000334
# BD = 1/[LOI/k1 + (1-LOI)/k2]

SOM_to_BD <- function(x, k1, k2) {
  1/((x/k1) + ((1-x)/k2))
}

## use the start values for the model from sanderman paper
model_SOM_to_BD <- nls(BD_reported_combined ~ SOM_to_BD(SOM_fraction, k1,k2), 
                      data=studies_BD_reported_SOM, 
                      start=list(k1 = 0.085 , k2 = 1.99))
summary(model_SOM_to_BD)


## using bootstrapping 

model_nls_boot <- nlsBoot(model_SOM_to_BD, niter = 1000)
model_nls_boot$estiboot

# # note: this doesn't work
# library(lme4)
# model_randomeffect <- lmer(BD_reported_combined ~ SOM_to_BD(SOM_fraction, k1,k2), 
#                            #  1/((x/k1) + ((1-x)/k2))
#                            + (1|Original_source), 
#                            data = studies_BD_reported_SOM)
# 
# summary(model_randomeffect)


## extract the coefficient values from the model summary
k1_est <- summary(model_SOM_to_BD)[['coefficients']][[1]]
k2_est <- summary(model_SOM_to_BD)[['coefficients']][[2]]

k1_stderr <- model_nls_boot$estiboot[1,2]
k2_stderr <- model_nls_boot$estiboot[2,2]

xBD2_SOM = seq(from = 0.001, to = 1, 
           length.out = 300)


fitted_values_SOM <- SOM_to_BD(xBD2_SOM, k1_est, k2_est)
df_fitted_SOM <- as.data.frame(cbind(xBD2_SOM, fitted_values_SOM))


fitted_values_Morris <- SOM_to_BD(xBD2_SOM, k1 = 0.085 , k2 = 1.99)
df_fitted_Morris <- as.data.frame(cbind(xBD2_SOM, fitted_values_Morris))

fitted_values_Holmquist <- SOM_to_BD(xBD2_SOM, k1 = 0.098 , k2 = 1.67)
df_fitted_Holmquist <- as.data.frame(cbind(xBD2_SOM, fitted_values_Holmquist))

###### SOM to BD graph ####
SOM_to_BD_graph <- ggplot(studies_BD_reported_SOM, aes(x = SOM_fraction, y = BD_reported_combined))+
  geom_point(col = 'grey')+
  theme_bw()+
  labs(x = "Soil organic matter (fraction)", y = "Bulk Density (g cm-3)")+
  geom_line(data = df_fitted_SOM, aes(x = xBD2_SOM, y =fitted_values_SOM), col = "blue", size = 1, linetype = 3)+
  #annotate("text", x=60, y=4, label= "0.065 + (0.59*exp(-0.056*OC)) + (0.77*exp(-0.58*OC))", color="blue")
  # annotate(geom = "text",  label = paste("BD =", round(a_est,3), "±", round(a_std,3), 
  #                                      "+", round(b_est,3), "±", round(b_std,3),
  #                                      "exp(", round((c_est*-1),3), "±", round(c_std,3)),
  #                                       "*OC) +", round(d_est,3), "±", round(d_std,3),
  #                                       "exp(", round((f_est*-1),3), "±", round(f_std,3),
  #          
  #        y = 50, x = 30)
  annotate(geom = "text",  label = paste("blue dotted BD = 1 / (( SOM /", round(k1_est,3),  
                                         ") + (( 1 - SOM ) / ", round(k2_est,3),
                                         ")) estimated from our data"),
           
           y = 2.4, x = 0.6)+
  geom_line(data = df_fitted_Morris, aes(x = xBD2_SOM, y =fitted_values_Morris), col = "red", size = 1)+
  #annotate("text", x=60, y=4, label= "0.065 + (0.59*exp(-0.056*OC)) + (0.77*exp(-0.58*OC))", color="blue")
  # annotate(geom = "text",  label = paste("BD =", round(a_est,3), "±", round(a_std,3), 
  #                                      "+", round(b_est,3), "±", round(b_std,3),
  #                                      "exp(", round((c_est*-1),3), "±", round(c_std,3)),
  #                                       "*OC) +", round(d_est,3), "±", round(d_std,3),
  #                                       "exp(", round((f_est*-1),3), "±", round(f_std,3),
  #          
  #        y = 50, x = 30)
  annotate(geom = "text",  label = paste("red MixingMod BD = 1 / (( SOM / 0.085) + (( 1 - SOM ) / 1.99)) from Morris et al. 2016"),
           
           y = 2.2, x = 0.6)+
  geom_line(data = df_fitted_Holmquist, aes(x = xBD2_SOM, y =fitted_values_Holmquist), col = "red", size = 1, linetype = 2)+
  #annotate("text", x=60, y=4, label= "0.065 + (0.59*exp(-0.056*OC)) + (0.77*exp(-0.58*OC))", color="blue")
  # annotate(geom = "text",  label = paste("BD =", round(a_est,3), "±", round(a_std,3), 
  #                                      "+", round(b_est,3), "±", round(b_std,3),
  #                                      "exp(", round((c_est*-1),3), "±", round(c_std,3)),
  #                                       "*OC) +", round(d_est,3), "±", round(d_std,3),
  #                                       "exp(", round((f_est*-1),3), "±", round(f_std,3),
  #          
  #        y = 50, x = 30)
  annotate(geom = "text",  label = paste("red dashed BD = 1 / (( SOM / 0.098) + (( 1 - SOM ) / 1.67)) from Holmquist et al. 2018"),
           
           y = 2, x = 0.6)




SOM_to_BD_graph


#### 4. convert OC to SOM ####

BD_SOM_df0 <- data1 %>% 
  filter(is.na(BD_reported_combined) == FALSE) %>% 
  filter(Method == "LOI" | Method == "EA") %>% 
  mutate(SOM_origin = case_when(is.na(SOM_perc_combined) == FALSE ~ "Measured",
         is.na(SOM_perc_combined) == TRUE & is.na(OC_perc_final) == FALSE ~ "Estimated from OC",
         TRUE ~ "Other")) 

BD_SOM_df_estimated0 <- BD_SOM_df0 %>% 
  filter(SOM_origin == "Estimated from OC")

solve_poly <- function(y){
  coeff <- c(0-y,0.410,0.000683) # coefficients from SOM to OC equation " y = 0.000683 * (x^2) + 0.410 * x "
  solution1 <- polyroot(coeff)[1]
  real1 <- Re(solution1)
  round1 <- round(real1, 4)
  return(round1)
}

BD_SOM_df_estimated <- BD_SOM_df_estimated0 %>% 
  mutate(SOM_estimated = as.numeric(lapply(OC_perc_final, solve_poly)))

BD_SOM_df <- left_join(BD_SOM_df0, BD_SOM_df_estimated)
summary(BD_SOM_df$SOM_estimated)


studies_BD_SOM_convertedOC <- BD_SOM_df %>% 
  mutate(SOM_final = case_when(SOM_origin == "Measured" ~ SOM_perc_combined,
                               SOM_origin == "Estimated from OC"~ SOM_estimated
                               )) %>% 
  mutate(SOM_fraction = SOM_final/100)

hist(studies_BD_SOM_convertedOC$SOM_fraction)
##### evaluate nls model ####


## use the start values for the model from sanderman paper
model_SOM_to_BD_withOC <- nls(BD_reported_combined ~ SOM_to_BD(SOM_fraction, k1,k2), 
                       data=studies_BD_SOM_convertedOC, 
                       start=list(k1 = 0.085 , k2 = 1.99))
summary(model_SOM_to_BD_withOC)


## using bootstrapping 

model_nls_boot_withOC <- nlsBoot(model_SOM_to_BD_withOC, niter = 1000)
model_nls_boot_withOC$estiboot

## extract the coefficient values from the model summary
k1_est_withOC <- summary(model_SOM_to_BD_withOC)[['coefficients']][[1]] #0.101
k2_est_withOC <- summary(model_SOM_to_BD_withOC)[['coefficients']][[2]] #1.49

k1_stderr_withOC <- model_nls_boot_withOC$estiboot[1,2]
k2_stderr_withOC <- model_nls_boot_withOC$estiboot[2,2]



fitted_values_SOM_withOC <- SOM_to_BD(xBD2_SOM, k1_est_withOC, k2_est_withOC)
df_fitted_SOM_withOC <- as.data.frame(cbind(xBD2_SOM, fitted_values_SOM_withOC))



##### 5. final graph ####
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


SOM_to_BD_graph


#### observed data only
SOM_to_BD_graph_obs <- studies_BD_SOM_convertedOC %>% 
  filter(SOM_origin == "Measured") %>% 
  ggplot(aes(x = SOM_fraction, y = BD_reported_combined))+
  geom_point(shape = 16, alpha = 0.1, col = "black")+
  theme_bw()+
  labs(x = "Soil organic matter (fraction)", y = "Bulk Density (g cm-3)")+
  #add our model line and text
  geom_line(data = df_fitted_SOM, aes(x = xBD2_SOM, y =fitted_values_SOM), col = "yellow", size = 2, linetype = 2)+
  annotate(geom = "text",  label = paste("yellow dashed BD = 1 / (( SOM /", round(k1_est,3),  
                                         ") + (( 1 - SOM ) / ", round(k2_est,3),
                                         ")) est. from measured SOM only"),
           
           y = 2.4, x = 0.6)+
  
  # #add our model line and text (SOM measured and derived from OC)
  # geom_line(data = df_fitted_SOM_withOC, aes(x = xBD2_SOM, y =fitted_values_SOM_withOC), col = "yellow", size = 2, linetype = 1)+
  # annotate(geom = "text",  label = paste("yellow solid BD = 1 / (( SOM /", round(k1_est_withOC,3),  
  #                                        ") + (( 1 - SOM ) / ", round(k2_est_withOC,3),
  #                                        ")) est. from SOM with estimates from OC"),
  #          
  #          y = 2.25, x = 0.6)+
  
  #add Morris model k1 and k2 line and text
  geom_line(data = df_fitted_Morris, aes(x = xBD2_SOM, y =fitted_values_Morris), col = "purple", size = 2)+
  annotate(geom = "text",  label = paste("purple MixingMod BD = 1 / (( SOM / 0.085) + (( 1 - SOM ) / 1.99)) from Morris et al. 2016"),
           
           y = 2.1, x = 0.6)+
  
  #add Holmquist model k1 and k2 line and text
  geom_line(data = df_fitted_Holmquist, aes(x = xBD2_SOM, y =fitted_values_Holmquist), col = "purple", size = 2, linetype = 2)+
  annotate(geom = "text",  label = paste("purple dashed BD = 1 / (( SOM / 0.098) + (( 1 - SOM ) / 1.67)) from Holmquist et al. 2018"),
           
           y = 1.95, x = 0.6)

SOM_to_BD_graph_obs


#### 6. figure exports ####
export_fig <- SOM_to_BD_graph
fig_main_name <- "SOM_to_BD_graph_withEstimates"

path_out = 'reports/02_data_process/figures/SOM_to_BD/'
export_file <- paste(path_out, fig_main_name, ".png", sep = '') 
ggsave(export_file, export_fig, width = 10.35, height = 6.89)
#ggsave(export_file, export_fig, width = 8.84, height = 5.99)

