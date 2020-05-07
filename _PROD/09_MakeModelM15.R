# ----------------------------------------------------------------------------------------
# R Script to build or update Deep Learning model for every Currency Pair
# ----------------------------------------------------------------------------------------
# (C) 2019 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
#
# load libraries to use and custom functions
library(tidyverse)
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


# outcome are the models files for each currency pair written to the folder /_MODELS


