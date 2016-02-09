library(ggplot2)
library(dplyr)

# read the data in
state <- read.csv('statedata.csv')

# plot the centers
ggplot(data = state,
       aes(x = x, y = y)) +
   geom_point()

# which region has highest avg high school graduation rate?
tapply(state$HS.Grad, state$state.region, mean)

# boxplot of murder by region
ggplot(data = state,
       aes(x = state.region, y = Murder)) +
   geom_boxplot()

# which state represents Murder NE outlier?
subset(state, state.region == 'Northeast')

# life expentancy
model <- lm(Life.Exp ~ Population + Income + Illiteracy + Murder + HS.Grad + Frost + Area, data = state)
summary(model)

# plot life expentancy vs. income
plot(state$Income, state$Life.Exp)

# find a better model
# model r2 = 0.7362, adj. r2 = 0.6922
model2 <- lm(Life.Exp ~ Population + Income + Illiteracy + Murder + HS.Grad + Frost, data = state)
summary(model2) # r2 = 0.7361, adj. r2 = 0.6993
model3 <- lm(Life.Exp ~ Population + Income + Murder + HS.Grad + Frost, data = state)
summary(model3) # r2 = 0.7361, adj. r2 = 0.7061
model4 <- lm(Life.Exp ~ Population + Murder + HS.Grad + Frost, data = state)
summary(model4) # r2 = 0.736, adj. r2 = 0.7126

# predict life expectancy
sort(predict(model4))
which.min(state$Life.Exp)
which.max(state$Life.Exp)

# residuals
which.min(abs(model4$residuals))
which.max(abs(model4$residuals))

