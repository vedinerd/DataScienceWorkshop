library(dplyr)
library(caTools)
library(ROCR)
library(ggplot2)
library(gridExtra) 

################################################################################
# prepare data

# read all our data in
package_file <- unz("sample_data/package_sample.zip", "package_sample.csv")
package_activity_file <- unz("sample_data/package_activity_sample.zip", "package_activity_sample.csv")
weather_file <- unz("sample_data/weather_sample.zip", "weather_sample.csv")
package <- read.csv(package_file)
package_activity <- read.csv(package_activity_file)
weather <- read.csv(weather_file)
remove(package_file, package_activity_file, weather_file)

# date type conversions
package$ship_date_time <- as.POSIXct(strptime(package$ship_date_time, "%Y-%m-%d %H:%M:%S"))
package$scheduled_delivery_date_time <- as.POSIXct(strptime(package$scheduled_delivery_date_time, "%Y-%m-%d %H:%M:%S"))
package$actual_delivery_date_time <- as.POSIXct(strptime(package$actual_delivery_date_time, "%Y-%m-%d %H:%M:%S"))
package_activity$date_time <- as.POSIXct(strptime(package_activity$date_time, "%Y-%m-%d %H:%M:%S"))
package_activity$rounded_date_time <- as.POSIXct(strptime(package_activity$rounded_date_time, "%Y-%m-%d %H:%M:%S"))
weather$date_time <- as.POSIXct(strptime(weather$date_time, "%Y-%m-%d %H:%M:%S"))

# join the package_activity and weather tables together
package_activity_weather <-
   package_activity %>%
      left_join(weather, by = c("rounded_date_time" = "date_time", "closest_station_wban" = "wban"))

# group the joined table by tracking_number
package_activity_weather_summary <-
   package_activity_weather %>%
      select(1, 11:12, 14:19, 21:22) %>%
      group_by(tracking_number) %>%
      summarize_each(funs(mean, max, min))

# join the new summary table with the package table
package_activity_weather_summary$tracking_number <- as.character(package_activity_weather_summary$tracking_number)
package$tracking_number <- as.character(package$tracking_number)
package_activity_weather_summary <-
   package_activity_weather_summary %>%
   left_join(package, by = c("tracking_number" = "tracking_number"))

# convert the two boolean columns into binary number columns
package_activity_weather_summary$was_delayed <- as.integer(package_activity_weather_summary$was_delayed) - 1
package_activity_weather_summary$was_delayed_weather <- as.integer(package_activity_weather_summary$was_delayed_weather) - 1

# split the data into training and testing sets (75% training)
split <- sample.split(package_activity_weather_summary$was_delayed, 0.75)
package_train <- subset(package_activity_weather_summary, split == TRUE)
package_test <- subset(package_activity_weather_summary, split == FALSE)

# if we assume no packages delayed due to weather as a baseline prediction, we get:
table(package_train$was_delayed_weather)
#   f      t
# f 36,385 0
# t    223 0
# 36385 / (223 + 36385) = 0.9939
# 99.39% prediction accuracy
# Note that it is very unlikely any model we come up with will beat this null prediction
# accuracy because the vast majority of the data represents packages that were not late,
# or more specifically were not late due to a weather-related issue.  But since the null
# prediction is useless, we agree to accept a model (paradoxically) with worse accuracy
# but actually useful predictive powers.

################################################################################
# try logistic multiple regression

# first look for highly correlated variables to get rid of them right off the bat
correlation <- cor(package_train[sapply(package_train, is.numeric)])
write.csv(correlation, "correlation.csv")

# we see from this that dry_bulb_celsius, wet_bulb_celsius, and dew_point_celsius are all highly correlated, so just use dry_bulb_celsius_*

# start with all the possibly relevant variables, except those eliminated above proactively as correlated,
# and also eliminate hourly_precip_min since it is 0 for every package and therefore useless
logistic_model_weather_initial <-
   glm(was_delayed_weather ~
          visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
          visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
          visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
       data = package_train,
       family = "binomial")
