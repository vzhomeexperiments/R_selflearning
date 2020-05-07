# ----------------------------------------------------------------------------------------
# R Script to collect the asset indicator data and respective 'future' price change
# ----------------------------------------------------------------------------------------
# (C) 2019 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
#
# load libraries to use and custom functions
library(tidyverse)
library(lubridate)
library(lazytrade)

#### Read asset prices and indicators ==========================================
#absolute path with the data (choose either MT4 directory or a '_TEST_DATA' folder)

path_terminal <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
macd <- load_asset_data(path_terminal = path_terminal, trade_log_file = "AI_Macd", time_period = 15, data_deepth = "300")
prices <- load_asset_data(path_terminal = path_terminal, trade_log_file = "AI_CP", time_period = 15, data_deepth = "300")

path_data <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_DATA"
# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

# Writing indicator and price change to the file
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
# performing data collection using the custom function
aml_collect_data(price_dataset = prices,
                 indicator_dataset = macd,
                 symbol = PAIR,
                 num_bars = 75,
                 timeframe = 15,
                 path_data = path_data)
  
 #full_path <- file.path(path_data, 'EURUSDM15X75.rds')
 #full_path <- file.path(path_data, 'GBPUSDM15X75.rds')  
 #x1 <- read_rds(full_path)
  
}

# outcome is series of files written to the _DATA folder of the repository


