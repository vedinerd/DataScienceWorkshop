library(dplyr)
library(ggplot2)

# read in the data
baseball <- read.csv("baseball.csv")

# number of rows
nrow(baseball)

# number of individual years
nrow(table(baseball$Year))

# only teams that made the playoffs
baseball <- subset(baseball, Playoffs == 1)
nrow(baseball)

# numbers of teams in playoffs
table(baseball$Year)

# store number of teams in playoffs
PlayoffTable <- table(baseball$Year)
names(PlayoffTable)

# add NumCompetitors column
baseball$NumCompetitors <- PlayoffTable[as.character(baseball$Year)]

# number where NumCompetitors is 8
nrow(subset(baseball, NumCompetitors == 8))

# add WorldSeries variable
baseball$WorldSeries = as.numeric(baseball$RankPlayoffs == 1)

# number where record does not represent a world series win year/team combo
nrow(subset(baseball, WorldSeries == 0))

# build bivariate models
mod01 <- glm(WorldSeries ~ Year, data = baseball, family = "binomial")
mod02 <- glm(WorldSeries ~ RS, data = baseball, family = "binomial")
mod03 <- glm(WorldSeries ~ RA, data = baseball, family = "binomial")
mod04 <- glm(WorldSeries ~ W, data = baseball, family = "binomial")
mod05 <- glm(WorldSeries ~ OBP, data = baseball, family = "binomial")
mod06 <- glm(WorldSeries ~ SLG, data = baseball, family = "binomial")
mod07 <- glm(WorldSeries ~ BA, data = baseball, family = "binomial")
mod08 <- glm(WorldSeries ~ RankSeason, data = baseball, family = "binomial")
mod09 <- glm(WorldSeries ~ OOBP, data = baseball, family = "binomial")
mod10 <- glm(WorldSeries ~ OSLG, data = baseball, family = "binomial")
mod11 <- glm(WorldSeries ~ NumCompetitors, data = baseball, family = "binomial")
mod12 <- glm(WorldSeries ~ League, data = baseball, family = "binomial")
summary(mod01) # AIC 232.35
summary(mod02)
summary(mod03) # AIC 237.88
summary(mod04)
summary(mod05)
summary(mod06)
summary(mod07)
summary(mod08) # AIC 238.75
summary(mod09)
summary(mod10)
summary(mod11) # AIC 230.96
summary(mod12)

# multivariate model
model <- glm(WorldSeries ~ Year + RA + RankSeason + NumCompetitors, data = baseball, family = "binomial")

# multivariate correlations
cor(baseball[c("Year", "RA", "RankSeason", "NumCompetitors")])

# multivariate models
mod21 <- glm(WorldSeries ~ Year + RA, data = baseball, family = "binomial")
mod22 <- glm(WorldSeries ~ Year + RankSeason, data = baseball, family = "binomial")
mod23 <- glm(WorldSeries ~ Year + NumCompetitors, data = baseball, family = "binomial")
mod24 <- glm(WorldSeries ~ RA + RankSeason, data = baseball, family = "binomial")
mod25 <- glm(WorldSeries ~ RA + NumCompetitors, data = baseball, family = "binomial")
mod26 <- glm(WorldSeries ~ RankSeason + NumCompetitors, data = baseball, family = "binomial")
summary(mod21) # AIC 233.88
summary(mod22) # AIC 233.55
summary(mod23) # AIC 232.90
summary(mod24) # AIC 238.22
summary(mod25) # AIC 232.74
summary(mod26) # AIC 232.52
