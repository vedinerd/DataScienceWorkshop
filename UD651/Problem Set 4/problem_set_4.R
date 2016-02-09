# setup
library(ggplot2)
data(diamonds)

# Your first task is to create a
# scatterplot of price vs x.
# using the ggplot syntax.
ggplot(aes(x = x, y = price), data = diamonds) +
   geom_point()
ggsave('price_vs_x_scatterplot.png')

# correlation between price and x
with(diamonds, cor.test(price, x))

# correlation between price and y
with(diamonds, cor.test(price, y))

# correlation between price and z
with(diamonds, cor.test(price, z))

# Create a simple scatter plot of price vs depth.
ggplot(aes(x = depth, y = price), data = diamonds) +
   geom_point()
ggsave('price_vs_depth_scatterplot.png')

# Change the code to make the transparency of the
# points to be 1/100 of what they are now and mark
# the x-axis every 2 units. See the instructor notes
# for two hints.
ggplot(data = diamonds, aes(x = depth, y = price)) + 
   geom_point(alpha = 0.01) +
   scale_x_continuous(breaks = seq(43, 79, 2))
ggsave('price_vs_depth_scatterplot2.png')

# correlation between price and depth
with(diamonds, cor.test(price, depth))

# Create a scatterplot of price vs carat
# and omit the top 1% of price and carat
# values.
ggplot(data = subset(diamonds,
                     price <= quantile(price, 0.99) & carat <= quantile(carat, 0.99)),
       aes(x = carat, y = price)) + 
   geom_point()
ggsave('price_vs_carat_scatterplot.png')

# Create a scatterplot of price vs. volume (x * y * z).
# This is a very rough approximation for a diamond's volume.
ggplot(aes(x = (x * y * z), y = price), data = diamonds) +
   geom_point()
ggsave('price_vs_volume_scatterplot.png')

# Create a new variable for volume in the diamonds data frame.
# This will be useful in a later exercise.
diamonds$volume <- diamonds$x * diamonds$y * diamonds$z

# correlation between price and volume, within a certain range
with(subset(diamonds, volume > 0 & volume <= 800), cor.test(price, volume))

# Subset the data to exclude diamonds with a volume
# greater than or equal to 800. Also, exclude diamonds
# with a volume of 0. Adjust the transparency of the
# points and add a linear model to the plot. (See the
# Instructor Notes or look up the documentation of
# geom_smooth() for more details about smoothers.)
ggplot(aes(x = (x * y * z), y = price),
       data = subset(diamonds, volume > 0 & volume <= 800)) +
   geom_point(alpha = 0.05) +
   geom_smooth(method = "lm") +
   ylim(0, 18000)
ggsave('price_vs_volume_scatterplot2.png')

# Do you think this would be a useful model to estimate
# the price of diamonds? Why or why not?

# I think it would be a reasonable approximation if all you needed was an estimate
# within an order of magnitude, but it appears pretty clear that the data is more
# closely approximated by a non-linear model.  Additionally, the data becomes very
# noisy above volume 170 or so.  Even a non-linear model would be pretty bad at
# that point.  But it really depends on what you need the estimate for.

# Use the function dplyr package
# to create a new data frame containing
# info on diamonds by clarity.
library(dplyr)
diamondsByClarity <- diamonds %>%
   group_by(clarity) %>%
   summarize(mean_price = mean(price),
             median_price = median(price),
             min_price = min(price),
             max_price = max(price),
             n = n())

# We’ve created summary data frames with the mean price
# by clarity and color. You can run the code in R to
# verify what data is in the variables diamonds_mp_by_clarity
# and diamonds_mp_by_color.
diamonds_by_clarity <- group_by(diamonds, clarity)
diamonds_mp_by_clarity <- summarise(diamonds_by_clarity, mean_price = mean(price))
diamonds_by_color <- group_by(diamonds, color)
diamonds_mp_by_color <- summarise(diamonds_by_color, mean_price = mean(price))

# Your task is to write additional code to create two bar plots
# on one output image using the grid.arrange() function from the package
# gridExtra.
library(gridExtra)
a <- ggplot(aes(clarity, mean_price), data = diamonds_mp_by_clarity) +
   geom_bar(stat = 'identity')
b <- ggplot(aes(color, mean_price), data = diamonds_mp_by_color) +
   geom_bar(stat = 'identity')
grid.arrange(a, b, ncol = 1)
g <- arrangeGrob(a, b, ncol=1)
ggsave(file='color_and_clarity_groups.png', g)


# The Gapminder website contains over 500 data sets with information about
# the world's population. Your task is to continue the investigation you did at the
# end of Problem Set 3 or you can start fresh and choose a different
# data set from Gapminder.
# In your investigation, examine pairs of variable and create 2-5 plots that make
# use of the techniques from Lesson 4.
library(tidyr)
library(dplyr)

# read in the co2 data from problem set 3
co2Data <-
   read.csv('indicator_CDIAC_carbon_dioxide_total_emissions.csv') %>%
   gather(year, emission_total, X1751:X2011) %>%
   transmute(country = as.character(CO2.emission.total), year = as.numeric(gsub("X", "", year)), emission_total)

# read in BMI data
bmiData <-
   read.csv('Indicator_BMI_male_ASM.csv') %>%
   gather(year, bmi, X1980:X2008) %>%
   transmute(country = as.character(Country), year = as.numeric(gsub("X", "", year)), bmi)

# join the two tables and filter everything out except the top 10 countries by GDP (according to wikipedia)
multivariate <-
   bmiData %>%
   left_join(co2Data, c("country", "year")) %>%
   filter(country %in% c('United States', 'China', 'Japan', 'Germany', 'United Kingdom', 'France', 'India', 'Italy', 'Brazil', 'Canada'))

# first plot emission total vs. bmi for all countries
ggplot(aes(x = emission_total, y = bmi, group = country),
       data = multivariate) +
   geom_point(aes(color = country))
ggsave('bmi_emission_01.png')

# show linear regression lines for each country
ggplot(aes(x = emission_total, y = bmi, group = country),
       data = multivariate) +
   geom_point(aes(color = country)) +
   geom_ribbon(stat='smooth', method = "lm", se=TRUE, alpha=0.1, 
               aes(color = country)) +
   geom_line(stat='smooth', method = "lm", alpha=0.3)   
ggsave('bmi_emission_02.png')

# zoom in on the left hand side
ggplot(aes(x = emission_total, y = bmi, group = country),
       data = multivariate) +
   geom_point(aes(color = country)) +
   geom_ribbon(stat='smooth', method = "lm", se=TRUE, alpha=0.1, 
               aes(color = country)) +
   geom_line(stat='smooth', method = "lm", alpha=0.3) +
   coord_cartesian(xlim = c(0, 1500000),
                   ylim = c(22, 28))
ggsave('bmi_emission_03.png')


