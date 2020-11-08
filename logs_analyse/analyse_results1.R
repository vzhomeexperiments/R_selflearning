# 20200913 - Analysing Model Testing results

library(ggplot2)
library(magrittr)

## read files with predicted price changes

#path to user repo:
#!!!Change this path!!! 
path_user <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning"

#path to store logs data (e.g. duration of machine learning steps)
path_logs <- file.path(path_user, "_MODELS")

# file names
filesToAnalyse <-list.files(path = path_logs,
                            pattern = "StrTestFull--",
                            full.names=TRUE)

# aggregate all files into one
for (VAR in filesToAnalyse) {
    # VAR <- filesToAnalyse[1]
  if(!exists("dfres")){dfres <- readr::read_rds(VAR)}  else {
    dfres <- readr::read_rds(VAR) %>% dplyr::bind_rows(dfres)
  }
  
}

# visualized
ggplot(dfres, aes(x = NB_hold, y = PnL_NB,
              #size = TotalTrades, 
              col = as.factor(Symbol)))+geom_point()+
  ggtitle("Strategy Test results")


## Analysis of model quality records
# file names
filesToAnalyse1 <-list.files(path = path_logs,
                            pattern = "StrTest-",
                            full.names=TRUE)

# aggregate all files into one
for (VAR in filesToAnalyse1) {
  # VAR <- filesToAnalyse1[1]
  if(!exists("dfres1")){dfres1 <- readr::read_csv(VAR)}  else {
    dfres1 <- readr::read_csv(VAR) %>% dplyr::bind_rows(dfres1)
  }
  
}

# visualized
ggplot(dfres1, aes(x = MaxPerf, y = Symbol,
                  col = TR_Level, 
                  size = NB_hold))+geom_point()+
                  geom_vline(xintercept=0.001)+ 
                  scale_x_continuous()+
  ggtitle("Model Performance")
                  #scale_x_continuous(trans='log10')+
  #ggtitle("Model Performance", "x axis at log 10 scale")
