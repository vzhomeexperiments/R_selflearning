# ----------------------------------------------------------------------------------------
# R Script to score the latest asset indicator data against Deep Learning model
# ----------------------------------------------------------------------------------------
# (C) 2019, 2020 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# load libraries to use and custom functions
library(dplyr)
library(readr)
library(lubridate)
library(h2o)
library(magrittr)
library(lazytrade)

#path to user repo:
#!!!Change this path!!! 
path_user <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning"

#### definition of paths and variables ==========================================
path_data <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"

#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")

# load prices of 28 currencies
path_sbxm <- "C:/Program Files (x86)/FxPro - Terminal1/MQL4/Files"
path_sbxs <- "C:/Program Files (x86)/FxPro - Terminal3/MQL4/Files"

# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

# initialize the virtual machine
h2o.init(nthreads = 1)

for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"
aml_score_data(symbol = PAIR,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)

}

# shutdown h2o
h2o.shutdown(prompt = F)

# outcome is series of files written to the sandboxes of each terminals


