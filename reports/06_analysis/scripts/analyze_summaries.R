library(tidyverse)
library(ggrepel)
library(cowplot)
Realm_Stats_0_30 <- read_csv("reports/06_analysis/summaries/Realm_Stats_0_30.csv")
Realm_Stats_30_100 <- read_csv("reports/06_analysis/summaries/Realm_Stats_30_100.csv")

Country_Stats_0_30 <- read_csv("reports/06_analysis/summaries/Country_Stats_0_30.csv")
Country_Stats_30_100 <- read_csv("reports/06_analysis/summaries/Country_Stats_30_100.csv")


#### clean data ##########

##### realm 

realm_0_30 <- Realm_Stats_0_30 %>% 
  rename(aoa_prop0 = aoa_prop) %>% 
  dplyr::select(-column1, -column3)

realm_30_100 <- Realm_Stats_30_100 %>% 
  rename(aoa_prop30 = aoa_prop)%>% 
  dplyr::select(-column1, -column3)

realm <- full_join(realm_0_30, realm_30_100, by = "Zone") %>% 
  mutate(pred_1m = mean_pred0_aoa + mean_pred30_aoa,
         err_1m = mean_err0_aoa + mean_err30_aoa)

realm_over50aoa <- realm %>% 
  filter(aoa_prop0 > 30 & aoa_prop30 > 30) %>% 
  arrange(desc(pred_1m))

##### countries 
countries_0_30 <- Country_Stats_0_30 %>% 
  filter(Area > 10) %>% 
  rename(aoa_prop0 = aoa_prop)

countries_30_100 <- Country_Stats_30_100 %>% 
  filter(Area > 10) %>% 
  rename(aoa_prop30 = aoa_prop)



country <- full_join(countries_0_30,countries_30_100, 
                     by = c("Country", "Area", "Area_lower", "Area_upper")) %>% 
  mutate(pred_1m = mean_pred0_aoa + mean_pred30_aoa,
         err_1m = mean_err0_aoa + mean_err30_aoa) %>% 
  mutate(stock_1m = pred_1m * Area * 100 / 1000000 , # *100 for km2 to hectare, / 1000000 for megagram to teragram
        stock_err_1m = err_1m * Area * 100 / 1000000 , 
        stock_area_lower = pred_1m * Area_lower * 100 / 1000000 , 
        stock_area_upper = pred_1m * Area_upper * 100 / 1000000) %>% 
  mutate(stock_30cm = mean_pred0_aoa * Area * 100 / 1000000 , # *100 for km2 to hectare, / 1000000 for megagram to teragram
         stock_err_30cm = mean_err0_aoa * Area * 100 / 1000000) 

#### Table S2 countries ####

country_table <- country %>% 
  select(Country, mean_pred0, mean_err0, aoa_prop0, mean_pred0_aoa, mean_err0_aoa,
         mean_pred30, mean_err30, aoa_prop30, mean_pred30_aoa, mean_err30_aoa,
         Area, stock_1m, stock_err_1m) %>% 
  mutate(initial_0 = paste(mean_pred0, " (",mean_err0, ")", sep = ""),
         final_0 = paste(mean_pred0_aoa, " (",mean_err0_aoa, ")", sep = ""), 
         initial_30 = paste(mean_pred30, " (",mean_err30, ")", sep = ""),
         final_30 = paste(mean_pred30_aoa, " (",mean_err30_aoa, ")", sep = "")
  ) %>% 
  mutate(area = round(Area, 2),
         stock_1m = round(stock_1m, 2),
         stock_err_1m = round(stock_err_1m, 2),
         final_stock = paste(stock_1m, " (",stock_err_1m, ")", sep = "")) %>% 
  dplyr::select(Country,initial_0, aoa_prop0, final_0, 
                initial_30, aoa_prop30, final_30,
                area, final_stock) %>% 
  mutate(final_0 = case_when(final_0 == "NA (NA)" ~ "",
                             TRUE ~ final_0),
         final_30 = case_when(final_30 == "NA (NA)" ~ "",
                             TRUE ~ final_30),
         final_stock = case_when(final_stock == "NA (NA)" ~ "",
                             TRUE ~ final_stock))

# # Write this table to a comma separated .txt file:    
# write.table(country_table, file = "reports/06_analysis/summaries/country_table.txt", 
#             sep = ",", quote = FALSE, row.names = F)

#### plot #### 

country_top10 <- country %>% 
  arrange(desc(stock_1m)) %>% 
  slice(1:10) 

plot_country_top10 <- country_top10 %>% 
  mutate(Country = fct_relevel(Country, "Cuba", "Ukraine", "Mozambique", "Brazil",
                               "Mexico", "Australia", "Argentina",
                               "Russia", "Canada", "United States")) %>% 
  ggplot()+
  geom_bar(aes(x = Country, y = stock_1m), color = "black", fill = "grey", stat="identity") + 
  geom_errorbar(aes(x=Country, ymin=stock_1m-stock_err_1m, 
                    ymax=stock_1m+stock_err_1m), width=0, linewidth = 0.8) +
  labs(x = "", y = "Total SOC stock to 1 m (Tg)")+
  scale_y_continuous(limits = c(0,780), expand = c(0,0))+
  coord_flip() +  
  theme_bw()+
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))
plot_country_top10

ggsave("reports/05_figures/paper_figures/Figure 3b.png", plot_country_top10, 
       width = 9.02, height = 2.78)


