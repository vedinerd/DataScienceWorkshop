library(dplyr)

# read all our data in
package_file <- unz("sample_data/package_sample.zip", "package_sample.csv")
package_activity_file <- unz("sample_data/package_activity_sample.zip", "package_activity_sample.csv")
weather_file <- unz("sample_data/weather_sample.zip", "weather_sample.csv")
package <- read.csv(package_file)
package_activity <- read.csv(package_activity_file)
weather <- read.csv(weather_file)
remove(package_file, package_activity_file, weather_file)

# date type conversions
package$ship_date_time <- strptime(package$ship_date_time, "%Y-%m-%d %H:%M:%S")
package$scheduled_delivery_date_time <- strptime(package$scheduled_delivery_date_time, "%Y-%m-%d %H:%M:%S")
package$actual_delivery_date_time <- strptime(package$actual_delivery_date_time, "%Y-%m-%d %H:%M:%S")
package_activity$date_time <- strptime(package_activity$date_time, "%Y-%m-%d %H:%M:%S")
package_activity$rounded_date_time <- strptime(package_activity$rounded_date_time, "%Y-%m-%d %H:%M:%S")
weather$date_time <- strptime(weather$date_time, "%Y-%m-%d %H:%M:%S")

# was_late column
package$was_late <- package$scheduled_delivery_date_time < package$actual_delivery_date_time
package$was_late[is.na]
package <- package %>%
   mutate(was_late = ifelse(is.na(was_late), TRUE, was_late))


