### explore data
# 11.11.22

#rm(list=ls()) # clear the workspace

library(tidyverse)

# arguments for snakemake
args <- commandArgs(trailingOnly=T)
import_data <- args[1]
export_file <- args[2]

# import_data <- "reports/02_data_process/snakesteps/03_bulk_density/data_clean_BDconv.csv"
# export_file <- 'reports/02_data_process/snakesteps/04_OCD/data_clean_SOCD.csv'


data0 <- read.csv(import_data)

data_final <- data0 %>% 
  ## creating a midpoint for each depth
  mutate(Depth_midpoint_m = U_depth_m + ((L_depth_m - U_depth_m)/2),
         Depth_thickness_m = L_depth_m - U_depth_m) %>%
  filter(is.na(Depth_midpoint_m) == FALSE) %>% 
  ##converting SOM to OC just for test (this will be done beforehand for final data)
  mutate(SOCD_g_cm3 = BD_g_cm3_final*OC_perc_final/100,
         SOCS_g_cm2 = SOCD_g_cm3 * 100 *Depth_thickness_m,
         # 100,000,000 cm2 in 1 ha and 1,000,000 g per tonne
         SOCS_t_ha = SOCS_g_cm2 * (100000000)/1000000) %>% 
  filter(is.na(SOCD_g_cm3) == FALSE)


##### Export 
write.csv(data_final, export_file, row.names = F)
