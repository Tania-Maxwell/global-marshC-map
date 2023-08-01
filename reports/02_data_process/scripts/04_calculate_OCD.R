### explore data
# 11.11.22

rm(list=ls()) # clear the workspace
library(openair)
library(tidyverse)


input_file01 <- "reports/02_data_process/data/data_clean_BDconv.csv"

data0 <- read.csv(input_file01)

str(data0)

data1 <- data0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = (L_depth_m - U_depth_m)/2,
         Depth_thickness_m = L_depth_m - U_depth_m) %>%
  filter(is.na(Depth_midpoint_m) == FALSE) %>% 
  ##converting SOM to OC just for test (this will be done beforehand for final data)
  mutate(SOCD_g_cm3 = BD_g_cm3_final*OC_perc_final/100,
         SOCS_g_cm2 = SOCD_g_cm3 * 100 *Depth_thickness_m,
         # 100,000,000 cm2 in 1 ha and 1,000,000 g per tonne
         SOCS_t_ha = SOCS_g_cm2 * (100000000)/1000000) %>% 
  filter(is.na(SOCD_g_cm3) == FALSE)


##### Export 

data_final <- data1 

path_out = 'reports/02_data_process/data/'

file_name <- "data_clean_SOCD.csv"
export_file <- paste(path_out, file_name, sep = '')

write.csv(data_final, export_file, row.names = F)



#### 0. Data stats #### 

data_unique <- data0 %>% 
  distinct(Latitude, .keep_all = TRUE)

table(data_unique$Country)

data_unique_over30 <- data0 %>% 
  filter(U_depth_m > 0.3) %>% 
  distinct(Latitude, .keep_all = TRUE)

table(data_unique_over30$Country)

########### FOR VISUALIZATIONS #############

### 1. calculate OCD and OCS ####

## add horizon info
marshC1 <- data0 %>% 
  mutate(Horizon_thick_m = L_depth_m - U_depth_m) %>% 
  mutate(Horizon_mid_depth_m = U_depth_m + (L_depth_m-U_depth_m)/2) %>% 
  mutate(Horizon_bin_m = as.factor(case_when(L_depth_m <= 0.1 ~ 0.1,
                                   L_depth_m > 0.1 & L_depth_m <= 0.2 ~ 0.2,
                                   L_depth_m > 0.2 & L_depth_m <= 0.3 ~ 0.3,
                                   L_depth_m > 0.3 & L_depth_m <= 0.4 ~ 0.4,
                                   L_depth_m > 0.4 & L_depth_m <= 0.5 ~ 0.5,
                                   L_depth_m > 0.5 & L_depth_m <= 0.6 ~ 0.6,
                                   L_depth_m > 0.6 & L_depth_m <= 0.7 ~ 0.7,
                                   L_depth_m > 0.7 & L_depth_m <= 0.8 ~ 0.8,
                                   L_depth_m > 0.8 & L_depth_m <= 0.9 ~ 0.9,
                                   L_depth_m > 0.9 & L_depth_m <= 1 ~ 1,
                                   L_depth_m > 1 ~ NaN))) %>% 
  #calculate stocks
  mutate(OCD_g_cm3 = BD_g_cm3_final * (OC_perc_final/100),
         OCD_kg_m3 = OCD_g_cm3*1000,
         OCS_kg_m2 = OCD_kg_m3*Horizon_thick_m) %>% 
  relocate(Horizon_thick_m,Horizon_mid_depth_m, Horizon_bin_m,
           OCD_g_cm3,OCD_kg_m3,OCS_kg_m2, .after = L_depth_m)  


#### 2. Distribution of Values ####

#log Depth vs log OC perc per data type
logDepth_logOC <- openair::scatterPlot(marshC1, x = "Horizon_mid_depth_m", y = "OC_perc_final", 
                     method = "hexbin", col = "increment", type = "Data_type",
                     log.x = TRUE, log.y = TRUE, xlab="Depth [m]", ylab="OC [%]")
logDepth_logOC

#log OC vs log BS per data type
logOC_logBD <- openair::scatterPlot(marshC1, x = "OC_perc_combined", y = "BD_g_cm3_final", 
                     method = "hexbin", col = "increment", type = "Data_type",
                     log.x = TRUE, log.y = TRUE, xlab="OC [%]", ylab="BD [g cm-3]")
logOC_logBD

#regular
OC_BD <-openair::scatterPlot(marshC1, x = "OC_perc_combined", y = "BD_g_cm3_final", 
                     method = "hexbin", col = "increment", type = "Data_type",
                     log.x = F, log.y = F, xlab="OC [%]", ylab="BD [g cm-3]")
OC_BD


#### export figure

## change here
# export_fig <- OC_BD
# fig_main_name <- "OC_BD"
# 
# 
# path_out = 'reports/04_data_process/figures/'
# fig_name <- paste(Sys.Date(),fig_main_name, sep = "_")
# export_file <- paste(path_out, fig_name, ".png", sep = '') 
# png(filename = export_file, width = 537, height = 622)
# export_fig
# dev.off()
# 



#### 2. OCS vs depth ####

p <- ggplot(data= marshC1, aes(x=Horizon_bin_m, y = OCS_kg_m2))+
  geom_boxplot() +
  coord_flip()+
  ylim(c(0,6))
p

##### 3. test: model OCD from OC percent  ########


#log OC percent vs log OC density 
openair::scatterPlot(marshC1, x = "OC_perc_final", y = "OCD_kg_m3", 
                     method = "hexbin", col = "increment", type = "Data_type",
                     log.x = TRUE, log.y = TRUE, xlab="OC [%]", ylab="OC [kg m-3]")



## add variables for pedo-transfer function

marshC1$log.oc <- log(marshC1$OC_perc_combined + .Machine$double.eps)
marshC1$log.oc2 <- (marshC1$log.oc)^2

# add .Machine$double.eps to add small value to 0 values
model_oc_ocd <- glm(I(OCD_kg_m3 + .Machine$double.eps)~log.oc + log.oc2 + 
                      Horizon_mid_depth_m, data = marshC1,
                    family = gaussian(link = "log"))

summary(model_oc_ocd)

with(summary(model_oc_ocd), 1 - deviance/null.deviance)
#remove artifacts in points ?!

marshC_reduced <-  marshC1 %>% 
  filter(log.oc > 0.5 & log.oc < 5)



#### 2. SOC density from content #####

rms.df$log.oc2 = rms.df$log.oc^2
df.oc_d = rms.df[sel.oc,c("oc_d", "log.oc", "log.oc2", "hzn_depth")]
## remove some artifacts in points:
df.oc_d = df.oc_d[!(df.oc_d$log.oc<0.5 & df.oc_d$oc_d>5),]
m.oc_d = glm(I(oc_d+.Machine$double.eps)~log.oc+log.oc2+hzn_depth, 
             df.oc_d, family = gaussian(link="log"))
summary(m.oc_d)





test <- marshC1 %>% 
  filter(BD_g_cm3_final>2)
