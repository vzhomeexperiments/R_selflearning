# 
#' Function to handle regression
#' https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
#' 
#' @param price_dataset 
#' @param indicator_dataset 
#' @param num_bars 
#' @param timeframe 
#'
#' @return
#' @export
#'
#' @examples
self_learn_ai_R <- function(price_dataset, indicator_dataset, num_bars, timeframe, research_mode = FALSE){
  require(h2o)
  require(tidyverse)
  ### use commented code below to test this function  
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
  # # load prices of 28 currencies
  # price_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_CP", time_period = 60)
  # # load macd indicator of 28 currencies
  # indicator_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_Macd", time_period = 60)
  # price_dataset <- read_rds("test_data/prices1.rds")
  # indicator_dataset <- read_rds("test_data/macd.rds")
  # num_bars <- 100
  # timeframe <- 1 # indicates the timeframe used for training (e.g. 1 minute, 15 minutes, 60 minutes, etc)
  
  # transform data and get the labels shift rows down
  dat14 <- create_labelled_data(price_dataset, num_bars, type = "regression") %>% mutate_all(funs(lag), n=28) 
  # transform data for indicator
  dat15 <- create_transposed_data(indicator_dataset, num_bars) 
  # dataframe for the DL modelling it contains all 
  dat16 <- dat14 %>% select(LABEL) %>% bind_cols(dat15) %>% na.omit() %>% filter_all(any_vars(. != 0))
  # split data to train and test blocks
  test_ind <- 1:round(0.3*(nrow(dat16)))
  dat21 <- dat16[test_ind, ]
  dat22 <- dat16[-test_ind,]
  
  #library(plotly)
  ## Visualize new matrix in 3D
  #plot_ly(z = as.matrix(dat16[,2:101]), type = "surface")
  
  ## ---------- Data Modelling  ---------------
  #h2o.init()
  
  # load data into h2o environment
  macd_ML  <- as.h2o(x = dat22, destination_frame = "macd_ML")
  
  # fit models from simplest to more complex
  ModelC <- h2o.deeplearning(
    model_id = paste0("DL_Regression", timeframe),
    x = names(macd_ML[,2:num_bars+1]), 
    y = "LABEL",
    training_frame = macd_ML,
    activation = "Tanh",
    overwrite_with_best_model = TRUE, 
    autoencoder = FALSE, 
    hidden = c(80,50,30,15,3), 
    loss = "Automatic",
    sparse = TRUE,
    l1 = 1e-4,
    distribution = "AUTO",
    stopping_metric = "MSE",
    #balance_classes = F,
    epochs = 100)
  
  #ModelC
  #summary(ModelC)
  #h2o.performance(ModelC)
  ## save model object for future reference
  #h2o.saveModel(ModelC, path = "test_data/model/", force = T)
  #write_rds(dat22, "test_data/model/train_Regr.rds")
  #write_rds(dat21, "test_data/model/test_Regr.rds")
  
  ## 
  # **** 
  ##
  
  # bringing test data
  # dat21 <- read_rds("test_data/model/test_Regr.rds")
  # ModelC <- h2o.loadModel("test_data/model/DL_Regression1")
  
  ## Checking how the model predict using the latest dataset
  # upload recent dataset to predict
  recent_ML  <- as.h2o(x = dat21[,-1], destination_frame = "recent_ML")
  # use model to predict
  result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame() %>% select(predict) %>% round()
  
  ## evaluate hypothetical results of trading using the model
  # join real values with predicted values
  dat31 <- dat21 %>% select(LABEL) %>% bind_cols(result) %>% 
    # add column risk that has +1 if buy trade and -1 if sell trade
    mutate(Risk = if_else(predict > 0, 1, if_else(predict == 0, 0, -1))) %>% 
    # calculate expected outcome of risking the 'Risk'
    mutate(ExpectedGain = predict*Risk) %>% 
    # calculate 'real' gain or loss
    mutate(AchievedGain = LABEL*Risk) %>% 
    # get the sum of both columns
    summarise(ExpectedPnL = sum(ExpectedGain),
              AchievedPnL = sum(AchievedGain)) %>% 
    # interpret the results
    mutate(FinalOutcome = if_else(AchievedPnL > 0, "VeryGood", "VeryBad"),
           FinalQuality = AchievedPnL/(0.0001+ExpectedPnL))
  
  # write the final object dat31 to the file for debugging or even for production
  if(research_mode == TRUE){
    # generate unique hash to be added to the object
    require(openssl)
    hash <- Sys.Date() %>% as.character.POSIXt() %>% sha1()
    write_rds(dat31, paste0("RESEARCH/", hash, "-Result-", num_bars, "-", timeframe, ".rds"))}
  
  
  # save the model in case it's good and Achieved is not much less than Expected!
  if(dat31$FinalOutcome == "VeryGood" && dat31$FinalQuality > 0.5){
    h2o.saveModel(ModelC, path = "model/", force = T)
  }
  
  #h2o.shutdown(prompt = FALSE)
  
  
  
  
}










#### End