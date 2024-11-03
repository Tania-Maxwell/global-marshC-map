#script written by Tom Worthington taw52@cam.ac.uk

library(dplyr)
library(corrplot)
library(ggplot2)
library(jsonlite)
library(grid)
library(cowplot)
library(tidyr)

train <- read.csv("reports/03_modelling/data/data_clean_SOCD.csv")

cov <- read.csv("reports/03_modelling/data/2023-08-30_data_covariates_global_native.csv ")


df1 <- inner_join(train,cov, by = c("Lat_Long"))

length(unique(df1$Lat_Long)) ## should be 3710

trainDat <- df1 %>% 
  #select(names_pred) # this is so that it matches the layers where we are predicting onto
  dplyr::select(Lat_Long, Latitude, Longitude, ndvi_med, ndvi_stdev,
                #  Human_modification, 
                M2Tide, PETdry, #PETwarm, # highly correlated to maxTemp
                TSM, maxTemp, minTemp, maxPrecip, minPrecip, 
                #  popDens, 
                copernicus_elevation,
                copernicus_slope, SLR_zone, ECU)

df2 <- trainDat[!duplicated(trainDat$Lat_Long),]

colSums(is.na(df2)) 

df2 <- na.omit(df2)
df3 <- df2[,4:14]

colnames(df3) <- c("NDVI - Median", "NDVI - StDev", "Tidal range", "PET", "TSM",
                   "Temperature - Max", "Temperature - Min","Preciptitation - Max", "Preciptitation - Min",
                   "Elevation", "Slope")

M <- cor(df3)

tiff(file="Correlation.tif", width=6000, height=6000, res=600, compression = c("lzw"))
png(file="Correlation.png", width=6000, height=6000, res=600)
corrplot(M, method="square" , tl.col="black", type = "upper", addCoef.col = 'black')
dev.off()

####### VIOLIN PLOTS

dat <- read.csv("reports/03_modelling/data/2024-07-31_global_sample_10k.csv")
colSums(is.na(dat)) 
dat <- dat %>%
  mutate(
    long = sapply(.geo, function(x) fromJSON(x)$coordinates[1]),
    lat = sapply(.geo, function(x) fromJSON(x)$coordinates[2])
  )


