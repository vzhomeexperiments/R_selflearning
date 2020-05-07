# ----------------------------------------------------------------------------------------
# R Script to score the latest asset indicator data against Deep Learning model
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
# load prices of 28 currencies
path_sbxm <- "C:/Program Files (x86)/FxPro - Terminal1/MQL4/Files"
path_sbxs <- "C:/Program Files (x86)/FxPro - Terminal3/MQL4/Files"

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

aml_score_data(symbol = PAIR,
               num_bars = predictor_period,
               timeframe = time_frame,
               path_model = path_model,
               path_data = path_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)

}

# shutdown h2o
h2o.shutdown(prompt = F)

# outcome is series of files written to the sandboxes of each terminals


