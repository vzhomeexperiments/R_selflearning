# 
#' Function to handle regression
#' https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10
#' 
#' Self-learning function. Function will use price and indicator datasets. Goal of the function is to create deep learning
#' model trained to predict future state of the label. Function will also check how the model predict by using trading 
#' objective.
#' 
#' Because of the function is intended to periodically re-train the model it would always check how the previous model was working.
#' In case new model is better, the better model will be used.
#' NOTE: Always run parameter research_mode = TRUE for the first time
#' 
#' Function can also write a log files with a results of the strategy test
#' 
#' @param price_dataset       Dataset containing assets prices. It will be used as a label
#' @param indicator_dataset   Dataset containing assets indicator which pattern will be used as predictor
#' @param num_bars            Number of bars used to detect pattern
#' @param timeframe           Data timeframe e.g. 1 min
#' @param research_mode       When TRUE model will be saved and model result will be stored as well
#' @param path_model          Path where the models are be stored
#' @param write_log           Writes results of the newly trained model and previously used model to the file
#'
#' @return
#' @export
#'
#' @examples
self_learn_ai_R <- function(price_dataset, indicator_dataset, num_bars, timeframe, research_mode = FALSE, path_model,
                            write_log = TRUE){
  require(h2o)
  require(tidyverse)
  ### use commented code below to test this function  
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
  # # load prices of 28 currencies
  # price_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_CP", time_period = 1)
  # # load macd indicator of 28 currencies
  # indicator_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_Macd", time_period = 1)
  # price_dataset <- read_rds("test_data/prices1.rds")
  # indicator_dataset <- read_rds("test_data/macd.rds")
  # num_bars <- 75
  # timeframe <- 1 # indicates the timeframe used for training (e.g. 1 minute, 15 minutes, 60 minutes, etc)
  # path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/model"
  # write_log = TRUE
  
  # transform data and get the labels shift rows down
  dat14 <- create_labelled_data(price_dataset, num_bars, type = "regression") %>% mutate_all(funs(lag), n=28) 
  # transform data for indicator
  dat15 <- create_transposed_data(indicator_dataset, num_bars) 
  # dataframe for the DL modelling it contains all 
  dat16 <- dat14 %>% select(LABEL) %>% bind_cols(dat15) %>% na.omit() %>% filter_all(any_vars(. != 0))
  # # split data to train and test blocks [code before 20180616]
  # test_ind <- 1:round(0.3*(nrow(dat16)))
  # dat21 <- dat16[test_ind, ]
  # dat22 <- dat16[-test_ind,]
  # split data to train and test blocks
  train_ind <- 1:round(0.7*(nrow(dat16))) #train indices 1:xxx
  dat21 <- dat16[-train_ind, ] #dataset to test the model
  dat22 <- dat16[train_ind,]   #dataset to train the model
  
  #library(plotly)
  ## Visualize new matrix in 3D
  #plot_ly(z = as.matrix(dat16[,2:101]), type = "surface")
  
  ## ---------- Data Modelling  ---------------
  #h2o.init()
  
  # load data into h2o environment
  macd_ML  <- as.h2o(x = dat22, destination_frame = "macd_ML")
  
  # fit models from simplest to more complex
  ModelC <- h2o.deeplearning(
    model_id = paste0("DL_Regression", num_bars, "-", timeframe),
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
    epochs = 300)
  
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

## ------ //added after 1st week of testing// -------------  
### Test existing model with new data to compare both results and keep the better model for production
  # check existence of the model trained previously and if exist, load it and test strategy using it
  ModelC_prev <- try(h2o.loadModel(paste0(path_model, "/DL_Regression",
                                      num_bars, "-", timeframe)),silent = T)
  if(!class(ModelC_prev)=='try-error'){
    # result prev
    result_prev <- h2o.predict(ModelC_prev, recent_ML) %>% as.data.frame() %>% select(predict) %>% round()
      
    ## evaluate hypothetical results of trading using the model
    # join real values with predicted values
    dat31_prev <- dat21 %>% select(LABEL) %>% bind_cols(result_prev) %>% 
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
    
    
    
    
  }
  
  # write the final object dat31 to the file for debugging or research
  if(research_mode == TRUE){
    # In research mode we will write results to the new folder
    write_rds(dat31, paste0("RESEARCH/", Sys.Date(), "-Result-", num_bars, "-", timeframe, ".rds"))
    h2o.saveModel(ModelC, path = path_model, force = T)
    }
  

  # save the model in case it's good and Achieved is not much less than Expected!
  if(research_mode == FALSE && dat31$FinalOutcome == "VeryGood" && 
     #condition OR will also overwrite the model in case previously made model is performing worse than the new one
     (dat31$FinalQuality > 0.8 || dat31$FinalQuality > dat31_prev$FinalQuality)){
  h2o.saveModel(ModelC, path = path_model, force = T)
  }
  
  
  # write logs if enabled
  if(write_log == TRUE){
    # create folder where to save if not exists
    path_LOG <- paste0(path_model, "/LOG/")
    if(!dir.exists(path_LOG)){dir.create(path_LOG)}
    # combine data and join them to one object
    dat61 <- dat31 %>% mutate(new_or_old = "NEW", num_bars = num_bars, timeframe = timeframe, model_type = "R")
    dat62 <- dat31_prev %>% mutate(new_or_old = "PREV", num_bars = num_bars, timeframe = timeframe, model_type = "R")
    bind_rows(dat61, dat62) %>% 
    # write combined data to the file named with current date
    write_csv(path = paste0(path_LOG, Sys.Date(), "-", num_bars, "-",timeframe, "R", ".csv"))
    
    
  }
  
  #h2o.shutdown(prompt = FALSE)
  
  
  
  
}










#### End