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
# source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/test_model.R")


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
#' @param price_dataset 
#' @param indicator_dataset 
#' @param num_bars 
#' @param timeframe 
#' @param path_model
#' @param write_log
#' @param research_mode 
#'
#' @return
#' @export
#'
#' @examples
self_learn_ai <- function(price_dataset, indicator_dataset, num_bars, timeframe, research_mode = FALSE,path_model,
                          write_log = TRUE){
  require(h2o)
  require(tidyverse)
  require(magrittr)
### use commented code below to test this function  
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_labelled_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/create_transposed_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/load_data.R")
  # source("C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/test_model.R")
  # # load prices of 28 currencies
  # price_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_CP", time_period = 60, data_deepth = 12000)
  # # load macd indicator of 28 currencies
  # indicator_dataset <- load_data(path_terminal = "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/", trade_log_file = "AI_Macd", time_period = 60, data_deepth = 12000)
  # price_dataset <- read_rds("test_data/prices1.rds")
  # indicator_dataset <- read_rds("test_data/macd.rds")
  # num_bars <- 100
  # timeframe <- 60 # indicates the timeframe used for training (e.g. 1 minute, 15 minutes, 60 minutes, etc)
  # path_model <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/model"
  # write_log = TRUE
  
# transform data and get the labels shift rows down
dat51 <-  create_labelled_data(price_dataset, num_bars, type = "regression") %>% mutate_all(funs(lag), n=28) %>% na.omit() %>% 
  select(LABEL)#will be used for testing the strategy. Note: the oldest data in the first row!!
# checking how much the label is balanced (research only)
dat61 <- dat51 %>% summarise(positives = sum(LABEL > 0),
                             negatives = sum(LABEL < 0),
                             zeroes    = sum(LABEL == 0)) # zeroes are due to absence of data by the broker
dat14 <- create_labelled_data(price_dataset, num_bars, type = "classification") %>% mutate_all(funs(lag), n=28) 
# transform data for indicator
dat15 <- create_transposed_data(indicator_dataset, num_bars) 
# dataframe for the DL modelling it contains all 
dat16 <- dat14 %>% select(LABEL) %>% bind_cols(dat15) %>% filter_all(any_vars(. != 0))%>% na.omit() %<>% mutate_at(1, as.factor) 
# split data to train and test blocks
train_ind <- 1:round(0.7*(nrow(dat16))) #train indices 1:xxx
dat21 <- dat16[-train_ind, ] #dataset to test the model
dat22 <- dat16[train_ind,]   #dataset to train the model
dat52 <- dat51[-train_ind, ] #dataset with price label for model test
#library(plotly)
## Visualize new matrix in 3D
#plot_ly(z = as.matrix(dat16[,2:76]), type = "surface")

## ---------- Data Modelling  ---------------
#h2o.init()

# load data into h2o environment
macd_ML  <- as.h2o(x = dat22, destination_frame = "macd_ML")
  
# fit models from simplest to more complex
ModelC <- h2o.deeplearning(
  model_id = paste0("DL_Classification",  num_bars, "-", timeframe),
  x = names(macd_ML[,2:num_bars+1]), 
  y = "LABEL",
  training_frame = macd_ML,
  activation = "Tanh",
  overwrite_with_best_model = TRUE, 
  autoencoder = FALSE, 
  hidden = c(80,50,30,15,5), 
  loss = "Automatic",
  sparse = TRUE,
  l1 = 1e-4,
  distribution = "AUTO",
  stopping_metric = "AUTO",
  balance_classes = F, #trial to improve models performance 2018-06-12 (F is better)
  epochs = 300)

#ModelC
#summary(ModelC)
#h2o.performance(ModelC)
## save model object for future reference
#h2o.saveModel(ModelC, path = "test_data/model/", force = T)
#write_rds(dat22, "test_data/model/train_Classif.rds")
#write_rds(dat21, "test_data/model/test_Classif.rds")


### Testing this Model 
# this dataset will contain test observations not used for model training
# we have to artificially create new column with fake name otherwise h2o gives an error
dat41 <- dat21 %>%  mutate(LABEL = "BU") %<>% 
  # same as data_latest$LABEL <- as.factor(data_latest$LABEL)
  mutate_at(1, as.factor) 

# upload recent dataset to h2o for predictions
recent_ML  <- as.h2o(x = dat41, destination_frame = "recent_ML")
# use model to create predictions
result <- h2o.predict(ModelC, recent_ML) %>% as.data.frame() %>% select(predict)

# test the model
dat91 <- test_model(test_dataset = dat52, predictor_dataset = result, test_type = "classification")


## ------ //added after 1st week of testing// -------------
### Test existing model with new data to compare both results and keep the better model for production
# load model
ModelC_prev <- try(h2o.loadModel(paste0(path_model, "/DL_Classification",
                                    num_bars, "-", timeframe)),silent = TRUE)

if(!class(ModelC_prev)=='try-error'){

  # result prev
  result_prev <- h2o.predict(ModelC_prev, recent_ML) %>% as.data.frame() %>% select(predict) 
  
  # test the previous model
  dat92 <- test_model(test_dataset = dat52, predictor_dataset = result_prev, test_type = "classification")
  
}

# write the final object dat31 to the file for debugging or research
if(research_mode == TRUE){
  # In research mode we will write results to the new folder
  write_rds(dat91, paste0("RESEARCH/", Sys.Date(), "-ResultC-", num_bars, "-", timeframe, ".rds"))
  h2o.saveModel(ModelC, path = path_model, force = T)
}

# save the model in case it's good and Achieved is not much less than Expected!
if(research_mode == FALSE && dat91$FinalOutcome == "VeryGood" && 
   #condition OR will also overwrite the model in case previously made model is performing worse than the new one
   (dat91$FinalQuality > 0.9 || dat91$FinalQuality > dat92$FinalQuality)){ 
  h2o.saveModel(ModelC, path = path_model, force = T)
}

# write logs if enabled
if(write_log == TRUE){
  # create folder where to save if not exists
  path_LOG <- paste0(path_model, "/LOG/")
  if(!dir.exists(path_LOG)){dir.create(path_LOG)}
  # combine data and join them to one object
  dat61 <- dat91 %>% mutate(new_or_old = "NEW", num_bars = num_bars, timeframe = timeframe, model_type = "C")
  dat62 <- dat92 %>% mutate(new_or_old = "PREV", num_bars = num_bars, timeframe = timeframe, model_type = "C")
  bind_rows(dat61, dat62) %>% 
    # write combined data to the file named with current date
    write_csv(path = paste0(path_LOG, Sys.Date(),"-",num_bars, "-", timeframe, "C", ".csv"))
  
  
}
#h2o.shutdown(prompt = FALSE)



}

