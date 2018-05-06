# import data function
# (C) 2018 Vladimir Zhbanko
# -------------------------
# Import Data to R
# -------------------------
# Function imports file and change data column type
# Function return the dataframe with trade data

load_data <- function(path_terminal, trade_log_file, time_period = 1){
  # path_terminal <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
  # trade_log_file <- "OrdersResultsT4.csv"
  require(tidyverse)
  require(lubridate)
  DFT1 <- try(read_csv(file = file.path(path_terminal, paste0(trade_log_file, time_period, ".csv")),
                       col_names = F),
              silent = TRUE)
  if(class(DFT1)[1] == "try-error") {stop("Error reading file. File with trades may not exist yet!",
                                       call. = FALSE)}
  if(!nrow(DFT1)==0){
    # data frame preparation
    DFT1$X1 <- ymd_hms(DFT1$X1)
    
    return(DFT1)
  } else {
    stop("Data log is empty!",
         call. = FALSE)
    }

}