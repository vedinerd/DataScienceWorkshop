library(dplyr)
library(ggplot2)
pf <- read.csv('pseudo_facebook.tsv', sep = '\t')

ggplot(aes(x = gender, y = age),
       data = subset(pf, !is.na(gender))) +
   geom_boxplot() +
   stat_summary(fun.y = mean, geom = 'point', shape = 4)

ggplot(aes(x = age, y = friend_count),
       data = subset(pf, !is.na(gender))) +
   geom_line(aes(color = gender), stat = 'summary', fun.y = median)

# Write code to create a new data frame,
# called 'pf.fc_by_age_gender', that contains
# information on each age AND gender group.
# The data frame should contain the following variables:
#    mean_friend_count,
#    median_friend_count,
#    n (the number of users in each age and gender grouping)
pf.fc_by_age_gender <-
   pf %>%
   filter(!is.na(gender)) %>%
   group_by(age, gender) %>%
   summarize(mean_friend_count = mean(friend_count),
             median_friend_count = median(friend_count),
             n = n()) %>%
   ungroup()

# Create a line graph showing the
# median friend count over the ages
# for each gender. Be sure to use
# the data frame you just created,
# pf.fc_by_age_gender.
ggplot(aes(x = age, y = median_friend_count),
       data = pf.fc_by_age_gender) +
   geom_line(aes(color = gender))


library(reshape2)

pf.fc_by_age_gender.wide <- dcast(pf.fc_by_age_gender,
                                  age ~ gender,
                                  value.var = 'median_friend_count')


# Plot the ratio of the female to male median
# friend counts using the data frame
# pf.fc_by_age_gender.wide.

# Think about what geom you should use.
# Add a horizontal line to the plot with
# a y intercept of 1, which will be the
# base line. Look up the documentation
# for geom_hline to do that. Use the parameter
# linetype in geom_hline to make the
# line dashed.

# The linetype parameter can take the values 0-6:
# 0 = blank, 1 = solid, 2 = dashed
# 3 = dotted, 4 = dotdash, 5 = longdash
# 6 = twodash

ggplot(aes(x = age, y = female / male),
       data = pf.fc_by_age_gender.wide) +
   geom_line() +
   geom_hline(yintercept = 1, alpha = 0.3, linetype = 2)


# Create a variable called year_joined
# in the pf data frame using the variable
# tenure and 2014 as the reference year.
# The variable year joined should contain the year
# that a user joined facebook.
pf$year_joined <- floor(2014 - (pf$tenure / 365))


# Create a new variable in the data frame
# called year_joined.bucket by using
# the cut function on the variable year_joined.
# You need to create the following buckets for the
# new variable, year_joined.bucket
#        (2004, 2009]
#        (2009, 2011]
#        (2011, 2012]
#        (2012, 2014]
# Note that a parenthesis means exclude the year and a
# bracket means include the year.
pf$year_joined.bucket <-
   cut(pf$year_joined,
       c(2004, 2009, 2011, 2012, 2014),
       right = TRUE)

table(pf$year_joined.bucket)

# Create a line graph of friend_count vs. age
# so that each year_joined.bucket is a line
# tracking the median user friend_count across
# age. This means you should have four different
# lines on your plot.
# You should subset the data to exclude the users
# whose year_joined.bucket is NA.
ggplot(aes(x = age, y = friend_count),
       data = subset(pf, !is.na(year_joined.bucket))) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = median)


# (1) Add another geom_line to code below
# to plot the grand mean of the friend count vs age.
# (2) Exclude any users whose year_joined.bucket is NA.
# (3) Use a different line type for the grand mean.
ggplot(aes(x = age, y = friend_count),
       data = subset(pf, !is.na(year_joined.bucket))) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = mean) +
   geom_line(stat = 'summary',
             fun.y = mean,
             linetype = 5,
             alpha = 0.5)

with(subset(pf, tenure >= 1), summary(friend_count / tenure))


