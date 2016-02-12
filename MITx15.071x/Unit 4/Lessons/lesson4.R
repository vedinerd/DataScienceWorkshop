stevens <- read.csv("stevens.csv")
str(stevens)
library(caTools)
set.seed(3000)
spl <- sample.split(stevens$Reverse, SplitRatio = 0.7)
train <- subset(stevens, spl == TRUE)
test <- subset(stevens, spl == FALSE)

install.packages("rpart")
library(rpart)
library(rpart.plot)

StevensTree <- rpart(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, method = "class", minbucket = 25)

prp(StevensTree)

PredictCART <- predict(StevensTree, newdata = test, type = "class")

summary(PredictCART)
table(test$Reverse, PredictCART)
(41+71)/(41+36+22+71)

library(ROCR)

PredictROC <- predict(StevensTree, newdata = test)

PredictROC
pred = prediction(PredictROC[,2], test$Reverse)
perf = performance(pred, "tpr", "fpr")
plot(perf)

as.numeric(performance(pred, "auc")@y.values)

StevensTree2 <- rpart(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, method = "class", minbucket = 5)
prp(StevensTree2)

StevensTree3 <- rpart(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, method = "class", minbucket = 100)
prp(StevensTree3)




install.packages("randomForest")
library(randomForest)

train$Reverse <- as.factor(train$Reverse)
test$Reverse <- as.factor(test$Reverse)

set.seed(200)
StevensForest <- randomForest(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, nodesize = 25, ntree = 200)
PredictForest <- predict(StevensForest, newdata = test)

table(test$Reverse, PredictForest)
(44+76)/(44+33+17+76)

install.packages("caret")
library(caret)
install.packages("e1071")
library(e1071)


numFolds <- trainControl(method = "cv", number = 10)
cpGrid <- expand.grid(.cp = seq(0.01, 0.5, 0.01))
train(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, method = "rpart", trControl = numFolds, tuneGrid = cpGrid)

StevensTreeCV = rpart(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst)

StevensTreeCV <- rpart(Reverse ~ Circuit + Issue + Petitioner + Respondent + LowerCourt + Unconst, data = train, method = "class", cp = 0.19)

PredictCV <- predict(StevensTreeCV, newdata = test, type = "class")
table(test$Reverse, PredictCV)
(59+64)/(59+18+29+64)

prp(StevensTreeCV)



Claims <- read.csv("ClaimsData.csv")
str(Claims)
table(Claims$bucket2009)/nrow(Claims)

library(caTools)
set.seed(88)

spl = sample.split(Claims$bucket2009, SplitRatio = 0.6)
ClaimsTrain = subset(Claims, spl == TRUE)
ClaimsTest = subset(Claims, spl == FALSE)

summary(ClaimsTrain)
nrow(subset(ClaimsTrain, diabetes > 0)) / nrow(ClaimsTrain)
104672

table(ClaimsTest$bucket2009, rep(1, nrow(ClaimsTest)))

122978 / (nrow(ClaimsTest))


sum(as.matrix(table(ClaimsTest$bucket2009, rep(1, nrow(ClaimsTest))) * PenaltyMatrix2)) / nrow(ClaimsTest)



ClaimsTest$bucket2008

head(ClaimsTest)


(110138+10721+2774+1539+104)/nrow(ClaimsTest)

PenaltyMatrix = matrix(c(0,1,2,3,4,2,0,1,2,3,4,2,0,1,2,6,4,2,0,1,8,6,4,2,0), byrow = TRUE, nrow = 5)

PenaltyMatrix2 = matrix(c(0,2,4,6,8), byrow = TRUE, nrow = 5)

as.matrix(table(ClaimsTest$bucket2009, ClaimsTest$bucket2008))*PenaltyMatrix



PenaltyMatrix
as.matrix(table(ClaimsTest$bucket2009, ClaimsTest$bucket2008))*PenaltyMatrix

sum(as.matrix(table(ClaimsTest$bucket2009, ClaimsTest$bucket2008)) * PenaltyMatrix) / nrow(ClaimsTest)


library(rpart)
library(rpart.plot)


ClaimsTree <- rpart(bucket2009 ~ age + arthritis + alzheimers + cancer + copd + depression + diabetes + heart.failure + ihd + kidney + osteoporosis + stroke + bucket2008 + reimbursement2008, data = ClaimsTrain, method = "class", cp = 0.00005)

prp(ClaimsTree)

PredictTest <- predict(ClaimsTree, newdata = ClaimsTest, type = "class")
table(ClaimsTest$bucket2009, PredictTest)

(114141 + 16102 + 118 + 201 + 0) / nrow(ClaimsTest)

as.matrix(table(ClaimsTest$bucket2009, PredictTest)) * PenaltyMatrix

sum(as.matrix(table(ClaimsTest$bucket2009, PredictTest)) * PenaltyMatrix) / nrow(ClaimsTest)


ClaimsTree <- rpart(bucket2009 ~ age + arthritis + alzheimers + cancer + copd + depression + diabetes + heart.failure + ihd + kidney + osteoporosis + stroke + bucket2008 + reimbursement2008, data = ClaimsTrain, method = "class", cp = 0.00005, parms = list(loss=PenaltyMatrix))

PredictTest <- predict(ClaimsTree, newdata = ClaimsTest, type = "class")
table(ClaimsTest$bucket2009, PredictTest)

?table
(94310+18942+4692+636+2)/nrow(ClaimsTest)
sum(as.matrix(table(ClaimsTest$bucket2009, PredictTest)) * PenaltyMatrix) / nrow(ClaimsTest)

(94310+7176+3590+1304+135)/nrow(ClaimsTest)



boston <- read.csv("boston.csv")
str(boston)
plot(boston$LON, boston$LAT)
points(boston$LON[boston$CHAS == 1], boston$LAT[boston$CHAS == 1], col = "blue", pch = 19)
points(boston$LON[boston$TRACT == 3531], boston$LAT[boston$TRACT == 3531], col = "red", pch = 19)

summary(boston$NOX)

points(boston$LON[boston$NOX >= 0.55], boston$LAT[boston$NOX >= 0.55], col = "green", pch = 19)



