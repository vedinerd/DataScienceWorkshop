library(dplyr)
library(caTools)
library(ROCR)
library(ggplot2)
library(gridExtra) 
library(GGally)
library(randomForest)
library(rpart)
library(rpart.plot)

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
#package_activity_weather_summary$was_delayed <- as.integer(as.integer(package_activity_weather_summary$was_delayed) - 1)
#package_activity_weather_summary$was_delayed_weather <- as.integer(as.integer(package_activity_weather_summary$was_delayed_weather) - 1)

# split the data into training and testing sets (60% training)
split <- sample.split(package_activity_weather_summary$was_delayed, 0.60)
package_train <- subset(package_activity_weather_summary, split == TRUE)
package_test <- subset(package_activity_weather_summary, split == FALSE)

# if we assume no packages delayed due to weather as a baseline prediction, we get:
table(package_train$was_delayed_weather)
#   f      t
# f 334810 0
# t   2195 0
# 334810 / (2195 + 334810) = 0.9935
# 99.35% prediction accuracy
# Note that it is very unlikely any model we come up with will beat this null prediction
# accuracy because the vast majority of the data represents packages that were not late,
# or more specifically were not late due to a weather-related issue.  But since the null
# prediction is useless, we agree to accept a model (paradoxically) with worse accuracy
# but actually useful predictive powers.

# generate plots showing correlations between pairs of variables
package_train_order <- package_train[with(package_train, order(was_delayed_weather)), ] # force our late by weather packages to the end so they aren't overplotted
for(i in c("visibility_mean","dry_bulb_celsius_mean","relative_humidity_max","visibility_min","wind_speed_min","station_pressure_min","dry_bulb_celsius_min","wind_speed_mean","visibility_max","hourly_precip_max")) {
   for(j in c("visibility_mean","dry_bulb_celsius_mean","relative_humidity_max","visibility_min","wind_speed_min","station_pressure_min","dry_bulb_celsius_min","wind_speed_mean","visibility_max","hourly_precip_max")) {
      if (i != j) {
         ggsave(filename = paste(i, "+", j, ".png", sep = ""),
                width = 10,
                height = 8,
                dpi = 300,
                units = "in",
                plot =
                   ggplot(data = filter_(package_train_order, paste(i, " <= stats::quantile(", i, ", 0.995) & ", i, " >= stats::quantile(", i, ", 0.005) & ", j, " <= stats::quantile(", j, ", 0.995) & ", j, " >= stats::quantile(", j, ", 0.005)", sep = "")),
                          aes_string(x = i,
                                     y = j,
                                     color = "was_delayed_weather",
                                     alpha = "was_delayed_weather")) +
                   geom_point() +
                   scale_alpha_discrete(range = c(0.03, 0.50)) +
                   geom_smooth(alpha = 0.5,
                               method = "lm"))
      }
   }
}
remove(package_train_order)

# generate plots showing individual variables 
for(i in names(package_train[c(3:11, 13:21, 23:31)])) {
   ggsave(filename = paste(i, ".pdf", sep = ""),
          width = 10,
          height = 8,
          dpi = 300,
          units = "in",
          plot =
             ggplot(data = filter_(package_train, paste(i, " <= stats::quantile(", i, ", 0.99) & ", i, " >= stats::quantile(", i, ", 0.01)", sep = "")),
                    aes_string(x = "was_delayed_weather",
                               y = i,
                               color = "was_delayed_weather")) +
             geom_boxplot())
}

################################################################################
# try logistic multiple regression

# first look for highly correlated variables to get rid of them right off the bat
correlation <- cor(package_train[sapply(package_train, is.numeric)])
write.csv(correlation, "correlation.csv")

# we see from this that dry_bulb_celsius, wet_bulb_celsius, and dew_point_celsius are all highly correlated, so just use dry_bulb_celsius_*

