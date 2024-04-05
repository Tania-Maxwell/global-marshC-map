varImp <- readRDS("reports/05_figures/scripts/varImp_scaled.rds")
varImp

imp <- as.data.frame(varImp$importance)
imp$variable <- rownames(imp)
imp$Overall <- as.numeric(imp$Overall)

imp_final <- imp %>% 
  mutate(variable = fct_recode(variable, 
                               "Soil depth" =  "Depth_midpoint_m",
                               "NDVI median" = "ndvi_med",
                               "NDVI stdev" = "ndvi_stdev",
                               "Tidal amplitude" = "M2Tide", 
                               "PET driest quarter" = "PETdry", 
                               "Total suspended matter" = "TSM",
                               "Max. monthly temperature" = "maxTemp",
                               "Min. monthly temperature" = "minTemp",
                               "Max. monthly precipitation" = "maxPrecip",
                               "Min. monthly precipitation" = "minPrecip",
                               "Elevation" = "copernicus_elevation",
                               "Slope" = "copernicus_slope",
                               "Sea-level rise zone" = "SLR_zone",
                               "Ecological coastal unit" = "ECU"))


imp_plot <- ggplot(imp_final, aes(x=reorder(variable, Overall), y=Overall)) + 
  geom_point() +
  geom_segment(aes(x=variable,xend=variable,y=0,yend=Overall)) +
  ylab("Relative variable importance") +
  xlab("") +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 1.5)+
  theme_bw()+
  coord_flip() + 
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))

imp_plot

ggsave("reports/05_figures/paper_figures/Figure 4.png", imp_plot, 
       width = 5.48, height = 4.50)
