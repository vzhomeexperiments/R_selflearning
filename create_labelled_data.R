## FUNCTION create_labelled_data
## PURPOSE: function gets price data in each column
## it is splitting this data by periods and transpose the data. 
## additionally it is label the data based on the simple logic assigning it to 2 categories based on the difference
## between beginning and end of the vector
## finally it is stacking all data and joining everything into the table 

## TEST:
# library(tidyverse)
# library(lubridate)
# pathT2 <- "C:/Program Files (x86)/FxPro - Terminal2/MQL4/Files/"
# prices <- read_csv(file.path(pathT2, "AI_CP1.csv"), col_names = F)
# prices$X1 <- ymd_hms(prices$X1)
# write_rds(prices, "test_data/prices.rds")

#' Create labelled data
#'
#' @param x - data set containing a table where 1st column is a Time index and other columns containing financial asset price values
#' @param n - number of rows we intend to split and transpose the data 
#' @param type - type of the label required. Can be either "classification" or "regression". "classification" will return either "BU" or "BE",
#' "regression" will return the difference between first value and the last value in each row
#'
#' @return function returns transposed data. One column called 'LABEL' indicate achieved value of the label.
#' Transposed values from every column are stacked one to each other
#' 
#' @export
#'
#' @examples
create_labelled_data <- function(x, n = 15, type = "classification"){
  require(tidyverse)
  #n <- 100
  #x <- read_rds(path = "test_data/prices.rds")
  #x <- read_rds("test_data/prices1.rds")
  #type <- "classification"
  #type <- "regression"
  #
  nr <- nrow(x)
  dat11 <- x %>% select(-1) %>% split(rep(1:ceiling(nr/n), each=n, length.out=nr)) #list
  
  # operations within the list
  for (i in 1:length(dat11)) {
    #i <- 1
    if(type == "classification"){
      
        # classify by 2 classes 'BU', 'BE'
        if(!exists("dfr12")){
          dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.data.frame() %>% mutate(LABEL = ifelse(.[[1]]>.[[n]], "BU", "BE"))} else {
            dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.tibble() %>% mutate(LABEL = ifelse(.[[1]]>.[[n]], "BU", "BE")) %>% 
              bind_rows(dfr12)
          }
    } else if(type == "regression"){
      # add label with numeric difference {in pips}
      if(!exists("dfr12")){
        dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.data.frame() %>% mutate(LABEL = 10000*(.[[1]]-.[[n]]))} else {
          dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.tibble() %>% mutate(LABEL = 10000*(.[[1]]-.[[n]])) %>% 
            bind_rows(dfr12)
        }
      
      
    }
  }
  
  return(dfr12)
  
}