# start with all the possibly relevant variables, except those eliminated above proactively as correlated,
# and also eliminate hourly_precip_min since it is 0 for every package and therefore useless, and hourly_precip_mean has too little data
logistic_model_weather <-
   glm(was_delayed_weather ~
          visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean +
          visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
          visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
       data = package_train,
       family = "binomial")
summary(logistic_model_weather) # AIC: 23663

# after paring all the irrelevant variables down, we're left with this model:
logistic_model_weather <-
   glm(was_delayed_weather ~
          visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean +
          visibility_max + relative_humidity_max + hourly_precip_max +
          visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
       data = package_train,
       family = "binomial")
summary(logistic_model_weather) # AIC: 23661

# Calculate the AUC for the training data
logistic_model_predict_train <- predict(logistic_model_weather, type = "response", newdata = package_train)
logistic_model_prediction_train <- prediction(logistic_model_predict_train, package_train$was_delayed_weather)
as.numeric(performance(logistic_model_prediction_train, "auc")@y.values) # 0.795
logistic_model_performance_tpr_fpr_train <- performance(logistic_model_prediction_train, "tpr", "fpr")
plot(logistic_model_performance_tpr_fpr_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Logistic Multiple Regression (Training Data) ROC (AUC ", round(as.numeric(performance(logistic_model_prediction_train, "auc")@y.values), 3), ")", sep = "")))

# Feed in the test data.
logistic_model_predict_test <- predict(logistic_model_weather, type = "response", newdata = package_test)
logistic_model_prediction_test <- prediction(logistic_model_predict_test, package_test$was_delayed_weather)
as.numeric(performance(logistic_model_prediction_test, "auc")@y.values) # 0.790
logistic_model_performance_tpr_fpr_test <- performance(logistic_model_prediction_test, "tpr", "fpr")
plot(logistic_model_performance_tpr_fpr_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Logistic Multiple Regression (Test Data) ROC (AUC ", round(as.numeric(performance(logistic_model_prediction_test, "auc")@y.values), 3), ")", sep = "")))




logistic_model_performance_ppv <- performance(logistic_model_prediction, "ppv")
logistic_model_performance_npv <- performance(logistic_model_prediction, "npv")
logistic_model_performance_acc <- performance(logistic_model_prediction, "acc")
logistic_model_performance_tpr <- performance(logistic_model_prediction, "tpr")
logistic_model_performance_tnr <- performance(logistic_model_prediction, "tnr")

plot(logistic_model_performance_ppv, xlim = c(0.0, 0.02), ylim = c(0.00, 0.04))
plot(logistic_model_performance_npv, xlim = c(0.0, 0.02))
plot(logistic_model_performance_acc, xlim = c(0.0, 0.02))
plot(logistic_model_performance_tpr, xlim = c(0.0, 0.02))
plot(logistic_model_performance_tnr, xlim = c(0.0, 0.02))


table(package_test$was_delayed_weather, logistic_model_predict > 0.02)


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



plot(logistic_model_performance, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.020, 0.001), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })

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

# sweep the cp and minsplit parameter space, looking to maximize AUC
for(cp_var in seq(0.0001, 0.001, by = 0.0001)) {
   for(minsplit_var in seq(10, 100, by = 10)) {
      package_tree <- rpart(
         was_delayed_weather ~
            visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
            visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
            visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
         method = "class",
         control = rpart.control(cp = cp_var,
                                 minsplit = minsplit_var),
         data = package_train)
      package_tree_predict <- predict(package_tree, newdata = package_test)
      package_tree_prediction <- prediction(package_tree_predict[,2], package_test$was_delayed_weather)
      print(paste(cp_var, minsplit_var, as.numeric(performance(package_tree_prediction, "auc")@y.values), sep = ","))
   }
}

# Best found was cp = 0.0001, minsplit = 40 -> auc: 0.849
package_tree <- rpart(
   was_delayed_weather ~
      visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
      visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
      visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
   method = "class",
   control = rpart.control(cp = 0.0001,
                           minsplit = 40),
   data = package_train)