summary(logistic_model_weather_01) # AIC: 2376.6

# after paring all the irrelevant variables down, we're left with this model:
logistic_model_weather <-
   glm(was_delayed_weather ~
          visibility_mean + dry_bulb_celsius_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
          relative_humidity_max + hourly_precip_max +
          visibility_min + wind_speed_min + station_pressure_min,
       data = package_train,
       family = "binomial")
summary(logistic_model_weather) # AIC: 2374.3

# feed in the test data
logistic_model_predict <- predict(logistic_model_weather, type = "response", newdata = package_test)
logistic_model_prediction <- prediction(logistic_model_predict, package_test$was_delayed_weather)
as.numeric(performance(logistic_model_prediction, "auc")@y.values) # 0.798
logistic_model_performance_tpr_fpr <- performance(logistic_model_prediction, "tpr", "fpr")
logistic_model_performance_ppv <- performance(logistic_model_prediction, "ppv")
logistic_model_performance_npv <- performance(logistic_model_prediction, "npv")
logistic_model_performance_acc <- performance(logistic_model_prediction, "acc")
logistic_model_performance_tpr <- performance(logistic_model_prediction, "tpr")
logistic_model_performance_tnr <- performance(logistic_model_prediction, "tnr")

plot(logistic_model_performance_tpr_fpr, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.020, 0.001), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })
plot(logistic_model_performance_ppv, xlim = c(0.0, 0.02), ylim = c(0.00, 0.04))
plot(logistic_model_performance_npv, xlim = c(0.0, 0.02))
plot(logistic_model_performance_acc, xlim = c(0.0, 0.02))
plot(logistic_model_performance_tpr, xlim = c(0.0, 0.02))
plot(logistic_model_performance_tnr, xlim = c(0.0, 0.02))


table(package_test$was_delayed_weather, logistic_model_predict > 0.005)

tn  fp
fn  tp

10696  1413
47     47


accuracy: (10696+47)/(10696+1413+47+47) : 0.880
ppv: TP / (TP + FP) : 47 / (47+1413): 0.032


# search the space from 0.020 to 0.001 and build a table of some measurements of quality to help decide the best threshold
search <- seq(0.020, 0.001, -0.001)
threshold_data <- data.frame(numeric(0), numeric(0), numeric(0), numeric(0), numeric(0), numeric(0))
for (i in 1:20) {
   confusion <- table(package_test$was_delayed_weather, logistic_model_predict > search[i])
   tn <- confusion[1,1]
   tp <- confusion[2,2]
   fn <- confusion[2,1]
   fp <- confusion[1,2]
   accuracy <- (tn+tp)/(tn+tp+fn+fp)
   sensitivity <- tp/(tp+fn)
   specificity <- tn/(tn+fp)
   pos_pred_value <- tp/(tp+fp)
   neg_pred_value <- tn/(tn+fn)
   threshold_data <- rbind(threshold_data, c(search[i], accuracy, sensitivity, specificity, pos_pred_value, neg_pred_value))
}
colnames(threshold_data) <- c("threshold", "accuracy", "sensitivity", "specificity", "pos_pred_value", "neg_pred_value")
grid.arrange(
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = accuracy)) + scale_x_continuous(breaks = seq(0.0, 0.02, 0.002)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = sensitivity)) + scale_x_continuous(breaks = seq(0.0, 0.02, 0.002)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = specificity)) + scale_x_continuous(breaks = seq(0.0, 0.02, 0.002)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = pos_pred_value)) + scale_x_continuous(breaks = seq(0.0, 0.02, 0.002)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = neg_pred_value)) + scale_x_continuous(breaks = seq(0.0, 0.02, 0.002)))
   


0.004


   summary(logistic_model_performance)
   
   ggplot(data = logistic_model_performance, aes(x = "False positive rate"))
   

logistic_model_performance@x.values
logistic_model_performance@y.values
logistic_model_performance@alpha.values



   plot(logistic_model_performance, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.020, 0.001), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) }))

