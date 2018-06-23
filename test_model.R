#' Test model function. Goal of the function is to verify how good predicted results are.
#' 
#' This function should work to backtest any possible dataset lenght. It could be that we will need to use it for testing
#' 1 week or 1 month. It should also work for both Regression and Classification models. Note: strategy outcomes assumes trading on
#' all 28 major forex pairs
#' 
#' 
#' @param test_dataset      Dataset containing the column 'LABEL' which will correspond to the real outcome of Asset price change. This 
#' column will be used to verify the trading strategy
#' @param predictor_dataset  Dataset containing the column 'predict'. This column is corresponding to the predicted outcome of Asset 
#'       change. This column will be used to verify strategy outcomes
#' @param test_type can be either "regression" or "classification" used to distinguish which type of modelling is being used
#'
#' @return Function will return a data frame with model quality score. In case this score is positive or more than 1 the model would likely 
#'         be working good. In case the score will be negative then the model is not predicting good
#' @export
#'
#' @examples
#' 
test_model <- function(test_dataset, predictor_dataset, test_type){
  require(tidyverse)
  # arguments for debugging for regression
  # test_dataset <- read_rds("test_data/dat21.rds")    
  # predictor_dataset <- read_rds("test_data/result_prev.rds")
  # test_type <- "regression"
  
  # arguments for debugging for classification
  # test_dataset <- read_rds("test_data/test_dataset_c.rds")
  # predictor_dataset <- read_rds("test_data/pred_dataset_c.rds")
  # test_type <- "classification"
  
  if(test_type == "regression"){
## evaluate hypothetical results of trading using the model
# join real values with predicted values
dat31 <- test_dataset %>% select(LABEL) %>% bind_cols(predictor_dataset) %>% 
  # add column risk that has +1 if buy trade and -1 if sell trade, 0 (no risk) if prediction is exact zero
  mutate(Risk = if_else(predict > 0, 1, if_else(predict < 0, -1, 0))) %>% 
  # calculate expected outcome of risking the 'Risk': trade according to prediction
  mutate(ExpectedGain = predict*Risk) %>% 
  # calculate 'real' gain or loss. LABEL is how the price moved (ground truth) so the column will be real outcome
  mutate(AchievedGain = LABEL*Risk) %>% 
  # get the sum of both columns
  # Column Expected PNL would be the result in case all trades would be successful
  # Column Achieved PNL is the results achieved in reality
  summarise(ExpectedPnL = sum(ExpectedGain),
            AchievedPnL = sum(AchievedGain)) %>% 
  # interpret the results
  mutate(FinalOutcome = if_else(AchievedPnL > 0, "VeryGood", "VeryBad"),
         FinalQuality = AchievedPnL/(0.0001+ExpectedPnL)) 

}

  if(test_type == "classification"){

    dat31 <-  predictor_dataset %>% bind_cols(test_dataset) %>% 
      # generate column of estimated risk trusting the model
      mutate(RiskEstim = if_else(predict == "BU", 1, -1)) %>%
      # generate colmn of 'known' direction
      mutate(RiskKnown = if_else(LABEL > 0, 1, if_else(LABEL < 0, -1, 0))) %>% 
      # calculate expected outcome of risking the 'RiskEst'
      mutate(AchievedGain = RiskEstim*LABEL) %>% 
      # calculate 'real' gain or loss
      mutate(ExpectedGain = RiskKnown*LABEL) %>% 
      # get the sum of both columns
      summarise(ExpectedPnL = sum(ExpectedGain),
                AchievedPnL = sum(AchievedGain)) %>% 
      # interpret the results
      mutate(FinalOutcome = if_else(AchievedPnL > 0, "VeryGood", "VeryBad"),
             FinalQuality = AchievedPnL/(0.0001+ExpectedPnL))
    
  }
  
return(dat31)



}