### Latitude 
combined_df <- data.frame(
  Value = c(dat$lat, df2$Latitude),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

Lat <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
            geom_violin(trim=FALSE) +
            scale_y_continuous(breaks=seq(-60, 60, by = 40), expand = c(0, 0)) +
            geom_boxplot(width=0.1, fill="white") +
            scale_fill_brewer(palette="Dark2") +
            theme_classic() +
            theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
            theme(axis.title.x=element_blank()) +
            theme(axis.text.x = element_text(color = "black", size = 10)) +
            theme(axis.text.y = element_text(color = "black", size = 10)) +
            theme(legend.position = "none") +
            labs(y = "Latitude") +
            labs(tag = "a", font = 2) +
            theme(
              plot.tag = element_text(face = "bold"),
              plot.tag.position = c(0.01, 0.98)
            )
  
Lat

### Longitude 
combined_df <- data.frame(
  Value = c(dat$long, df2$Longitude),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

Long <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(breaks=seq(-180, 180, by = 60), expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Longitude") +
  labs(tag = "b", font = 2) +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

Long

### NDVI medium

combined_df <- data.frame(
  Value = c(dat$ndvi_med,df2$ndvi_med),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

NDVI_Med <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "NDVI - median") +
  labs(tag = "c") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

NDVI_Med

### NDVI SD

combined_df <- data.frame(
  Value = c(dat$ndvi_stdev, df2$ndvi_stdev),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

NDVI_SD <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "NDVI - SD") +
  labs(tag = "d") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

NDVI_SD

### Elevation

combined_df <- data.frame(
  Value = c(dat$copernicus_elevation, df2$copernicus_elevation),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

Elevation <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Elevation (m)") +
  labs(tag = "e") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

Elevation

### Slope

combined_df <- data.frame(
  Value = c(dat$copernicus_slope, df2$copernicus_slope),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

Slope <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Slope (%)") +
  labs(tag = "f") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

Slope

### Tidal amplitude

combined_df <- data.frame(
  Value = c(dat$M2Tide/100, df2$M2Tide/100),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

Tide <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Tidal amplitude (m)") +
  labs(tag = "g") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

Tide

###  SLR
combined_df <- data.frame(
  Value = c(dat$SLR_zone, df2$SLR_zone),
  Source = factor(c(rep("Global", 10000), rep("Training", 3682))))

# Calculate the percentage of each SLR zone within each group
percentage_df <- combined_df %>%
  group_by(Source, Value) %>%
  summarise(Count = n()) %>%
  ungroup() %>%
  group_by(Source) %>%
  mutate(Percentage = Count / sum(Count) * 100)

# Draw the grouped bar plot
SLR <- ggplot(percentage_df, aes(x = Value, y = Percentage, fill = Source)) +
  geom_bar(stat = "identity", position = "dodge", color = "blaCK") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  labs(x = "SLR zone", y = "Percentage", fill = NULL) +
  theme_classic() +
  scale_fill_brewer(palette="Dark2") +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  labs(tag = "h") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  ) +
  theme(legend.position = c(0.98, 0.98), # Position legend in top-left corner
        legend.justification = c(1, 1))  # Adjust legend anchor point

SLR

### ECU

combined_df <- data.frame(
  Value = c(dat$ECU, df2$ECU),
  Source = factor(c(rep("Global", 10000), rep("Training", 3682))))

# Calculate the percentage of each SLR zone within each group
percentage_df <- combined_df %>%
  group_by(Source, Value) %>%
  summarise(Count = n(), .groups = 'drop') %>%
  complete(Source, Value, fill = list(Count = 0)) %>%  # Fill in missing combinations with Count = 0
  group_by(Source) %>%
  mutate(Percentage = Count / sum(Count) * 100)

# Draw the grouped bar plot
ECU <- ggplot(percentage_df, aes(x = Value, y = Percentage, fill = Source)) +
  geom_bar(stat = "identity", position = "dodge", color = "blaCK") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  labs(x = "ECU group", y = "Percentage", fill = NULL) +
  theme_classic() +
  scale_fill_brewer(palette="Dark2") +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  labs(tag = "i") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  ) +
  theme(legend.position = c(0.98, 0.98), # Position legend in top-left corner
        legend.justification = c(1, 1)) + # Adjust legend anchor point
  scale_x_continuous(breaks = seq(2,16,2)) # Label every 2nd x-axis value
ECU

### Temperature - Max

combined_df <- data.frame(
  Value = c(dat$maxTemp/10, df2$maxTemp/10),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

MaxTemp <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Temperature (°C)") +
  labs(tag = "j") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

MaxTemp

### Temperature - Min

combined_df <- data.frame(
  Value = c(dat$minTemp/10, df2$minTemp/10),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

MinTemp <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Temperature (°C)") +
  labs(tag = "k") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

MinTemp

### Precipitation - Max

combined_df <- data.frame(
  Value = c(dat$maxPrecip, df2$maxPrecip),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

MaxPrecip <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Precipitation (mm)") +
  labs(tag = "l") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

MaxPrecip

### Precipitation - Min

combined_df <- data.frame(
  Value = c(dat$minPrecip, df2$minPrecip),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

MinPrecip <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = "Precipitation (mm)") +
  labs(tag = "m") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

MinPrecip

### PET

combined_df <- data.frame(
  Value = c(dat$PETdry, df2$PETdry),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

PET <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = expression("PET (mm month"^-1*")")) +
  labs(tag = "n") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

PET

### TSM

combined_df <- data.frame(
  Value = c(dat$TSM, df2$TSM),
  Source = factor(c(rep("Global sample", 10000), rep("Training data", 3682))))

TSM <- ggplot(combined_df, aes(x = Source, y = Value, fill = Source)) +
  geom_violin(trim=FALSE) +
  scale_y_continuous(expand = c(0, 0)) +
  geom_boxplot(width=0.1, fill="white") +
  scale_fill_brewer(palette="Dark2") +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, size = 1)) +
  theme(axis.title.x=element_blank()) +
  theme(axis.text.x = element_text(color = "black", size = 10)) +
  theme(axis.text.y = element_text(color = "black", size = 10)) +
  theme(legend.position = "none") +
  labs(y = expression("TSM (g m"^-3*")")) +
  labs(tag = "o") +
  theme(
    plot.tag = element_text(face = "bold"),
    plot.tag.position = c(0.01, 0.98)
  )

TSM

######
tiff(file="Covariates.tif", width=12000, height=15000, res=1200, compression = c("lzw"))
par(oma = c(0.5,0.5,0.5,0.5))
plot_grid(Lat, Long, NDVI_Med,
          NDVI_SD, Elevation, Slope,
          Tide, SLR, ECU,
          MaxTemp, MinTemp, MaxPrecip,
          MinPrecip, PET, TSM,
          ncol = 3, nrow = 5, align = "vh")
dev.off()


png(file="Covariates.png", width=12000, height=15000, res=1200)
par(oma = c(0.5,0.5,0.5,0.5))
plot_grid(Lat, Long, NDVI_Med,
          NDVI_SD, Elevation, Slope,
          Tide, SLR, ECU,
          MaxTemp, MinTemp, MaxPrecip,
          MinPrecip, PET, TSM,
          ncol = 3, nrow = 5, align = "vh")
dev.off()