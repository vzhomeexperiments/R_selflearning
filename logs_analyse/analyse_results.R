# 20190208 - Analysing Twitter Sentiment Model results predicting #TeslaMotors stock

library(tidyverse)
library(lubridate)

## read files with predicted price changes
# file names
filesToAnalyse <-list.files("C:/Users/fxtrams/Google Drive/Udemy/C7/logs_predictions",
                            pattern = "AI_M60_ChangeEURUSD-log.csv",
                            full.names=TRUE)

      # remove the left part of the string
        Period <- str_remove(filesToAnalyse, 
                               pattern = "C:/Users/fxtrams/Google Drive/Udemy/C7/logs_predictions/AI_M")
      # remove the right part .csv
        Period <- Period %>% str_remove(pattern = '_ChangeEURUSD-log.csv')
      
      # read content of the file
        prediction <- read_csv(file = filesToAnalyse, col_types = 'nc',col_names = F)
        
        prediction$X2 <- ymd_hms(prediction$X2)
     
        

# plot results
ggplot(prediction, aes(x = X2, y = X1)) + geom_line()

# get real prices

# read data for comparing
path_repository <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
prices <- read_csv(file.path(path_repository, "AI_CP60-12000.csv"), col_names = F) %>% select(1,2)
prices$X1 <- ymd_hms(prices$X1)


## join predicted to real prices
joined_df1 <- prediction %>% inner_join(prices,by = c("X1" = "X2"))

# visualize together
ggplot(joined_df1, aes(x = DateTimeR, y = X2, col = Type_price))+geom_line()

# visualize at facets
ggplot(joined_df1, aes(x = DateTimeR, y = X2, col = Type_price))+
  geom_line()+
  facet_grid(Type_price ~ .)


