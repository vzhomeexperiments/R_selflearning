# ----------------------------------------------------------------------------------------
# R Script to Find the best possible strategy of using Self-learning algorithms
# ----------------------------------------------------------------------------------------
# (C) 2018 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to perform
# Supervised Deep Learning Classification Modelling
#
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)
#library(plotly)
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/self_learn_ai.R")
source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/self_learn_ai_R.R")

h2o.init()

### Create For loop to test possible outcomes and test those strategies
options_predict_ahead <- c(75, 100, 125)
options_time_periodicity <- c(1, 15, 60)

for (AHEAD in options_predict_ahead) {
  for (PERIODS in options_time_periodicity) {
    #### Read asset prices and indicators ==========================================
    # load prices of 28 currencies
    prices <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/",
                    trade_log_file = "AI_CP", 
                    time_period = PERIODS)
    
    # load macd indicator of 28 currencies
    macd <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/",
                    trade_log_file = "AI_Macd", 
                    time_period = PERIODS)
    
    # to be used for tests of demonstrations
    # prices <- read_rds("test_data/prices.rds")
    # macd <- read_rds("test_data/macd.rds")
    
    
    
    
    # performing Deep Learning Regression using the custom function
    self_learn_ai_R(price_dataset = prices,
                indicator_dataset = macd,
                num_bars = AHEAD,
                timeframe = PERIODS,
                research_mode = TRUE)

    
  }
  
}

h2o.shutdown(prompt = F)
#### End