# Create a line graph of mean of friendships_initiated per day (of tenure)
# vs. tenure colored by year_joined.bucket.
# You need to make use of the variables tenure,
# friendships_initiated, and year_joined.bucket.
# You also need to subset the data to only consider user with at least
# one day of tenure.
ggplot(aes(x = tenure, y = friendships_initiated / tenure),
       data = subset(pf, tenure >= 1)) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = mean)


# Instead of geom_line(), use geom_smooth() to add a smoother to the plot.
# You can use the defaults for geom_smooth() but do color the line
# by year_joined.bucket
ggplot(aes(x = 7 * round(tenure / 7), y = friendships_initiated / tenure),
       data = subset(pf, tenure > 0)) +
   geom_smooth(aes(color = year_joined.bucket))



yo <- read.csv('yogurt.csv')

yo$id <- factor(yo$id)

ggplot(aes(x = price), data = yo) + geom_histogram(breaks = seq(10, 80, 10))


summary(yo)
length(unique(yo$price))

?seq

?transform


# Create a new variable called all.purchases,
# which gives the total counts of yogurt for
# each observation or household.

# One way to do this is using the transform
# function. You can look up the function transform
# and run the examples of code at the bottom of the
# documentation to figure out what it does.

# The transform function produces a data frame
# so if you use it then save the result to 'yo'!

# OR you can figure out another way to create the
# variable.

yo$all.purchases <- yo$strawberry + yo$blueberry + yo$pina.colada + yo$plain + yo$mixed.berry


ggplot(aes(x = all.purchases), data = yo) + geom_histogram()


# Create a scatterplot of price vs time.
ggplot(aes(x = time, y = price),
       data = yo) +
   geom_point(alpha = 0.05)


set.seed(4230)
sample.ids <- sample(levels(yo$id), 16)

ggplot(aes(x = time, y = price),
       data = subset(yo, id %in% sample.ids)) +
   facet_wrap( ~ id) +
   geom_line() +
   geom_point(aes(size = all.purchases), pch = 1)

set.seed(1978)
sample.ids <- sample(levels(yo$id), 16)

ggplot(aes(x = time, y = price),
       data = subset(yo, id %in% sample.ids)) +
   facet_wrap( ~ id) +
   geom_line() +
   geom_point(aes(size = all.purchases), pch = 1)




library(GGally)

set.seed(1836)
pf_subset <- pf[, c(2:15)]
names(pf_subset)

ggpairs(pf_subset[sample.int(nrow(pf_subset), 1000), ])


nci <- read.table('nci.tsv')

colnames(nci) <- c(1:64)


library(reshape2)

nci.long.samp <- melt(as.matrix(nci[1:200, ]))
names(nci.long.samp) <- c('gene', 'case', 'value')

head(nci.long.samp)


ggplot(aes(y = gene, x = case, fill = value),
       data = nci.long.samp) +
   geom_tile() +
   scale_fill_gradientn(colors = colorRampPalette(c('blue', 'red'))(100))





ggplot(aes(x = 7 * round(tenure / 7), y = friendships_initiated / tenure),
       data = subset(pf, tenure >= 1)) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = mean)


ggplot(aes(x = 7 * round(tenure / 7), y = friendships_initiated / tenure),
       data = subset(pf, tenure >= 1)) +
   geom_line(aes(color = year_joined.bucket), stat = 'summary', fun.y = mean)







ggplot(aes(x = age, y = friend_count / tenure),
       data = subset(pf, tenure >= 1)) +
   geom_point()


friend_rate <- pf2$friend_count / pf2$tenure

max(friend_rate)
median(friend_rate)

mean(pf$friend_count / pf$tenure)

summary(pf$friend_count / pf$tenure)



?cut

table(pf$year_joined)

summary(pf$year_joined)


2014 - (pf$tenure / 365)


?geom_hline



head(pf.fc_by_age_gender.wide)




head(pf.fc_by_age_gender)
