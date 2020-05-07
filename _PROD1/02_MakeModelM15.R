# ----------------------------------------------------------------------------------------
# R Script to build or update Deep Learning model for every Currency Pair
# ----------------------------------------------------------------------------------------
# (C) 2019 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
#
# load libraries to use and custom functions
#library(tidyverse)
library(magrittr)
library(dplyr)
library(readr)
library(h2o)
library(lazytrade)

#### Read asset prices and indicators ==========================================
#absolute path with the data (choose either MT4 directory or a '_TEST_DATA' folder)
path_data <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_DATA"
# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")  
#absolute path to store model objects (useful when scheduling tasks)
path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_MODELS"

#path to store logs data (e.g. duration of machine learning steps)
path_logs <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_LOGS"

#record time when the script starts to run
time_start <- Sys.time()

h2o.init()

# Writing indicator and price change to the file
for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"
 # performing Deep Learning Regression using the custom function
 aml_make_model(symbol = PAIR,
                num_bars = 75,
                timeframe = 15,
                path_model = path_model,
                path_data = path_data)

}  
  
 # stop h2o engine
h2o.shutdown(prompt = F)

#record time when the script ended to run
time_end <- Sys.time()
#calculate total time difference in seconds
time_total <- difftime(time_end,time_start,units="sec")
#convert to numeric
as.double(time_total)

# extract number of rows in the datasets
x <- read_rds(file.path(path_data, "EURUSDM15X75.rds"))
n_rows_x <- nrow(x)

#setup a log dataframe
logs <- data.frame(time2run = time_total, nrows = n_rows_x)

#read existing log (if exists) and add there a new log data
if(!file.exists(file.path(path_logs, 'time_executeM15.rds'))){
  write_rds(logs, file.path(path_logs, 'time_executeM15.rds'))
} else {
  read_rds(file.path(path_logs, 'time_executeM15.rds')) %>% 
    bind_rows(logs) %>% 
    write_rds(file.path(path_logs, 'time_executeM15.rds'))
}


# outcome are the models files for each currency pair written to the folder /_MODELS
#set delay to insure h2o unit closes properly
Sys.sleep(5)

