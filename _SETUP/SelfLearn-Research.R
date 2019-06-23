# ----------------------------------------------------------------------------------------
# R Script to Find the best possible strategy of using Self-learning algorithms
# ----------------------------------------------------------------------------------------
# (C) 2019 Vladimir Zhbanko
# https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
# Script to gather financial data, transform it and to perform
# Supervised Deep Learning Regression Modelling
# ***
# Purpose of this script is to simulate results in the several possible variants
# NOTE: delete all previously create models from the folder R_selflearning/model after updating h2o engine
# ***
# load libraries to use and custom functions
library(tidyverse)
library(h2o)
library(lubridate)
library(magrittr)
#library(plotly)
library(lazytrade)
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/load_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/create_labelled_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/create_transposed_data.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/self_learn_ai_R.R")
#source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_FUN/test_model.R")

#absolute path to store model objects
path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_MODELS"

#absolute path with the data (choose either MT4 directory or a '_TEST_DATA' folder)
path_data <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
#path_data <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_TEST_DATA/"

# start h2o engine (using all CPU's by default)
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
    if(PERIODS == 1) {file_bars <- "50000"}
    if(PERIODS == 15) {file_bars <-"35000"}
    if(PERIODS == 60) {file_bars <-"12000"}
    prices <- load_asset_data(path_terminal = path_data,
                    trade_log_file = "AI_CP", 
                    time_period = PERIODS,
                    data_deepth = file_bars)
    
    # load macd indicator of 28 currencies
    macd <- load_asset_data(path_terminal = path_data,
                    trade_log_file = "AI_Macd", 
                    time_period = PERIODS,
                    data_deepth = file_bars)
    
    # performing Deep Learning Regression using the custom function
    self_learn_ai_R(price_dataset = prices,
                    indicator_dataset = macd,
                    num_bars = AHEAD,
                    timeframe = PERIODS,
                    path_model = path_model,
                    setup_mode = TRUE,
                    research_mode = TRUE,
                    write_log = TRUE)

    
  }
  
}

h2o.shutdown(prompt = F)

## combine the achieved outcomes?
# gather all files
files_to_analyse <-list.files(file.path(getwd(),"_SETUP/"), pattern="*.rds", full.names=TRUE) 
# extract numbers from the file name using regular expressions
# e.g.: str_extract(files_to_analyse[2], "(?<=Result-)(.*)(?=.rds)")
# 
for (FILE in files_to_analyse) {
  #FILE <- files_to_analyse[3]
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
write_rds(best2, file.path(getwd(),"_SETUP/BestParameters.rds"))


#### End