package_tree_predict_test <- predict(package_tree, newdata = package_test)
package_tree_prediction_test <- prediction(package_tree_predict_test[,2], package_test$was_delayed_weather)
as.numeric(performance(package_tree_prediction_test, "auc")@y.values) # 0.849
prp(package_tree)
package_tree_perf_test <- performance(package_tree_prediction_test, "tpr", "fpr")
plot(package_tree_perf_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Decision Tree (Testing Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_test, "auc")@y.values), 3), ")", sep = "")))

# This tree is very complicated; seems like it might be over-fit.  What is the AUC when used on the training data?
package_tree_predict_train <- predict(package_tree, newdata = package_train)
package_tree_prediction_train <- prediction(package_tree_predict_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_tree_prediction_train, "auc")@y.values) # 0.868
package_tree_perf_train <- performance(package_tree_prediction_train, "tpr", "fpr")
plot(package_tree_perf_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Decision Tree (Training Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_train, "auc")@y.values), 3), ")", sep = "")))

# The tree is very complicated -- it seems to be over-fit.  However, we see an AUC of 0.868 when using the
# training data and an AUC of 0.849 when using the testing data, which seems reasonable.  The data is a little
# over-fit, but still seems to be a good predictor of the testing data.  We need to throw more unseen data at the
# model to be sure, however.

# Still, let's see if we can prune the tree to reduce the complexity.  Prune the tree at the minimum 'xerror' point.
printcp(package_tree)
plotcp(package_tree)
package_tree_pruned <- prune(package_tree, cp = package_tree$cptable[which.min(package_tree$cptable[,"xerror"]),"CP"])
printcp(package_tree_pruned)
plotcp(package_tree_pruned)
package_tree_predict_pruned_test <- predict(package_tree_pruned, newdata = package_test)
package_tree_prediction_pruned_test <- prediction(package_tree_predict_pruned_test[,2], package_test$was_delayed_weather)
as.numeric(performance(package_tree_prediction_pruned_test, "auc")@y.values) # 0.824
package_tree_perf_pruned_test <- performance(package_tree_prediction_pruned_test, "tpr", "fpr")
plot(package_tree_perf_pruned_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Pruned Decision Tree (Testing Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_pruned_test, "auc")@y.values), 3), ")", sep = "")))
prp(package_tree_pruned)
package_tree_predict_pruned_train <- predict(package_tree_pruned, newdata = package_train)
package_tree_prediction_pruned_train <- prediction(package_tree_predict_pruned_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_tree_prediction_pruned_train, "auc")@y.values) # 0.832
package_tree_perf_pruned_train <- performance(package_tree_prediction_pruned_train, "tpr", "fpr")
plot(package_tree_perf_pruned_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Pruned Decision Tree (Training Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_pruned_train, "auc")@y.values), 3), ")", sep = "")))

# This tree is much less complicated, and is a poorer fit to the training data AS WELL as the testing data,
# but I think the reduction in the tree complexity is worth it.

################################################################################
# random forest

# After experimenting with the nodesize and ntree parameters, I arrived at nodesize = 20 and ntree = 500.
package_forest <- randomForest(
   was_delayed_weather ~
      visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean + hourly_precip_mean +
      visibility_max + dry_bulb_celsius_max + relative_humidity_max + wind_speed_max + station_pressure_max + hourly_precip_max +
      visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
   data = package_train, nodesize = 20, ntree = 500)
summary(package_forest)
package_forest_predict_test <- predict(package_forest, newdata = package_test, type="prob")
package_forest_prediction_test <- prediction(package_forest_predict_test[,2], package_test$was_delayed_weather)
as.numeric(performance(package_forest_prediction_test, "auc")@y.values) # 0.922
package_forest_perf_test <- performance(package_forest_prediction_test, "tpr", "fpr")
plot(package_forest_perf_test, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.030, 0.002), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })

