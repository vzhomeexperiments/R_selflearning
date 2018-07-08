# ----------------------------------------------------------------------------------------
# R Script to score the latest asset indicator against Deep Learning model
# ----------------------------------------------------------------------------------------
# (C) 2018 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to predict
# with Deep Learning Classification Model
#
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
#### Read asset prices and indicators ==========================================
# load prices of 28 currencies
sbx <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files"
sbx_masterT1 <- "C:/Program Files (x86)/FxPro - Terminal1/MQL4/Files"
sbx_slaveT3 <- "C:/Program Files (x86)/FxPro - Terminal3/MQL4/Files"
sbx_slaveT4 <- "C:/Program Files (x86)/FxPro - Terminal4/MQL4/Files"
sbx_slaveT5 <- "C:/Program Files (x86)/FxPro - Terminal5/MQL4/Files"
time_frame <- 1         #this is to define chart timeframe periodicity
predictor_period <- 75  #this variable will define market type period (number of bars)
# load macd indicator of 28 currencies, use for demo: macd <- read_rds("test_data/macd.rds")
macd <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/",
                  trade_log_file = "AI_Macd", 
                  time_period = time_frame,
                  data_deepth = 300)

# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

### Indicator values for the last periods
data_latest <- macd %>% head(2*predictor_period) %>% create_transposed_data(predictor_period) %>% 
  # need to add fake category to avoid h2o prediction function errors
  mutate(LABEL = "BU") %<>% 
  # same as data_latest$LABEL <- as.factor(data_latest$LABEL)
  mutate_at(predictor_period + 1, as.factor) 

### also dataset for Regression prediction
data_latest_R <- macd %>% head(2*predictor_period) %>% create_transposed_data(predictor_period) 

### Predicting the next period
# initialize the virtual machine
h2o.init(nthreads = 1)
# loading the model
ModelC <- h2o.loadModel(path = paste0("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/model/DL_Classification",
                                      predictor_period, "-", time_frame))
# uploading data to h2o
recent_ML  <- as.h2o(x = data_latest, destination_frame = "recent_ML")
# PREDICT the next period...
result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame()

# save for Regression model
ModelR <- h2o.loadModel(path = paste0("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/model/DL_Regression",
                                      predictor_period, "-", time_frame))
# uploading data to h2o
recent_ML  <- as.h2o(x = data_latest_R, destination_frame = "recent_ML")
# PREDICT the next period...
result_R <- h2o.predict(ModelR, recent_ML) %>% as.data.frame()

# shutdown h2o
h2o.shutdown(prompt = F)

### Applying prediction by writing files
# Rename the rownames
rownames(result) <- Pairs
rownames(result_R) <- Pairs

# test for all columns
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # filter by row and select prediction
  df <- result %>% filter(row.names(result) %in% PAIR) %>% select(predict)
  # name the column with pair name
  names(df) <- PAIR
  # write to the files
  file_string <- paste0("AI_M", time_frame, "_Direction", PAIR, ".csv")
  write_csv(df, file.path(sbx, file_string))
  write_csv(df, file.path(sbx_masterT1, file_string))
  write_csv(df, file.path(sbx_slaveT3,  file_string))
  write_csv(df, file.path(sbx_slaveT4,  file_string))
  write_csv(df, file.path(sbx_slaveT5,  file_string))
  
  # create record to the log file;
  df_log <- result %>% filter(row.names(result) %in% PAIR) %>% select(predict) %>% 
    # add new column
    mutate(DT = Sys.time())
  # write to the file
  file_string <- paste0("AI_M", time_frame, "_Direction", PAIR, "-log.csv")
  write_csv(df_log, file.path(sbx, file_string),append = TRUE)
  
}

# same for regression (writing predicted price change to the file)
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # filter by row and select prediction
  df <- result_R %>% filter(row.names(result_R) %in% PAIR) %>% select(predict)
  # name the column with pair name
  names(df) <- PAIR
  # write to the files
  file_string <- paste0("AI_M", time_frame, "_Change", PAIR, ".csv")
  write_csv(df, file.path(sbx, file_string))
  write_csv(df, file.path(sbx_masterT1, file_string))
  write_csv(df, file.path(sbx_slaveT3,  file_string))
  write_csv(df, file.path(sbx_slaveT4,  file_string))
  write_csv(df, file.path(sbx_slaveT5,  file_string))
  
  # create record to the log file;
  df_log <- result_R %>% filter(row.names(result_R) %in% PAIR) %>% select(predict) %>% 
    # add new column
    mutate(DT = Sys.time())
  # write to the file
  file_string <- paste0("AI_M", time_frame, "_Change", PAIR, "-log.csv")
  write_csv(df_log, file.path(sbx, file_string),append = TRUE)
  
}

# outcome is series of files written to the sandboxes of each terminals


