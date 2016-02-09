wine <- read.csv("wine.csv")
str(wine)
summary(wine)

model1 <- lm(Price ~ AGST, data = wine)

summary(model1)

model1$residuals

SSE <- sum(model1$residuals^2)
SSE

model2 <- lm(Price ~ AGST + HarvestRain, data = wine)

summary(model2)
model2$residuals

SSE <- sum(model2$residuals^2)
SSE

model3 <- lm(Price ~ AGST + HarvestRain + WinterRain + Age + FrancePop, data = wine)
model3
summary(model3)


SSE <- sum(model3$residuals^2)
SSE

modela <- lm(Price ~ HarvestRain + WinterRain, data = wine)
SSE <- sum(modela$residuals^2)
SSE

summary(modela)


model4 <- lm(Price ~ AGST + HarvestRain + WinterRain + Age, data = wine)
summary(model4)

cor(wine)

model5 <- lm(Price ~ AGST + HarvestRain + WinterRain, data = wine)
summary(model5)


wineTest <- read.csv('wine_test.csv')

str(wineTest)

predictTest <- predict(model4, newdata = wineTest)
predictTest

SSE <- sum((wineTest$Price - predictTest)^2)
SSE
SST <- sum((wineTest$Price - mean(wine$Price))^2)
SST
1 - (SSE/SST)

baseball <- read.csv('baseball.csv')

str(baseball)

moneyball <- subset(baseball, Year < 2002)
str(moneyball)

moneyball$RD <- moneyball$RS - moneyball$RA
str(moneyball)

plot(moneyball$RD, moneyball$W)

WinsReg <- lm(W ~ RD, data = moneyball)
summary(WinsReg)

str(moneyball)

RunsReg <- lm(RS ~ OBP + SLG + BA, data = moneyball)
summary(RunsReg)

RunsReg <- lm(RS ~ OBP + SLG, data = moneyball)
summary(RunsReg)

-804.63 + 2737.77 * OBP + 1584.91 * SLG
-804.63 + 2737.77 * 0.311 + 1584.91 * 0.405



-804.63 + 2737.77 * 0.338 + 1584.91 * 0.540
-804.63 + 2737.77 * 0.391 + 1584.91 * 0.450
-804.63 + 2737.77 * 0.369 + 1584.91 * 0.374
-804.63 + 2737.77 * 0.313 + 1584.91 * 0.447
-804.63 + 2737.77 * 0.361 + 1584.91 * 0.500



-837.38 + 2913.60 * OOBP + 1514.29 * OSLG
-837.38 + 2913.60 * 0.297 + 1514.29 * 0.370

teamRank = c(1,2,3,3,4,4,4,4,5,5)
wins2012 = c(94,88,95,88,93,94,98,97,93,94)
wins2013 = c(97,97,92,93,92,96,94,96,92,90)


cor(teamRank, wins2012)
cor(teamRank, wins2013)


99


nba <- read.csv('nba_train.csv')
str(nba)


table(nba$W, nba$Playoffs)

nba$PTSdiff = nba$PTS - nba$oppPTS

plot(nba$PTSdiff, nba$W)

WinsReg = lm(W ~ PTSdiff, data = nba)
summary(WinsReg)

W = 41 + 0.03259 * PTSdiff

1 / 0.03259


PointsReg <- lm(PTS ~ X2PA + X3PA + FTA + AST + ORB + DRB + TOV + STL + BLK, data = nba)
summary(PointsReg)

PointsReg$residuals

SSE <- sum(PointsReg$residuals^2)
SSE

RMSE <- sqrt(SSE / nrow(nba))
RMSE
mean(nba$PTS)

summary(PointsReg)

PointsReg2 <- lm(PTS ~ X2PA + X3PA + FTA + AST + ORB + DRB + STL + BLK, data = nba)
summary(PointsReg2)

PointsReg3 <- lm(PTS ~ X2PA + X3PA + FTA + AST + ORB + STL + BLK, data = nba)
summary(PointsReg3)

PointsReg4 <- lm(PTS ~ X2PA + X3PA + FTA + AST + ORB + STL, data = nba)
summary(PointsReg4)

SSE4 <- sum(PointsReg4$residuals^2)
SSE4

RMSE4 <- sqrt(SSE4 / nrow(nba))
RMSE4
mean(nba$PTS)


nba_test <- read.csv("NBA_test.csv")

PointsPredictions = predict(PointsReg4, newdata = nba_test)


SSE <- sum((PointsPredictions - nba_test$PTS)^2)
SST <- sum((mean(nba$PTS) - nba_test$PTS)^2)

RS <- 1 - SSE/SST
RS
RMSE <- sqrt(SSE/nrow(nba_test))
RMSE

