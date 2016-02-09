library(ggplot2)
library(tidyr)
library(dplyr)
library(RColorBrewer)
library(gridExtra)
data(diamonds)

# Create a histogram of diamond prices.
# Facet the histogram by diamond color
# and use cut to color the histogram bars.

# The plot should look something like this.
# http://i.imgur.com/b5xyrOu.jpg

# Note: In the link, a color palette of type
# 'qual' was used to color the histogram using
# scale_fill_brewer(type = 'qual')
ggplot(aes(x = price),
       data = diamonds) +
   geom_histogram(aes(fill = cut), binwidth = 0.08) +
   scale_fill_brewer(type = 'qual') +
   facet_wrap( ~ color) +
   scale_x_log10()
ggsave('price_color_facet_cut.png')


# Create a scatterplot of diamond price vs.
# table and color the points by the cut of
# the diamond.

# The plot should look something like this.
# http://i.imgur.com/rQF9jQr.jpg

# Note: In the link, a color palette of type
# 'qual' was used to color the scatterplot using
# scale_color_brewer(type = 'qual')
ggplot(aes(x = table, y = price),
       data = diamonds) +
   geom_point(aes(color = cut)) +
   scale_x_continuous(breaks = seq(40, 100, 1)) +
   scale_color_brewer(type = 'qual')
ggsave('table_vs_price_by_cut.png')


# Create a scatterplot of diamond price vs.
# volume (x * y * z) and color the points by
# the clarity of diamonds. Use scale on the y-axis
# to take the log10 of price. You should also
# omit the top 1% of diamond volumes from the plot.
# Note: Volume is a very rough approximation of
# a diamond's actual volume.
ggplot(aes(x = x * y * z, y = price),
       data = filter(diamonds, x * y * z <= quantile(x * y * z, 0.99))) +
   geom_point(aes(color = clarity)) +
   scale_y_log10() +
   scale_color_brewer(type = 'div')
ggsave('volume_vs_price_by_clarity.png')


# Many interesting variables are derived from two or more others.
# For example, we might wonder how much of a person's network on
# a service like Facebook the user actively initiated. Two users
# with the same degree (or number of friends) might be very
# different if one initiated most of those connections on the
# service, while the other initiated very few. So it could be
# useful to consider this proportion of existing friendships that
# the user initiated. This might be a good predictor of how active
# a user is compared with their peers, or other traits, such as
# personality (i.e., is this person an extrovert?).

# Your task is to create a new variable called 'prop_initiated'
# in the Pseudo-Facebook data set. The variable should contain
# the proportion of friendships that the user initiated.
pf <- read.csv('pseudo_facebook.tsv', sep = '\t')
pf$prop_initiated <- pf$friendships_initiated / pf$friend_count

# Create a line graph of the median proportion of
# friendships initiated ('prop_initiated') vs.
# tenure and color the line segment by
# year_joined.bucket.
pf$year_joined <- floor(2014 - (pf$tenure / 365))
pf$year_joined.bucket <-
   cut(pf$year_joined,
       c(2004, 2009, 2011, 2012, 2014),
       right = TRUE)
ggplot(aes(x = tenure, y = prop_initiated),
       data = subset(pf, !is.na(year_joined.bucket) & !is.nan(prop_initiated))) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = median)
ggsave('prop_initiated_vs_tenure_by_year_joined_bucket.png')


# Smooth the last plot you created of
# of prop_initiated vs tenure colored by
# year_joined.bucket. You can bin together ranges
# of tenure or add a smoother to the plot.
ggplot(aes(x = tenure, y = prop_initiated),
       data = subset(pf, !is.na(year_joined.bucket) & !is.nan(prop_initiated))) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = median) +
   geom_smooth()
ggsave('prop_initiated_vs_tenure_by_year_joined_bucket_smooth.png')

# mean of (2012,2014] group
mean(subset(pf, year_joined.bucket == "(2012,2014]" & !is.nan(prop_initiated))$prop_initiated)