# with this information, and given that the problem set wants to minimize the false negative rate,
# choose 0.018 as the threshold, giving:
table(package_test$was_delayed_weather, predict_weather_02 > 0.018)





predict_weather_01 <- predict(logistic_model_weather_01, type = "response", newdata = package_test)
predict_test_weather_01 <- prediction(predict_weather_01, package_test$was_delayed_weather)
as.numeric(performance(predict_test_weather_01, "auc")@y.values) # 0.8187
predict_test_perf_weather_01 <- performance(predict_test_weather_01, "tpr", "fpr")
plot(predict_test_perf_weather_01, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.030, 0.001), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })





package_train[c(3:11, 13:21, 23:31)]

package_activity <- read.csv(package_activity_file)



# after paring all the irrelevant variables down, we're left with this model:
logistic_model_weather_02 <-
   glm(was_delayed_weather ~
       visibility_mean + dry_bulb_fahrenheit_mean + 
       wind_speed_mean +
       hourly_precip_mean + visibility_max +
       relative_humidity_max +
       hourly_precip_max + visibility_min +
       wet_bulb_fahrenheit_min + relative_humidity_min +
       wind_speed_min + station_pressure_min,
    data = package_train,
    family = "binomial")
summary(logistic_model_weather_02) # AIC: 2343.8
predict_weather_02 <- predict(logistic_model_weather_02, type = "response", newdata = package_test)
predict_test_weather_02 <- prediction(predict_weather_02, package_test$was_delayed_weather)
as.numeric(performance(predict_test_weather_02, "auc")@y.values) # 0.8164
predict_test_perf_weather_02 <- performance(predict_test_weather_02, "tpr", "fpr")
plot(predict_test_perf_weather_02, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.030, 0.001), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })

# search the space from 0.030 to 0.001 and build a table of some measurements of quality to help decide the best threshold
search <- seq(0.030, 0.001, -0.001)
threshold_data <- data.frame(numeric(0), numeric(0), numeric(0), numeric(0))
for (i in 1:30) {
   confusion <- table(package_test$was_delayed_weather, predict_weather_02 > search[i])
   tn <- confusion[1,1]
   tp <- confusion[2,2]
   fn <- confusion[1,2]
   fp <- confusion[2,1]
   accuracy <- (tn+tp)/(tn+tp+fn+fp)
   sensitivity <- tp/(tp+fn)
   specificity <- tn/(tn+fp)
   pos_pred_value <- tp/(tp+fp)
   neg_pred_value <- tn/(tn+fn)
   threshold_data <- rbind(threshold_data, c(search[i], accuracy, sensitivity, specificity, pos_pred_value, neg_pred_value))
}
colnames(threshold_data) <- c("threshold", "accuracy", "sensitivity", "specificity", "pos_pred_value", "neg_pred_value")
grid.arrange(
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = accuracy)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = sensitivity)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = specificity)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = pos_pred_value)),
   ggplot(data = threshold_data, aes(x = threshold)) + geom_line(aes(y = neg_pred_value)))

# with this information, and given that the problem set wants to minimize the false negative rate,
# choose 0.018 as the threshold, giving:
table(package_test$was_delayed_weather, predict_weather_02 > 0.018)

################################################################################
# decision tree

library(randomForest)
library(rpart)
library(rpart.plot)

package_tree <- rpart(
   was_delayed_weather ~
      visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
      visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
      visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
   data = package_train,
   method = "anova",
   minbucket = 10)

package_tree_predict <- predict(package_tree, newdata = package_test)
package_tree_prediction <- prediction(package_tree_predict, package_test$was_delayed_weather)

package_tree_perf <- performance(package_tree_prediction, "tpr", "fpr")


plot(package_tree_perf)


predict_test_perf_weather_02 <- performance(predict_test_weather_02, "tpr", "fpr")


table(package_test$was_delayed_weather, package_tree_predict > 0.01)

plot(package_tree_predict)

package_tree_predict


?rpart

prp(package_tree)

package_forest <- randomForest(
   was_delayed_weather ~
      visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
      visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
      visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
   data = package_train, nodesize = 25, ntree = 200)



