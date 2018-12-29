## read dat file into R
# use library
library(tidyverse)
# read binary file
base_buy <- readBin("test_data/Buy_Position8132102.dat",what = "double",n = 60000, endian = "little") %>% 
  # convert vector to matrix
  matrix(ncol = 6, byrow = TRUE) %>%
  # convert to dataframe
  as.data.frame()

nrow(base_buy)

base_buy$V6 <- as.factor(base_buy$V6)

## explore this data visually
# one vector over another one
ggplot(base_buy, aes(V1, V2, col = V6))+geom_point()
ggplot(base_buy, aes(V1, V3, col = V6))+geom_point()

# make this data as long format
base_buy_long <- base_buy %>% gather(key = "vector", value = "base_value", -V6)
# visualize it
ggplot(base_buy_long, aes(x = vector, y = base_value, col = V6))+geom_jitter()
# with facets
ggplot(base_buy_long, aes(x = vector, y = base_value, col = V6))+geom_jitter()+facet_grid(vector ~ .)
# probably better ones
ggplot(base_buy_long, aes(x = vector, y = base_value, col = V6))+geom_jitter()+facet_grid(.~ vector)
ggplot(base_buy_long, aes(x = vector, y = base_value, col = V6))+geom_jitter()+facet_grid(V6 ~ vector)


library(caret)

# Create index to split based on labels  
index <- createDataPartition(base_buy$V6, p=0.75, list=FALSE)

# Subset training set with index
d.training <- base_buy[index,]

# Subset test set with index
d.test <- base_buy[-index,]

# Train a model
model_knn <- train(x = d.training[ , 1:5],
                   y = d.training[ , 6],
                   method = 'knn')

# Predict the probabilities (newdata should come from new observations)
predict_prob <- predict(object = model_knn, type = "prob", newdata = d.test[,1:5])

# Predict the classes
predict_class <- predict(object = model_knn, type = "raw", newdata = d.test[,1:5])


# Evaluate the predictions
table(predict_class)

# Confusion matrix 
confusionMatrix(predict_class,d.test[,6])