### realms
# 
# plot_0 <- ggplot(realm_0_30, aes(x = aoa_prop0, y = mean_pred0_aoa, label = Zone))+
#   geom_point(size =4)+
#   geom_errorbar(aes(x=aoa_prop0, ymin=mean_pred0_aoa-mean_err0_aoa, 
#                     ymax=mean_pred0_aoa+mean_err0_aoa), width=0, linewidth = 0.4) +
#   geom_text_repel(
#     force_pull   = 0, # do not pull toward data points
#     nudge_y      = 0.05,
#     direction    = "x",
#     angle        = 90,
#     hjust        = 0,
#     segment.size = 0.2
#   )+
#   labs(x = "Proportion in the area of applicability (%)", y = "Average SOC prediction (Mg C ha-1)")+  
#   theme_bw()+
#   theme(axis.text = element_text(size = 10, color = 'black'),
#         axis.title = element_text(size = 12, color = 'black'))
# plot_0
# 
# plot_30 <- ggplot(realm_30_100, aes(x = aoa_prop30, y = mean_pred30_aoa, label = Zone))+
#   geom_point(size =4)+
#   geom_errorbar(aes(x=aoa_prop30, ymin=mean_pred30_aoa-mean_err30_aoa, 
#                     ymax=mean_pred30_aoa+mean_err30_aoa), width=0, linewidth = 0.4) +
#   geom_text_repel(
#     force_pull   = 0, # do not pull toward data points
#     nudge_y      = 0.05,
#     direction    = "x",
#     angle        = 90,
#     hjust        = 0,
#     segment.size = 0.2
#   )+
#   labs(x = "Proportion in the area of applicability (%)", y = "Average SOC prediction (Mg C ha-1)")+  
#   theme_bw()+
#   theme(axis.text = element_text(size = 10, color = 'black'),
#         axis.title = element_text(size = 12, color = 'black'))
# plot_30
# 
# 
# final_realm <- plot_grid(plot_0, plot_30, labels = c("a)", "b)"), nrow = 2, ncol = 1)
# final_realm

#### vertical

plot_0 <- ggplot(realm_0_30, aes(x = mean_pred0_aoa, y = aoa_prop0, label = Zone))+
  geom_errorbar(aes(y=aoa_prop0, xmin=mean_pred0_aoa-mean_err0_aoa, 
                    xmax=mean_pred0_aoa+mean_err0_aoa), width=0, linewidth = 0.4) +
  geom_point(size =4, aes(color = Zone))+
  geom_text_repel()+
  # labs(x = "", y = ""  )+
  labs(x = "Average SOC prediction (Mg C ha-1)", y = "Proportion in the area of applicability (%)"  )+  
  theme_bw()+
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))+
  scale_y_continuous(limits = c (0,100)) +
  scale_x_continuous(limits = c(-5,200)) +
  theme(legend.position="none")
plot_0

plot_30 <- ggplot(realm_30_100, aes(x = mean_pred30_aoa, y = aoa_prop30, label = Zone))+
  geom_errorbar(aes(y=aoa_prop30, xmin=mean_pred30_aoa-mean_err30_aoa, 
                    xmax=mean_pred30_aoa+mean_err30_aoa), width=0, linewidth = 0.4) +
  geom_point(size =4, aes(color = Zone))+
  geom_text_repel()+
  # labs(x = "", y = ""  )+
  labs(x = "Average SOC prediction (Mg C ha-1)", y = "Proportion in the area of applicability (%)"  )+  
  theme_bw()+
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.title = element_text(size = 12, color = 'black'))+
  scale_y_continuous(limits = c (0,100))+
  scale_x_continuous(limits = c(-5,400))+
  theme(legend.position="none")
plot_30

x_label <- "Average SOC prediction (Mg C ha-1)" 
y_label <- "Proportion in the area of applicability (%)"

final_realm_vertical <- plot_grid(plot_0, plot_30, labels = c("a", "b"), nrow = 1, ncol = 2)
final_realm_vertical 

ggsave("reports/05_figures/paper_figures/pdfs/Figure 3 raw.pdf", final_realm_vertical, 
       width = 7.93, height = 6.01)


### 
#### with aoa as size
plot_0 <- ggplot(realm_0_30, aes(x = Zone, y = mean_pred0_aoa))+
  geom_point(aes(size = aoa_prop0))+
  geom_errorbar(aes(x=Zone, ymin=mean_pred0_aoa-mean_err0_aoa, 
                    ymax=mean_pred0_aoa+mean_err0_aoa), width=0, linewidth = 0.4) +
  labs(x = "Proportion in the area of applicability (%)", y = "Average SOC prediction (Mg C ha-1)")+  
  theme_bw()+
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.text.x = element_text(angle =30, vjust = 1, hjust =1),
        axis.title = element_text(size = 12, color = 'black'))
plot_0



plot_30 <- ggplot(realm_30_100, aes(x = Zone, y = mean_pred30_aoa))+
  geom_point(aes(size = aoa_prop30))+
  geom_errorbar(aes(x=Zone, ymin=mean_pred30_aoa-mean_err30_aoa, 
                    ymax=mean_pred30_aoa+mean_err30_aoa), width=0, linewidth = 0.4) +
  labs(x = "Proportion in the area of applicability (%)", y = "Average SOC prediction (Mg C ha-1)")+  
  theme_bw()+
  theme(axis.text = element_text(size = 10, color = 'black'),
        axis.text.x = element_text(angle =30, vjust = 1, hjust =1),
        axis.title = element_text(size = 12, color = 'black'))
plot_30


final_realm <- plot_grid(plot_0, plot_30, labels = c("a)", "b)"), nrow = 2, ncol = 1)
final_realm
