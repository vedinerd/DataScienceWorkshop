quality <- read.csv('quality.csv')
str(quality)
table(quality$PoorCare)

install.packages('caTools')

library(caTools)

split <- sample.split(quality$PoorCare, SplitRatio = 0.75)

head(split)

qualityTrain <- subset(quality, split == TRUE)
qualityTest <- subset(quality, split == FALSE)

QualityLog <- glm(PoorCare ~ OfficeVisits + Narcotics, data = qualityTrain, family = binomial)

summary(QualityLog)

predictTrain = predict(QualityLog, type = "response")

summary(predictTrain)

tapply(predictTrain, qualityTrain$PoorCare, mean)

predictTest = predict(QualityLog, type="response", newdata=qualityTest)

ROCRpredTest = prediction(predictTest, qualityTest$PoorCare)

auc = as.numeric(performance(ROCRpredTest, "auc")@y.values)
auc


set.seed(88)

QualityLog2 <- glm(PoorCare ~ StartedOnCombination + ProviderCount, data = qualityTrain, family = binomial)
summary(QualityLog2)

table(qualityTrain$PoorCare, predictTrain > 0.2)


sensitivity = TP / (TP + FN)
specificity = TN / (TN + FP)

11 / (11 + 187)
1069 / (1069 + 6)

   0  1
0 TN FP
1 FN TP



20 / (20 + 5)
15 / (15 + 10)

15 / (10 + 15)
20 / (20 + 5)

# increase threshold, sensitivity goes down, specificity goes up

install.packages("ROCR")
library(ROCR)


ROCRpred <- prediction(predictTrain, qualityTrain$PoorCare)
ROCRperf <- performance(ROCRpred, "tpr", "fpr")

plot(ROCRperf)
plot(ROCRperf, colorize = TRUE)
plot(ROCRperf, colorize = TRUE, print.cutoffs.at = seq(0, 1, 0.1), text.adj = c(-0.2, 1.7))


7/25
6/25


framingham <- read.csv('framingham.csv')
str(framingham)
library(caTools)
set.seed(1000)
split <- sample.split(framingham$TenYearCHD, SplitRatio = 0.65)
train <- subset(framingham, split == TRUE)
test <- subset(framingham, split == FALSE)
framinghamLog = glm(TenYearCHD ~ ., data = train, family = binomial)
summary(framinghamLog)

predictTest <- predict(framinghamLog, type = "response", newdata = test)
table(test$TenYearCHD, predictTest > 0.5)
library(ROCR)
ROCRpred = prediction(predictTest, test$TenYearCHD)
as.numeric(performance(ROCRpred, "auc")@y.values)



polling = read.csv("PollingData.csv")
str(polling)

table(polling$Year)

summary(polling)


install.packages('mice')
library(mice)

simple <- polling[c("Rasmussen", "SurveyUSA", "PropR", "DiffCount")]

summary(simple)
set.seed(144)

imputed <- complete(mice(simple))

summary(imputed)


polling$Rasmussen <- imputed$Rasmussen
polling$SurveyUSA <- imputed$SurveyUSA

summary(polling)

Train <- subset(polling, Year == 2004 | Year == 2008)
Test <- subset(polling, Year == 2012)

table(Train$Republican)

table(sign(Train$Rasmussen))
table(Train$Republican, sign(Train$Rasmussen))

str(Train)
cor(Train[c("Rasmussen", "SurveyUSA", "PropR", "DiffCount", "Republican")])

mod1 <- glm(Republican ~ PropR, data = Train, family = "binomial")
summary(mod1)

mod2 <- glm(Republican ~ SurveyUSA + DiffCount, data = Train, family = "binomial")
pred2 <- predict(mod2, type="response")
table(Train$Republican, pred2 >= 0.5)
summary(mod2)

table(Test$Republican, sign(Test$Rasmussen))

TestPrediction <- predict(mod2, newdata = Test, type = "response")
table(Test$Republican, TestPrediction >= 0.99)


ROCRpred2 <- prediction(TestPrediction, Test$Republican)
ROCRperf2 <- performance(ROCRpred2, "tpr", "fpr")

plot(ROCRperf2)
plot(ROCRperf2, colorize = TRUE)
plot(ROCRperf2, colorize = TRUE, print.cutoffs.at = seq(0, 1, 0.1), text.adj = c(-0.2, 1.7))

TestPrediction


subset(Test, TestPrediction >= 0.5 & Republican == 0)







