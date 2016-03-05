library(dplyr)
library(caTools)
library(ROCR)
library(gridExtra) 
library(GGally)
library(randomForest)
library(rpart)
library(rpart.plot)
library(ggplot2)

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

# split the data into training and testing sets (60% training)
split <- sample.split(package_activity_weather_summary$was_delayed, 0.60)
package_train <- subset(package_activity_weather_summary, split == TRUE)
package_test <- subset(package_activity_weather_summary, split == FALSE)

# clean up
remove(split, package, package_activity, weather, package_activity_weather, package_activity_weather_summary)

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
# logistic multiple regression

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
summary(logistic_model_weather) # AIC: 23471

# after paring all the irrelevant variables down, we're left with this model:
logistic_model_weather <-
   glm(was_delayed_weather ~
          visibility_mean + dry_bulb_celsius_mean + relative_humidity_mean + wind_speed_mean + station_pressure_mean +
          visibility_max + relative_humidity_max + hourly_precip_max +
          visibility_min + dry_bulb_celsius_min + relative_humidity_min + wind_speed_min + station_pressure_min,
       data = package_train,
       family = "binomial")
summary(logistic_model_weather) # AIC: 23469

# Calculate the AUC for the training data
logistic_model_predict_train <- predict(logistic_model_weather, type = "response", newdata = package_train)
logistic_model_prediction_train <- prediction(logistic_model_predict_train, package_train$was_delayed_weather)
as.numeric(performance(logistic_model_prediction_train, "auc")@y.values) # 0.795
logistic_model_performance_tpr_fpr_train <- performance(logistic_model_prediction_train, "tpr", "fpr")
png(filename = "logistic-multiple-regression-roc-train.png", width = 10, height = 8, units = "in", res = 300)
plot(logistic_model_performance_tpr_fpr_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Logistic Multiple Regression (Training Data) ROC (AUC ", round(as.numeric(performance(logistic_model_prediction_train, "auc")@y.values), 3), ")", sep = ""))
dev.off()

# Feed in the test data.
logistic_model_predict_test <- predict(logistic_model_weather, type = "response", newdata = package_test)
logistic_model_prediction_test <- prediction(logistic_model_predict_test, package_test$was_delayed_weather)
as.numeric(performance(logistic_model_prediction_test, "auc")@y.values) # 0.790
logistic_model_performance_tpr_fpr_test <- performance(logistic_model_prediction_test, "tpr", "fpr")
png(filename = "logistic-multiple-regression-roc-test.png", width = 10, height = 8, units = "in", res = 300)
plot(logistic_model_performance_tpr_fpr_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Logistic Multiple Regression (Test Data) ROC (AUC ", round(as.numeric(performance(logistic_model_prediction_test, "auc")@y.values), 3), ")", sep = ""))
dev.off()

# with this information, and given that the problem set wants to minimize the false negative rate,
# choose 0.018 as the threshold, giving:
table(package_test$was_delayed_weather, logistic_model_predict_test > 0.05)

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
pdf(file = "decision-tree-plot.pdf", width = 10, height = 8)
prp(package_tree)
dev.off()
package_tree_perf_test <- performance(package_tree_prediction_test, "tpr", "fpr")
png(filename = "decision-tree-roc-test.png", width = 10, height = 8, units = "in", res = 300)
plot(package_tree_perf_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Decision Tree (Testing Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_test, "auc")@y.values), 3), ")", sep = ""))
dev.off()

# This tree is very complicated; seems like it might be over-fit.  What is the AUC when used on the training data?
package_tree_predict_train <- predict(package_tree, newdata = package_train)
package_tree_prediction_train <- prediction(package_tree_predict_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_tree_prediction_train, "auc")@y.values) # 0.868
package_tree_perf_train <- performance(package_tree_prediction_train, "tpr", "fpr")
png(filename = "decision-tree-roc-train.png", width = 10, height = 8, units = "in", res = 300)
plot(package_tree_perf_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Decision Tree (Training Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_train, "auc")@y.values), 3), ")", sep = ""))
dev.off()

# The tree is very complicated -- it seems to be over-fit.  However, we see an AUC of 0.868 when using the
# training data and an AUC of 0.849 when using the testing data, which seems reasonable.  The data is a little
# over-fit, but still seems to be a good predictor of the testing data.  We need to throw more unseen data at the
# model to be sure, however.

