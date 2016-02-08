# Investigate the price per carat of diamonds across
# the different colors of diamonds using boxplots.

# Go to the discussions to
# share your thoughts and to discover
# what other people found.

# You can save images by using the ggsave() command.
# ggsave() will save the last plot created.
# For example...
#                  qplot(x = price, data = diamonds)
#                  ggsave('priceHistogram.png')

# ggsave currently recognises the extensions eps/ps, tex (pictex),
# pdf, jpeg, tiff, png, bmp, svg and wmf (windows only).

# Copy and paste all of the code that you used for
# your investigation, and submit it when you are ready.

# SUBMIT YOUR CODE BELOW THIS LINE
# ===================================================================

# setup
library(ggplot2)
data(diamonds)

# Create a histogram of the price of
# all the diamonds in the diamond data set.
ggplot(aes(x = price), data = diamonds) +
   geom_histogram(bins = 250)
ggsave('price_histogram.png')

# get counts by various conditions
length(diamonds$price[diamonds$price < 500])
length(diamonds$price[diamonds$price < 250])
length(diamonds$price[diamonds$price >= 15000])

# Explore the largest peak in the
# price histogram you created earlier.

# Try limiting the x-axis, altering the bin width,
# and setting different breaks on the x-axis.
ggplot(aes(x = price),
       data = diamonds) +
   geom_histogram(breaks = seq(250, 1500, by = 20)) +
   scale_x_continuous(breaks = seq(250, 1500, by = 50)) +
   scale_y_continuous(breaks = seq(0, 700, by = 50))
ggsave('price_histogram_250_1500.png')

# Break out the histogram of diamond prices by cut.
# You should have five histograms in separate
# panels on your resulting plot.
a <- ggplot(aes(x = price),
            data = subset(diamonds, cut == 'Ideal')) +
   geom_histogram() +
   ggtitle('Ideal')
b <- ggplot(aes(x = price),
            data = subset(diamonds, cut == 'Premium')) +
   geom_histogram() +
   ggtitle('Premium')
c <- ggplot(aes(x = price),
            data = subset(diamonds, cut == 'Very Good')) +
   geom_histogram() +
   ggtitle('Very Good')
d <- ggplot(aes(x = price),
            data = subset(diamonds, cut == 'Good')) +
   geom_histogram() +
   ggtitle('Good')
e <- ggplot(aes(x = price),
            data = subset(diamonds, cut == 'Fair')) +
   geom_histogram() +
   ggtitle('Fair')
library(gridExtra)
grid.arrange(a, b, c, d, e, ncol = 1)
ggsave('price_by_cut.png')

# a few statistics by cut
diamond_cut_group <- group_by(diamonds, cut)
summarize(diamond_cut_group,
          price_max = max(price),
          price_min = min(price),
          price_median = median(price))

# Look up the documentation for facet_wrap in R Studio.
# Then, scroll back up and add a parameter to facet_wrap so that
# the y-axis in the histograms is not fixed. You want the y-axis to
# be different for each histogram.
qplot(x = price, data = diamonds) + facet_wrap(~cut, scales="free_y")
ggsave('price_hist_facet_by_cut.png')

# Create a histogram of price per carat
# and facet it by cut. You can make adjustments
# to the code from the previous exercise to get
# started.
ggplot(aes(x = price_per_carat),
       data = diamonds) +
   geom_histogram() +
   facet_wrap(~cut)
ggsave('price_per_carat_hist_facet_by_cut.png')

# Adjust the bin width and transform the scale
# of the x-axis using log10.
ggplot(aes(x = price_per_carat),
       data = diamonds) +
   geom_histogram(breaks = seq(3, 4.2, by = 0.05)) +
   facet_wrap(~cut) +
   scale_x_log10()
ggsave('price_per_carat_hist_facet_by_cut2.png')

# Investigate the price of diamonds using box plots,
# numerical summaries, and one of the following categorical
# variables: cut, clarity, or color.
ggplot(aes(x = color, y = price),
       data = diamonds) +
   geom_boxplot(aes(color = color)) +
   coord_cartesian(ylim = c(0, 10000))

# Investigate the price per carat of diamonds across
# the different colors of diamonds using boxplots.
ggplot(aes(x = color, y = price / carat),
       data = diamonds,
       xlab = 'Color',
       ylab = 'Price per Carat') +
   geom_boxplot(aes(color = color))
ggsave('price_per_carat_boxplots.png')

