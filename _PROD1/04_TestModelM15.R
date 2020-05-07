# ----------------------------------------------------------------------------------------
# R Script to test the Deep Learning model for all currency pairs
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

#### definition of paths and variables ==========================================
path_data <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_DATA"
#absolute path to store model objects (useful when scheduling tasks)
path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_MODELS"

time_frame <- 15         #this is to define chart timeframe periodicity
predictor_period <- 75  #this variable will define market type period (number of bars)

# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

# initialize the virtual machine
h2o.init(nthreads = 1)

for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"

  # test the results of predictions
  aml_test_model(symbol = PAIR,
                 num_bars = predictor_period,
                 timeframe = time_frame,
                 path_model = path_model,
                 path_data = path_data)  

}

# shutdown h2o
h2o.shutdown(prompt = F)

# outcome is series of files written to the folder path_model

#set delay to insure h2o unit closes properly
Sys.sleep(5)