# Still, let's see if we can prune the tree to reduce the complexity.  Prune the tree at the minimum 'xerror' point.
printcp(package_tree)
png(filename = "decision-tree-complexity-parameter.png", width = 10, height = 8, units = "in", res = 300)
plotcp(package_tree)
dev.off()
package_tree_pruned <- prune(package_tree, cp = package_tree$cptable[which.min(package_tree$cptable[,"xerror"]),"CP"])
printcp(package_tree_pruned)
png(filename = "decision-tree-complexity-parameter-pruned.png", width = 10, height = 8, units = "in", res = 300)
plotcp(package_tree_pruned)
dev.off()
package_tree_predict_pruned_test <- predict(package_tree_pruned, newdata = package_test)
package_tree_prediction_pruned_test <- prediction(package_tree_predict_pruned_test[,2], package_test$was_delayed_weather)
as.numeric(performance(package_tree_prediction_pruned_test, "auc")@y.values) # 0.814
package_tree_perf_pruned_test <- performance(package_tree_prediction_pruned_test, "tpr", "fpr")
png(filename = "decision-tree-roc-test-pruned.png", width = 10, height = 8, units = "in", res = 300)
plot(package_tree_perf_pruned_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7), cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Pruned Decision Tree (Testing Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_pruned_test, "auc")@y.values), 3), ")", sep = ""))
dev.off()
pdf(file = "decision-tree-plot-pruned.pdf", width = 10, height = 8)
prp(package_tree_pruned)
dev.off()
package_tree_predict_pruned_train <- predict(package_tree_pruned, newdata = package_train)
package_tree_prediction_pruned_train <- prediction(package_tree_predict_pruned_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_tree_prediction_pruned_train, "auc")@y.values) # 0.842
package_tree_perf_pruned_train <- performance(package_tree_prediction_pruned_train, "tpr", "fpr")
png(filename = "decision-tree-roc-train-pruned.png", width = 10, height = 8, units = "in", res = 300)
plot(package_tree_perf_pruned_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.020, 0.001),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Pruned Decision Tree (Training Data) ROC (AUC ", round(as.numeric(performance(package_tree_prediction_pruned_train, "auc")@y.values), 3), ")", sep = ""))
dev.off()

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
as.numeric(performance(package_forest_prediction_test, "auc")@y.values) # 0.914
package_forest_perf_test <- performance(package_forest_prediction_test, "tpr", "fpr")
png(filename = "random-forest-roc-test.png", width = 10, height = 8, units = "in", res = 300)
plot(package_forest_perf_test,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.030, 0.002),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Random Forest (Test Data) ROC (AUC ", round(as.numeric(performance(package_forest_prediction_test, "auc")@y.values), 3), ")", sep = ""))
dev.off()

# Take a look at the AUC against the training data
package_forest_predict_train <- predict(package_forest, newdata = package_train, type="prob")
package_forest_prediction_train <- prediction(package_forest_predict_train[,2], package_train$was_delayed_weather)
as.numeric(performance(package_forest_prediction_train, "auc")@y.values) # 1.000 (!)
package_forest_perf_train <- performance(package_forest_prediction_train, "tpr", "fpr")
png(filename = "random-forest-roc-train.png", width = 10, height = 8, units = "in", res = 300)
plot(package_forest_perf_train,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.030, 0.002),
     text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Random Forest (Training Data) ROC (AUC ", round(as.numeric(performance(package_forest_prediction_train, "auc")@y.values), 3), ")", sep = ""))
dev.off()
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
package_remainder <-
   package_activity_weather_summary_full[!package_activity_weather_summary_full$tracking_number
                                         %in%
                                         package_train$tracking_number
                                         &
                                         !package_activity_weather_summary_full$tracking_number
                                         %in%
                                         package_test$tracking_number
                                         ,]
remove(package_full, package_activity_full, weather_full, package_activity_weather_full, package_activity_weather_summary_full)

