# ----------------------------------------------------------------------------------------
# R Script to score the latest asset indicator against Deep Learning model
# ----------------------------------------------------------------------------------------
# (C) 2018 Vladimir Zhbanko
# https://www.udemy.com/draft/1482480/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to predict
# with Deep Learning Classification Model
#
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)

#### Read asset prices and indicators ==========================================
# load prices of 28 currencies
pathT2 <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
# load macd indicator of 28 currencies
macd <- read_csv(file.path(pathT2, "AI_Macd1.csv"), col_names = F)

# to be used for tests of demonstrations
# macd <- read_rds("test_data/macd.rds")

# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")   

### Indicator values for the last 15 minutes values
data_latest <- macd %>% head(15) %>% select(-1) %>% t() %>% as.tibble() %>% 
  # need to add fake category to avoid h2o prediction function errors
  mutate(LABEL = "BU") %<>% 
  # same as data_latest$LABEL <- as.factor(data_latest$LABEL)
  mutate_at(16, as.factor) 

# initialize the virtual machine
h2o.init(nthreads = 2)

ModelC <- h2o.loadModel(path = "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/model/DL_Classification")

recent_ML  <- as.h2o(x = data_latest, destination_frame = "recent_ML")

## PREDICT current market...
result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame()

h2o.shutdown(prompt = F)


# Rename the rownames
rownames(result) <- Pairs

# test for all columns
for (PAIR in Pairs) {
  # PAIR <- "EURUSD"
  # filter by row and select prediction
  df <- result %>% filter(row.names(result) %in% PAIR) %>% select(predict)
  # name the column with pair name
  names(df) <- PAIR
  # write to the files
  write_csv(df, file.path(pathT2, paste0("AI_M15_Direction", PAIR, ".csv")))
}


# outcome is series of files written to the sandboxes of each terminals


