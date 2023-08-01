## file to dump unused scripts in files - might be useful later

#### 02_SOM_to_OC ####


# mutate(OC_perc_estimated = 
#          
#          case_when(
#            # is.na(OC_perc_combined) == FALSE 
#            #         & is.na(SOM_perc_combined) == FALSE
#            #         & is.na(Conv_factor) == FALSE
#            #          ~ OC_perc_combined,
#                    
#            #only replace values when OC_perc is NA and the Conv_factor is NA
#                     is.na(OC_perc_combined) == TRUE 
#                     & is.na(SOM_perc_combined) == FALSE 
#                     & is.na(Conv_factor) == TRUE 
#            #using our quadratic equation
#                      ~ OC_from_SOM_our_eq,
#          
#            #observed values           
#           is.na(OC_perc_combined) == FALSE
#           & is.na(SOM_perc_combined) == TRUE
#           & is.na(Conv_factor) == TRUE
#           ~ NA_real_ )) %>%




#### 03_bulk_density ####




#### help from Lukas ####

# create some data points from a double-exponential distribution
n <- 1000
obs <- rdexp(n, location = 0, scale = 1)
# make all values positive
obs <- obs + abs(obs)
# sort
obs_sort <- sort(obs, decreasing=TRUE)
# add some noise to the observations
noise <- rnorm(n, mean=0, sd=1)
obs_sort_noisy <- obs_sort + noise

# x-values
x <- 1:1000

df = data.frame(obs=obs_sort_noisy, x=x)
plot(df$x, df$obs)

# function to fit the data
BD_simple <- function(x, a, b){
  a * exp(-x/b)
}

# here's where the model is created. start= needs some best guess starting values for each coefficient
# for a simple exponential it's easier to have a guess given what the data looks like
model <- nls(obs ~ BD_simple(x, a, b), data=df, start=list(a=20, b=10))

summary(model)

a_est <- summary(model)[['coefficients']][[1]]
b_est <- summary(model)[['coefficients']][[2]]

fitted_values <- BD_simple(df$x, a_est, b_est)

plot(df$x, df$obs)
lines(df$x, fitted_values, col="red")


















#### Fit a simple Model ####



BD_simple <- function(x, a, b){
  a * exp(-x*b)
}

# remove NAs from the data frame
input_data_model <- input_data01 %>% 
  drop_na(OC_perc) %>% 
  drop_na(BD_reported_g_cm3)

# create a random sequence of numbers from which to predict y values 
# i.e. random values of OC_perc where we'll predict BD
xBD = seq(from = 0.001, to = 50, 
          length.out = length(input_data_model$BD_reported_g_cm3[!is.na(input_data_model$BD_reported_g_cm3)]))


simple_model <- nls(BD_reported_g_cm3 ~ BD_simple(OC_perc, a, b), 
                    data=input_data_model, start=list(a=0.8758, b=0.0786))

summary(simple_model)

a_est <- summary(simple_model)[['coefficients']][[1]]
b_est <- summary(simple_model)[['coefficients']][[2]]

fitted_values <- BD_simple(xBD, a_est, b_est)

plot(input_data_model$OC_perc, input_data_model$BD_reported_g_cm3)
lines(xBD, fitted_values, col="red")


# ### calculation prediction intervals for the predictions 
# predictions <- predictNLS(quadratic_model, newdata = data.frame(SOM_perc_combined = xOC2),
#                           interval="pred")
# predictions$summary
# 
# 
# modelr::rsquare(quadratic_model, data_SOM_OC)
