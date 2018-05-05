# ----------------------------------------------------------------------------------------
# R Script to auto-select and train the Deep Learning model on Financial Asset Time Series Data
# ----------------------------------------------------------------------------------------
# (C) 2018 Vladimir Zhbanko
# https://www.udemy.com/draft/1482480/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to perform
# Supervised Deep Learning Classification Modelling
#
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)
#library(plotly)
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")

#### Read asset prices and indicators ==========================================
# load prices of 28 currencies
pathT2 <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
prices <- read_csv(file.path(pathT2, "AI_CP1.csv"), col_names = F)
prices$X1 <- ymd_hms(prices$X1)
# load macd indicator of 28 currencies
macd <- read_csv(file.path(pathT2, "AI_Macd1.csv"), col_names = F)
macd$X1 <- ymd_hms(macd$X1)

# to be used for tests of demonstrations
# prices <- read_rds("test_data/prices.rds")
# macd <- read_rds("test_data/macd.rds")

#### Automatically Selecting data... =================================================
# Market Periods
# 1. Bullish, BU
# 2. Bearish, BE
##########################################################################
## ---------- Data Preparation  ---------------
##########################################################################
# transform data and get the labels shift rows down
dat14 <- create_labelled_data(prices, 100) %>% mutate_all(funs(lag), n=28) 
# transform data for indicator
dat15 <- create_transposed_data(macd, 100) 
# dataframe for the DL modelling it contains all 
dat16 <- dat14 %>% select(LABEL) %>% bind_cols(dat15) %<>% mutate_at(1, as.factor) %>% na.omit()

#library(plotly)
## Visualize new matrix in 3D
#plot_ly(z = as.matrix(dat16[,2:16]), type = "surface")

##########################################################################
## ---------- Data Modelling  ---------------
##########################################################################
h2o.init()

# load data into h2o environment
macd_ML  <- as.h2o(x = dat16, destination_frame = "macd_ML")

# fit models from simplest to more complex
ModelC <- h2o.deeplearning(
  model_id = "DL_Classification",
  x = names(macd_ML[,2:101]), 
  y = "LABEL",
  training_frame = macd_ML,
  activation = "Tanh",
  overwrite_with_best_model = TRUE, 
  autoencoder = FALSE, 
  hidden = c(100,100), 
  loss = "Automatic",
  sparse = TRUE,
  l1 = 1e-4,
  distribution = "AUTO",
  stopping_metric = "AUTO",
  balance_classes = F,
  epochs = 200)

#ModelC
#summary(ModelC)
#h2o.performance(ModelC)

## Checking how the model predict using the latest dataset
# get the labelled data for the test
dat17 <- create_labelled_data(prices, 100) %>% select(LABEL) %>% head(28)
# transform data for indicator and get the subset to predict
dat18 <- create_transposed_data(macd, 100) %>% head(56) %>% tail(28) %>% 
  # need to add fake category to avoid h2o prediction function errors
  mutate(LABEL = "BU") %<>% 
  # same as data_latest$LABEL <- as.factor(data_latest$LABEL)
  mutate_at(101, as.factor) 

# upload recent dataset to predict
recent_ML  <- as.h2o(x = dat18, destination_frame = "recent_ML")
# use model to 
result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame() %>% select(predict) %>% bind_cols(dat17) %>% 
  # compare predicted vs real
  mutate(MATCH = ifelse(predict==LABEL, 1, 0)) %>% 
  # count matches
  summarise(Quality = sum(MATCH)/28)

# save the model in case it's correctly predicting in more than 50% of the cases
if(result$Quality > 0.5){
  h2o.saveModel(ModelC, path = "model/", force = T)
}

h2o.shutdown(prompt = FALSE)





#### End