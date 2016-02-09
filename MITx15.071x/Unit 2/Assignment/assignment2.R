library(ggplot2)
library(dplyr)

# read the data in
elantra <- read.csv('elantra.csv')

# split into two data sets (training and testing)
elantra_training <- subset(elantra, Year <= 2012)
elantra_testing <- subset(elantra, Year > 2012)

# linear regression model to predict monthly sales
training_model <- lm(ElantraSales ~ Unemployment + CPI_all + CPI_energy + Queries, data = elantra_training)
summary(training_model)

# linear regression model to predict monthly sales with month
training_model2 <- lm(ElantraSales ~ Month + Unemployment + CPI_all + CPI_energy + Queries, data = elantra_training)
summary(training_model2)

# month factor variable
elantra_training$MonthFactor <- as.factor(elantra_training$Month)
elantra_testing$MonthFactor <- as.factor(elantra_testing$Month)

# linear regression model to predict monthly sales with month factor
training_model3 <- lm(ElantraSales ~ MonthFactor + Unemployment + CPI_all + CPI_energy + Queries, data = elantra_training)
summary(training_model3)

# CPI_energy correlation
cor(elantra_training$CPI_energy, elantra_training$Month)
cor(elantra_training$CPI_energy, elantra_training$Unemployment)
cor(elantra_training$CPI_energy, elantra_training$Queries)
cor(elantra_training$CPI_energy, elantra_training$CPI_all)

# Queries correlation
cor(elantra_training$Queries, elantra_training$Month)
cor(elantra_training$Queries, elantra_training$Unemployment)
cor(elantra_training$Queries, elantra_training$CPI_energy)
cor(elantra_training$Queries, elantra_training$CPI_all)

summary(training_model3)

# pare down the inputs
training_model4 <- lm(ElantraSales ~ MonthFactor + Unemployment + CPI_all + CPI_energy, data = elantra_training)
summary(training_model4)

# predict on the test set
prediction <- predict(training_model4, newdata = elantra_testing)
SSE <- sum((elantra_testing$ElantraSales - prediction)^2)
baselineMean <- mean(elantra_training$ElantraSales)
SST <- sum((elantra_testing$ElantraSales - baselineMean)^2)
1 - (SSE/SST)

# largest absolute error in prediction
max(abs(prediction - elantra_testing$ElantraSales))
which.max(abs(prediction - elantra_testing$ElantraSales))