# Take a look at the AUC against the training data
package_forest_predict_train <- predict(package_forest, newdata = package_train, type="prob")
package_forest_prediction_train <- prediction(package_forest_predict_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_forest_prediction_train, "auc")@y.values) # 1.000 (!)
package_forest_perf_train <- performance(package_forest_prediction_train, "tpr", "fpr")
plot(package_forest_perf_train, colorize = TRUE, print.cutoffs.at = seq(0.000, 0.030, 0.002), text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) })
# This seems radically over-fit, yet still provides a good accuracy against the testing data.
# I'm not quite sure what to do at this point, except throw more unseen data at the model.
# We have been using 25% of the full data set (60% of that 25% towards training and 40% towards testing) so far.

# Let's load in the full data set, remove all rows that have already been trained or tested against, and throw
# it at the model as test data.
package_file <- unz("data/package.zip", "package.csv")
package_activity_file <- unz("data/package_activity.zip", "package_activity.csv")
weather_file <- unz("data/weather.zip", "weather.csv")
package_full <- read.csv(package_file)
package_activity_full <- read.csv(package_activity_file)
weather_full <- read.csv(weather_file)
remove(package_file, package_activity_file, weather_file)
package_full$ship_date_time <- as.POSIXct(strptime(package_full$ship_date_time, "%Y-%m-%d %H:%M:%S"))
package_full$scheduled_delivery_date_time <- as.POSIXct(strptime(package_full$scheduled_delivery_date_time, "%Y-%m-%d %H:%M:%S"))
package_full$actual_delivery_date_time <- as.POSIXct(strptime(package_full$actual_delivery_date_time, "%Y-%m-%d %H:%M:%S"))
package_activity_full$date_time <- as.POSIXct(strptime(package_activity_full$date_time, "%Y-%m-%d %H:%M:%S"))
package_activity_full$rounded_date_time <- as.POSIXct(strptime(package_activity_full$rounded_date_time, "%Y-%m-%d %H:%M:%S"))
weather_full$date_time <- as.POSIXct(strptime(weather_full$date_time, "%Y-%m-%d %H:%M:%S"))
package_activity_weather_full <-
   package_activity_full %>%
   left_join(weather_full, by = c("rounded_date_time" = "date_time", "closest_station_wban" = "wban"))
package_activity_weather_summary_full <-
   package_activity_weather_full %>%
   select(1, 11:12, 14:19, 21:22) %>%
   group_by(tracking_number) %>%
   summarize_each(funs(mean, max, min))
package_activity_weather_summary_full$tracking_number <- as.character(package_activity_weather_summary_full$tracking_number)
package_full$tracking_number <- as.character(package_full$tracking_number)
package_activity_weather_summary_full <-
   package_activity_weather_summary_full %>%
   left_join(package_full, by = c("tracking_number" = "tracking_number"))
package_remainder <- package_activity_weather_summary_full[!package_activity_weather_summary_full$tracking_number %in% package_activity_weather_summary$tracking_number,]

# We now have the remainder data set (all records that were not used for training or testing).  Feed
# them into our random forest model.
package_forest_predict_remainder <- predict(package_forest, newdata = package_remainder, type="prob")
package_forest_prediction_remainder <- prediction(package_forest_predict_remainder[,2], package_remainder$was_delayed_weather)
as.numeric(performance(package_forest_prediction_remainder, "auc")@y.values) # 0.920
package_forest_perf_remainder <- performance(package_forest_prediction_remainder, "tpr", "fpr")
plot(package_forest_perf_remainder,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.030, 0.002), text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     title(main = paste("Random Forest (Remainder Data) ROC (AUC ", round(as.numeric(performance(package_forest_prediction_remainder, "auc")@y.values), 3), ")", sep = "")))



ggsave(filename = "random_forest_remainder_roc")

?plot
?text



# table(package_test$was_delayed_weather, package_forest_predict_test[,2] > 0.04)


