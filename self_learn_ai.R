## FUNCTION self_learn_ai, self_learn_ai_R
## PURPOSE: function gets price data, indicator data, number of predictors as input
## it is splitting this data by number or rows, transposes this data
## additionally it is labelling the data based on the simple logic assigning it to 2 categories based on the difference
## between beginning and end of the vector
## Then it is stacking all data and joining everything into the table
## Data is split to test and training datasets
## Labelled data is used to train deep learning model on training dataset
## Once model is trained it is 'back-tested' using test dataset
## In case Achieved PnL is > 0 and Achieved Quality is greater than 0.5 model will be saved for use
## more info is inside Udemy course Lazy Trading Part 7: Developing Self Learning Robot
## see function self_learn_ai_R -> is to handle regression problem

## NB: functions below must be available inside the R Environment!
# source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
# source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
# source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")

#' Title
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
self_learn_ai <- function(price_dataset, indicator_dataset, num_bars, timeframe){
  require(h2o)
  require(tidyverse)
  require(magrittr)
### use commented code below to test this function  
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
  # # load prices of 28 currencies
  # price_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_CP", time_period = 60)
  # # load macd indicator of 28 currencies
  # indicator_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_Macd", time_period = 60)
  # price_dataset <- read_rds("test_data/prices.rds")
  # indicator_dataset <- read_rds("test_data/macd.rds")
  # num_bars <- 100
  # timeframe <- 60 # indicates the timeframe used for training (e.g. 1 minute, 15 minutes, 60 minutes, etc)
  
# transform data and get the labels shift rows down
dat14 <- create_labelled_data(price_dataset, num_bars) %>% mutate_all(funs(lag), n=28) 
# transform data for indicator
dat15 <- create_transposed_data(indicator_dataset, num_bars) 
# dataframe for the DL modelling it contains all 
dat16 <- dat14 %>% select(LABEL) %>% bind_cols(dat15) %>% filter_all(any_vars(. != 0))%>% na.omit() %<>% mutate_at(1, as.factor) 

#library(plotly)
## Visualize new matrix in 3D
#plot_ly(z = as.matrix(dat16[,2:101]), type = "surface")

## ---------- Data Modelling  ---------------
h2o.init()

# load data into h2o environment
macd_ML  <- as.h2o(x = dat16, destination_frame = "macd_ML")
  
# fit models from simplest to more complex
ModelC <- h2o.deeplearning(
  model_id = paste0("DL_Classification", timeframe),
  x = names(macd_ML[,2:num_bars+1]), 
  y = "LABEL",
  training_frame = macd_ML,
  activation = "Tanh",
  overwrite_with_best_model = TRUE, 
  autoencoder = FALSE, 
  hidden = c(100,100), 
  loss = "Automatic",
  sparse = TRUE,
  l1 = 1e-4,
  distribution = "AUTO",
  stopping_metric = "AUTO",
  balance_classes = F,
  epochs = 100)

#ModelC
#summary(ModelC)
#h2o.performance(ModelC)

## Checking how the model predict using the latest dataset
# get the labelled data for the test
dat17 <- create_labelled_data(price_dataset, num_bars) %>% select(LABEL) %>% head(28)
# transform data for indicator and get the subset to predict
dat18 <- create_transposed_data(indicator_dataset, num_bars) %>% head(56) %>% tail(28) %>% 
  # need to add fake category to avoid h2o prediction function errors
  mutate(LABEL = "BU") %<>% 
  # same as data_latest$LABEL <- as.factor(data_latest$LABEL)
  mutate_at(num_bars+1, as.factor) 

# upload recent dataset to predict
recent_ML  <- as.h2o(x = dat18, destination_frame = "recent_ML")
# use model to 
result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame() %>% select(predict) %>% bind_cols(dat17) %>% 
  # compare predicted vs real
  mutate(MATCH = ifelse(predict==LABEL, 1, 0)) %>% 
  # count matches
  summarise(Quality = sum(MATCH)/28)

# save the model in case it's correctly predicting in more than 90% of the cases for the very last observation
if(result$Quality > 0.9){
  h2o.saveModel(ModelC, path = "model/", force = T)
}

h2o.shutdown(prompt = FALSE)



}



# function to handle regression
self_learn_ai_R <- function(price_dataset, indicator_dataset, num_bars, timeframe){
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
  # price_dataset <- read_rds("test_data/prices.rds")
  # indicator_dataset <- read_rds("test_data/macd.rds")
  # num_bars <- 100
  # timeframe <- 15 # indicates the timeframe used for training (e.g. 1 minute, 15 minutes, 60 minutes, etc)
  
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
  h2o.init()
  
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
  
  ## Checking how the model predict using the latest dataset
  # upload recent dataset to predict
  recent_ML  <- as.h2o(x = dat21[,-1], destination_frame = "recent_ML")
  # use model to predict
  result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame() %>% select(predict)
  
  ## evaluate hypothetical results of trading using the model
  # join real values with predicted values
  dat31 <- dat21 %>% select(LABEL) %>% bind_cols(result) %>% 
    # add column risk that has +1 if buy trade and -1 if sell trade
    mutate(Risk = if_else(predict > 0, 1, -1)) %>% 
    # calculate expected outcome of risking the 'Risk'
    mutate(ExpectedGain = predict*Risk) %>% 
    # calculate 'real' gain or loss
    mutate(AchievedGain = LABEL*Risk) %>% 
    ## uncomment to visualize
    #ggplot(aes(ExpectedGain, AchievedGain))+geom_point()
    # get the sum of both columns
    summarise(ExpectedPnL = sum(ExpectedGain),
              AchievedPnL = sum(AchievedGain)) %>% 
    # interpret the results
    mutate(FinalOutcome = if_else(AchievedPnL > 0, "VeryGood", "VeryBad"),
           FinalQuality = AchievedPnL/(0.0001+ExpectedPnL))
  
  # save the model in case it's good and Achieved is not much less than Expected!
  if(dat31$FinalOutcome == "VeryGood" && FinalQuality > 0.5){
    h2o.saveModel(ModelC, path = "model/", force = T)
  }
  
  h2o.shutdown(prompt = FALSE)
  
  
  
}










#### End