# frequency polygon for carat with different bin widths
ggplot(aes(x = carat),
       data = diamonds) +
   geom_freqpoly(breaks = seq(0, 5, by = 1.00))
ggsave('freqpoly_carat_1.00.png')
ggplot(aes(x = carat),
       data = diamonds) +
   geom_freqpoly(breaks = seq(0, 5, by = 0.10))
ggsave('freqpoly_carat_0.10.png')
ggplot(aes(x = carat),
       data = diamonds) +
   geom_freqpoly(breaks = seq(0, 5, by = 0.01))
ggsave('freqpoly_carat_0.01.png')


# The Gapminder website contains over 500 data sets with information about
# the world's population. Your task is to download a data set of your choice
# and create 2-5 plots that make use of the techniques from Lesson 3.

# read in some co2 data and tidy it up (melt it so the year columns become one tidy variable)
install.packages("tidyr")
library(tidyr)
library(dplyr)
co2data <-
   read.csv('indicator_CDIAC_carbon_dioxide_total_emissions.csv') %>%
   gather(year, emission_total, X1751:X2011) %>%
   transmute(country = CO2.emission.total, year = as.numeric(gsub("X", "", year)), emission_total)

# plot the co2 emissions for the top 10 economies by GDP (from wikipedia)
ggplot(aes(x = year, y = emission_total, group = country),
       data = filter(co2data, country %in%
                        c('United States', 'China', 'Japan', 'Germany', 'United Kingdom', 'France', 'India', 'Italy', 'Brazil', 'Canada') &
                        !is.na(emission_total))) +
   geom_line(aes(color = country)) +
   scale_x_continuous(breaks = seq(min(co2data$year), max(co2data$year), by = 10))
ggsave('co2_01.png')

# zoom in on the period from 1901 to 2011
ggplot(aes(x = year, y = emission_total, group = country),
       data = filter(co2data, country %in%
                        c('United States', 'China', 'Japan', 'Germany', 'United Kingdom', 'France', 'India', 'Italy', 'Brazil', 'Canada') &
                        !is.na(emission_total))) +
   geom_line(aes(color = country)) +
   scale_x_continuous(breaks = seq(as.numeric(min(co2data$year)), as.numeric(max(co2data$year)), by = 10),
                      limits = c(1901, 2011))
ggsave('co2_02.png')

# change the y-scale to log10
ggplot(aes(x = year, y = emission_total, group = country),
       data = filter(co2data, country %in%
                        c('United States', 'China', 'Japan', 'Germany', 'United Kingdom', 'France', 'India', 'Italy', 'Brazil', 'Canada') &
                        !is.na(emission_total))) +
   geom_line(aes(color = country)) +
   scale_x_continuous(breaks = seq(as.numeric(min(co2data$year)), as.numeric(max(co2data$year)), by = 10),
                      limits = c(1901, 2011)) +
   scale_y_log10()
ggsave('co2_03.png')

# y-scale back to linear, but zoom y-scale from 0 to 2,000,000
ggplot(aes(x = year, y = emission_total, group = country),
       data = filter(co2data, country %in%
                        c('United States', 'China', 'Japan', 'Germany', 'United Kingdom', 'France', 'India', 'Italy', 'Brazil', 'Canada') &
                        !is.na(emission_total))) +
   geom_line(aes(color = country)) +
   scale_x_continuous(breaks = seq(as.numeric(min(co2data$year)), as.numeric(max(co2data$year)), by = 10),
                      limits = c(1901, 2011)) +
   scale_y_continuous(breaks = seq(0, 2000000, 100000),
                      limits = c(0, 2000000))
ggsave('co2_04.png')

# birthday data
birthdayData <-
   read.csv('birthdaysExample.csv')  %>%
   transmute(date = as.Date(dates, format = '%m/%d/%y'))

# How many people share your birthday? Do you know them?
subset(birthdayData, date == '2014-08-09')
# 3

# Which month contains the most number of birthdays?
birthdayMonthGroup <-
   group_by(birthdayData, format(date, "%b")) %>%
   summarize(n = n())
subset(birthdayMonthGroup, n == max(n))
# March - 98

# How many birthdays are in each month?
birthdayMonthGroup

# Which day of the year has the most number of birthdays?
birthdayDateGroup <-
   group_by(birthdayData, date) %>%
   summarize(n = n())
subset(birthdayDateGroup, n == max(n))
# 8 on each of 2014-02-06, 2014-05-22, and 2014-07-16

# Do you have at least 365 friends that have birthdays on everyday
# of the year?
# see data; no
