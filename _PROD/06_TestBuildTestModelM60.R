# ----------------------------------------------------------------------------------------
# R Script to build or update Deep Learning model for every Currency Pair
# ----------------------------------------------------------------------------------------
# (C) 2019,2021 Vladimir Zhbanko
# https://www.udemy.com/course/self-learning-trading-robot/?referralCode=B95FC127BA32DA5298F4
#
# load libraries to use and custom functions
library(dplyr)
library(readr)
library(h2o)
library(lazytrade)
library(magrittr)
library(lubridate)

#path to user repo:
#!!!Setup Environmental Variables!!! 
path_user <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')
path_user <- file.path(path_user, "R_selflearning")

#### Read asset prices and indicators ==========================================

#absolute path with the data
path_data <- file.path(path_user, "_DATA")

# Vector of currency pairs
Pairs = c("EURUSD", "GBPUSD", "AUDUSD", "NZDUSD", "USDCAD", "USDCHF", "USDJPY",
          "EURGBP", "EURJPY", "EURCHF", "EURNZD", "EURCAD", "EURAUD", "GBPAUD",
          "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "AUDCAD", "AUDCHF", "AUDJPY",
          "AUDNZD", "CADJPY", "CHFJPY", "NZDJPY", "NZDCAD", "NZDCHF", "CADCHF")  
#absolute path to store model objects (useful when scheduling tasks)
path_model <- file.path(path_user, "_MODELS")

#path to store logs data (e.g. duration of machine learning steps)
path_logs <- file.path(path_user, "_LOGS")

path_sbxm <- normalizePath(Sys.getenv('PATH_T1'), winslash = '/')
path_sbxs <- normalizePath(Sys.getenv('PATH_T3'), winslash = '/')

#copy file with tick size info
file.copy(from = file.path(path_sbxm, "TickSize_AI_RSIADX.csv"),
          to = file.path(path_data, "TickSize_AI_RSIADX.csv"),
          overwrite = TRUE)

#record time when the script starts to run
time_start <- Sys.time()

h2o.init()

# Performing Testing => Building -> Testing...
for (PAIR in Pairs) {
  ## PAIR <- "EURUSD"

# repeat testing and training several times  

  aml_test_model(symbol = PAIR,
                 num_bars = 600,
                 timeframe = 60,
                 path_model = path_model,
                 path_data = path_data,
                 path_sbxm = path_sbxm,
                 path_sbxs = path_sbxs)  
  
aml_make_model(symbol = PAIR,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               force_update=FALSE,
               objective_test = TRUE,
               num_epoch = 100,
               num_nn_options = 24,
               num_bars_test = 600,
               num_bars_ahead = 34,
               num_cols_used = 16,
               min_perf = 100000)

aml_test_model(symbol = PAIR,
               num_bars = 600,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)  

aml_make_model(symbol = PAIR,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               force_update=FALSE,
               objective_test = TRUE,
               num_epoch = 100,
               num_nn_options = 24,
               num_bars_test = 600,
               num_bars_ahead = 34,
               num_cols_used = 16,
               min_perf = 50000)

aml_test_model(symbol = PAIR,
               num_bars = 600,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)  

aml_make_model(symbol = PAIR,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               force_update=FALSE,
               objective_test = TRUE,
               num_epoch = 100,
               num_nn_options = 24,
               num_bars_test = 600,
               num_bars_ahead = 34,
               num_cols_used = 16,
               min_perf = 10000)

aml_test_model(symbol = PAIR,
               num_bars = 600,
               timeframe = 60,
               path_model = path_model,
               path_data = path_data,
               path_sbxm = path_sbxm,
               path_sbxs = path_sbxs)  

}  
  
 # stop h2o engine
h2o.shutdown(prompt = F)

#record time when the script ended to run
time_end <- Sys.time()
#calculate total time difference in seconds
time_total <- difftime(time_end,time_start,units="sec")
#convert to numeric
as.double(time_total)

# extract number of rows in the datasets
x <- read_rds(file.path(path_data, "AI_RSIADXEURUSD60.rds"))
n_rows_x <- nrow(x)

#setup a log dataframe
logs <- data.frame(dtm = Sys.time(), time2run = time_total, nrows = n_rows_x)

#read existing log (if exists) and add there a new log data
if(!file.exists(file.path(path_logs, 'time_executeM60.rds'))){
  write_rds(logs, file.path(path_logs, 'time_executeM60.rds'))
} else {
  read_rds(file.path(path_logs, 'time_executeM60.rds')) %>% 
    bind_rows(logs) %>% 
    write_rds(file.path(path_logs, 'time_executeM60.rds'))
}

# outcome are the models files for each currency pair written to the folder /_MODELS

## ================
# analyse StrTestFiles to automatically define min model quality value 
## Analysis of model quality records
# file names
filesToAnalyse1 <-list.files(path = path_model,
                             pattern = "StrTest-",
                             full.names=TRUE)


# aggregate all files into one
for (VAR in filesToAnalyse1) {
  # VAR <- filesToAnalyse1[1]
  if(!exists("dfres1")){dfres1 <- readr::read_csv(VAR)}  else {
    dfres1 <- readr::read_csv(VAR) %>% dplyr::bind_rows(dfres1)
  }
  
}

# find the 1st quantile by sampling 25% of the data see ?quantile
df <- dfres1 %>% 
  dplyr::mutate(qrtl = quantile(MaxPerf, 0.25)) %>% 
  head(1) %$% qrtl %>% as_tibble() %>% rename(FrstQntlPerf = value)
  

# write the value of the 1st quantile into all files
timeframe <- 60
# 
for (VAR in filesToAnalyse1) {
  # VAR <- filesToAnalyse1[1]
  readr::read_csv(VAR) %>% dplyr::bind_cols(df) %>% readr::write_csv(VAR)
  }

# also move these files to sandboxes of the trading terminals
for (PAIR in Pairs) {
  #PAIR <- 'EURUSD'
  #timeframe <- 60
  file.copy(from = file.path(path_model, paste0('StrTest-', PAIR,"M",timeframe, ".csv")),
            to = file.path(path_sbxm, paste0('StrTest-', PAIR,"M",timeframe, ".csv")),
            overwrite = TRUE)
  
  file.copy(from = file.path(path_model, paste0('StrTest-', PAIR,"M",timeframe, ".csv")),
            to = file.path(path_sbxs, paste0('StrTest-', PAIR,"M",timeframe, ".csv")),
            overwrite = TRUE)
}

#set delay to insure h2o unit closes properly
Sys.sleep(5)

