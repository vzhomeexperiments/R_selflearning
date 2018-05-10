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

create_labelled_data <- function(x, n = 15, type = "classification"){
  #n <- 100
  #x <- read_rds(path = "test_data/prices.rds")
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
      # add label with numeric difference
      if(!exists("dfr12")){
        dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.data.frame() %>% mutate(LABEL = .[[1]]-.[[n]])} else {
          dfr12 <- dat11[i] %>% as.data.frame() %>% t() %>% as.tibble() %>% mutate(LABEL = .[[1]]-.[[n]]) %>% 
            bind_rows(dfr12)
        }
      
      
    }
  }
  
  return(dfr12)
  
}
