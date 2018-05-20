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
options_predict_ahead <- c(75, 100, 125) # must be more than 50
options_time_periodicity <- c(1, 15, 60) # only periods corresponding to the active files in the sandbox

for (AHEAD in options_predict_ahead) {
  # AHEAD <- 75
  for (PERIODS in options_time_periodicity) {
    #PERIODS <- 1
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

## combine the achieved outcomes?
# gather all files
files_to_analyse <-list.files(file.path(getwd(),"RESEARCH/"), pattern="*.rds", full.names=TRUE) 
# extract numbers from the file name using regular expressions
# e.g.: str_extract(files_to_analyse[2], "(?<=Result-)(.*)(?=.rds)")
# 
for (FILE in files_to_analyse) {
  #extract nbars from the file name, note we use only those of the latest date
  num_bars <- FILE %>% str_extract(paste0("(?<=",Sys.Date(),"-Result-)(.*)(?=.rds)"))
  if(!exists("summary_file")){
    summary_file <- read_rds(FILE) %>% mutate(Category = num_bars)
  } else {
    summary_file <- read_rds(FILE) %>% mutate(Category = num_bars) %>% bind_rows(summary_file)
  }
  
}

# select the best outcomes
best1 <- summary_file %>% separate(Category, c("PredictAhead", "Timeframe"),sep = "-", convert = TRUE)
# create graph
# best1 %>% ggplot(aes(x = Timeframe, y = PredictAhead, size= FinalQuality)) + geom_point()
# output the best result for each timeframe
best2 <- best1 %>% group_by(Timeframe) %>% filter(FinalQuality == max(FinalQuality))
  
# write the current outcome to the Folder
write_rds(best2, file.path(getwd(),"model/BestParameters.rds"))


#### End