# 20200913 - Analysing Model Testing results

library(ggplot2)

## read files with predicted price changes
# path
path_logs <- "C:/Users/fxtrams/Documents/000_TradingRepo/R_selflearning/_MODELS"
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
              col = as.factor(Symbol)))+geom_point()