# We now have the remainder data set (all records that were not used for training or testing).  Feed
# them into our random forest model.
package_forest_predict_remainder <- predict(package_forest, newdata = package_remainder, type="prob")
package_forest_prediction_remainder <- prediction(package_forest_predict_remainder[,2], package_remainder$was_delayed_weather)
as.numeric(performance(package_forest_prediction_remainder, "auc")@y.values) # 0.918
package_forest_perf_remainder <- performance(package_forest_prediction_remainder, "tpr", "fpr")
png(filename = "random-forest-roc-remainder.png", width = 10, height = 8, units = "in", res = 300)
plot(package_forest_perf_remainder,
     colorize = TRUE,
     print.cutoffs.at = seq(0.000, 0.030, 0.002), text.adj=c(-0.2, 1.7),
     cutoff.label.function=function(x) { round(x, 3) },
     main = paste("Random Forest (Remainder Data) ROC (AUC ", round(as.numeric(performance(package_forest_prediction_remainder, "auc")@y.values), 3), ")", sep = ""))
dev.off()
package_forest_perf_remainder_acc <- performance(package_forest_prediction_remainder, "acc")

# Null prediction 
#         f   t
# f 1676896   0
# t   10932   0
# accuracy: 99.4%

# add in the predicted values to our data frames
package_test <- cbind(package_test, was_delayed_weather_pred = package_forest_predict_test[,2])
package_train <- cbind(package_train, was_delayed_weather_pred = package_forest_predict_train[,2])
package_remainder <- cbind(package_remainder, was_delayed_weather_pred = package_forest_predict_remainder[,2])

# plot each package over time against the was delayed due to weather prediction,
# coloring the data by the actual weather delay parameter
ggsave(filename = "package_prediction_timeline.png",
       width = 10,
       height = 8,
       dpi = 300,
       units = "in",
       plot =
          ggplot(data = package_remainder[with(package_remainder, order(was_delayed_weather)), ],
                 aes(x = ship_date_time,
                     y = was_delayed_weather_pred,
                     color = was_delayed_weather,
                     alpha = was_delayed_weather)) +
             scale_alpha_discrete(range = c(0.50, 0.50)) +
             geom_point(size = 0.5) +
             xlim(as.POSIXct("2015-06-15 00:00:00"), as.POSIXct("2015-12-31 23:59:59")))
# add in some jitter
ggsave(filename = "package_prediction_timeline_jitter.png",
       width = 10,
       height = 8,
       dpi = 300,
       units = "in",
       plot =
          ggplot(data = package_remainder,
                 aes(x = ship_date_time,
                     y = was_delayed_weather_pred,
                     color = was_delayed_weather,
                     alpha = was_delayed_weather)) +
             scale_alpha_discrete(range = c(0.50, 0.50)) +
             geom_point(size = 0.5, position = position_jitter(w = 200000, h = 0.0)) +
             xlim(as.POSIXct("2015-06-15 00:00:00"), as.POSIXct("2015-12-31 23:59:59")))


   scale_x_discrete(xlim = )

class(package_test$ship_date_time)


 ggplot(data = filter_(package_train_order, paste(i, " <= stats::quantile(", i, ", 0.995) & ", i, " >= stats::quantile(", i, ", 0.005) & ", j, " <= stats::quantile(", j, ", 0.995) & ", j, " >= stats::quantile(", j, ", 0.005)", sep = "")),
        aes_string(x = i,
                   y = j,
                   color = "was_delayed_weather",
                   alpha = "was_delayed_weather")) +
 geom_point() +
 scale_alpha_discrete(range = c(0.03, 0.50)) +
 geom_smooth(alpha = 0.5,
             method = "lm"))




summary(package_remainder)

?cbind

class(package_forest_predict_remainder[,2])

package_forest_prediction_remainder

# Random Forest model with threshold set at 0.15
table(package_remainder$was_delayed_weather, package_forest_predict_remainder[,2] > 0.15)
#         f      t
# f 1674819   2077
# t    6341   4591
# accuracy: 99.5%

# Despite projections that the high accuracy of the null prediction would not be exceeded, we were able to achieve a 0.1% increase.

summary(package_remainder)
summary(package_forest_prediction_remainder)


ggplot(data = package_forest_predict_remainder$ [,2])
head(package_forest_predict_remainder)

package_forest_predict_remainder$f


plot(package_forest_predict_remainder[,2])

