library(dplyr)
library(caTools)
library(ROCR)

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
      select(1, 11:12, 14:18, 20, 22:23) %>%
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

# if we assume no packages delayed as a baseline prediction, we get:
table(package_train$was_delayed_weather)
#   f      t
# f 34,560 0
# t  2,062 0
# 34560 / (2062 + 34560) = 0.9437

logistic_model <-
   glm(was_delayed_weather ~
          visibility_mean +
          dry_bulb_fahrenheit_mean +
          dew_point_fahrenheit_mean +
          relative_humidity_mean +
          wind_speed_mean +
          station_pressure_mean +
          hourly_precip_mean,
       data = package_train)

logistic_model <-
   glm(was_delayed_weather ~
          visibility_mean +
          dry_bulb_fahrenheit_mean +
          relative_humidity_mean +
          wind_speed_mean +
          station_pressure_mean +
          hourly_precip_mean,
       data = package_train)

logistic_model <-
   glm(was_delayed ~
          visibility_mean +
          dry_bulb_fahrenheit_mean +
          relative_humidity_mean +
          wind_speed_mean +
          hourly_precip_mean,
       data = package_train)

logistic_model_weather <-
   glm(was_delayed_weather ~
          visibility_min +
          dry_bulb_fahrenheit_min +
          wind_speed_max +
          hourly_precip_max,
       data = package_train)

summary(logistic_model_weather)

predict_weather <- predict(logistic_model_weather, type = "response", newdata = package_test)
predict_test_weather <- prediction(predict_weather, package_test$was_delayed_weather)
predict_test_perf_weather <- performance(predict_test_weather, "tpr", "fpr")
plot(predict_test_perf_weather, colorize = TRUE)

table(package_test$was_delayed, predict > 0.07)



summary(logistic_model)

