# ----------------------------------------------------------------------------------------
# R Script to train the Deep Learning model on Financial Asset Time Series Data
# ----------------------------------------------------------------------------------------
# (C) 2019 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to perform
# Supervised Deep Learning Regression Modelling
#
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)
library(lazytrade)
#library(plotly)
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/load_asset_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/create_labelled_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/create_transposed_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/self_learn_ai_R.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/test_model.R")

#absolute path to store model objects (useful when scheduling tasks)
path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_MODELS"

#absolute path with the data (choose either MT4 directory or a '_TEST_DATA' folder)
path_data <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
#path_data <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_TEST_DATA/"

#### Read asset prices and indicators ==========================================
# load prices of 28 currencies
prices <- load_asset_data(path_terminal = path_data,
                          trade_log_file = "AI_CP", 
                          time_period = 15,
                          data_deepth = "35000")

# load macd indicator of 28 currencies
macd <- load_asset_data(path_terminal = path_data,
                        trade_log_file = "AI_Macd", 
                        time_period = 15,
                        data_deepth = "35000")

# start h2o engine (using all CPU's by default)
h2o.init()

# performing Deep Learning Regression using the custom function
self_learn_ai_R(price_dataset = prices,
                indicator_dataset = macd,
                num_bars = 75,
                timeframe = 15,
                path_model = path_model,
                write_log = TRUE)

# stop h2o engine
h2o.shutdown(prompt = F)

# update trigger in the sandboxes
# read trigger value to the repository and paste it to the sandboxes
file.copy(from = file.path(path_model, "LOG", "AI_T-15.csv"), 
          to = c("C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/AI_T-15.csv",
                 "C:/Program Files (x86)/FxPro - Terminal1/MQL4/Files/AI_T-15.csv",
                 "C:/Program Files (x86)/FxPro - Terminal3/MQL4/Files/AI_T-15.csv",
                 "C:/Program Files (x86)/FxPro - Terminal4/MQL4/Files/AI_T-15.csv",
                 "C:/Program Files (x86)/FxPro - Terminal5/MQL4/Files/AI_T-15.csv"),
          overwrite = TRUE) 


#### End