# Create a scatter plot of the price/carat ratio
# of diamonds. The variable x should be
# assigned to cut. The points should be colored
# by diamond color, and the plot should be
# faceted by clarity.
ggplot(aes(x = cut, y = price / carat),
       data = diamonds) +
   geom_point(aes(color = color), position = position_jitter(h = 0)) +
   facet_wrap( ~ clarity) +
   scale_color_brewer(type = 'div')
ggsave('price_carat_vs_cut_by_color.png')


# The Gapminder website contains over 500 data sets with information about
# the world's population. Your task is to continue the investigation you did at the
# end of Problem Set 4 or you can start fresh and choose a different
# data set from Gapminder.
# In your investigation, examine 3 or more variables and create 2-5 plots that make
# use of the techniques from Lesson 5.
# read in the co2 data from problem set 3
co2.data <-
   read.csv('indicator_CDIAC_carbon_dioxide_emissions_per_capita.csv') %>%
   gather(year, emission_per_capita, X1751:X2012) %>%
   transmute(country = as.character(CO2.per.capita), year = as.numeric(gsub("X", "", year)), emission_per_capita)
gdp.data <-
   read.csv('indicator_gapminder_gdp_per_capita_ppp.csv') %>%
   gather(year, gdp_per_capita, X1800:X2015) %>%
   transmute(country = as.character(GDP.per.capita), year = as.numeric(gsub("X", "", year)), gdp_per_capita)

# join the two tables, and filter out empty rows (there seem to be a lot in the GDP data)
multivariate <-
   gdp.data %>%
   inner_join(co2.data, c("country", "year")) %>%
   filter(!is.na(gdp_per_capita) & !is.na(emission_per_capita))

# a summary of the data shows that to split the data into four quartiles,
# we should cut it by GDP at (142,1998], (1998, 4154], (4154, 10202], (10202, 182668]
summary(multivariate)
multivariate$gdp_quartile <-
   cut(multivariate$gdp_per_capita,
       c(142, 1998, 4154, 10202, 182668))

# plot the gdp_per_capita vs. emission_per_capita and color the data by the GDP quartile
ggplot(aes(x = emission_per_capita, y = gdp_per_capita),
       data = filter(multivariate,
                     !is.na(gdp_quartile) & !is.na(emission_per_capita))) +
   geom_point(aes(color = gdp_quartile), alpha = 0.30) +
   scale_x_log10() +
   scale_y_log10()
ggsave('gdp_per_capita_vs_emission_per_capita.png')

# split this plot out over three different year groups
grid.arrange(
   ggplot(aes(x = emission_per_capita, y = gdp_per_capita),
          data = filter(multivariate,
                        !is.na(gdp_quartile) & !is.na(emission_per_capita) & year <= 1945)) +
      geom_point(aes(color = gdp_quartile), alpha = 0.30) +
      ggtitle("<= 1940") +
      scale_x_log10() +
      scale_y_log10() +
      coord_cartesian(xlim = c(0.001, 100), ylim = c(100, 1000000)),
   ggplot(aes(x = emission_per_capita, y = gdp_per_capita),
          data = filter(multivariate,
                        !is.na(gdp_quartile) & !is.na(emission_per_capita) & year > 1945 & year <= 1980)) +
      geom_point(aes(color = gdp_quartile), alpha = 0.30) +
      ggtitle("> 1945 and <= 1980") +
      scale_x_log10() +
      scale_y_log10() +
      coord_cartesian(xlim = c(0.001, 100), ylim = c(100, 1000000)),
   ggplot(aes(x = emission_per_capita, y = gdp_per_capita),
          data = filter(multivariate,
                        !is.na(gdp_quartile) & !is.na(emission_per_capita) & year > 1980)) +
      geom_point(aes(color = gdp_quartile), alpha = 0.30) +
      ggtitle("> 1981") +
      scale_x_log10() +
      scale_y_log10() +
      coord_cartesian(xlim = c(0.001, 100), ylim = c(100, 1000000)))
ggsave('gdp_per_capita_vs_emission_per_capita_year_group.png')

   




