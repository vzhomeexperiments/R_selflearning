# ----------------------------------------------------------------------------------------
# R Script to collect (aggregate) the asset indicator data and respective prices
# ----------------------------------------------------------------------------------------
# (C) 2020 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# load libraries to use and custom functions
 library(dplyr)
 library(readr)
 library(lubridate)
 library(lazytrade)
 library(magrittr)


#### Read asset prices and indicators ==========================================
#absolute path with the data (choose MT4 directory where files are generated)
path_terminal <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"

#path to user repo:
#!!!Change this path!!! 
path_user <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning"

#path with the data
path_data <- file.path(path_user, "_DATA")

# Vector of currency pairs used
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

# Writing indicator and price change to the file
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
# performing data collection
ind = file.path(path_terminal, paste0("AI_RSIADX",PAIR,"60",".csv")) %>% read_csv(col_names = FALSE)
ind$X1 <- ymd_hms(ind$X1)  
  
# data transformation using the custom function for one symbol
aml_collect_data(indicator_dataset = ind,
                 symbol = PAIR,
                 timeframe = 60,
                 path_data = path_data)
  
 #full_path <- file.path(path_data, 'AI_RSIADXEURUSD60.rds')
   
 #x1 <- read_rds(full_path)
  
}

# outcome is series of files written to the _DATA folder of the repository


