library(dplyr)
library(ggplot2)
pf <- read.csv('pseudo_facebook.tsv', sep = '\t')

summary(pf$friendships_initiated)

qplot(age, friendships_initiated, data = pf)

ggplot(aes(x = age, y = friendships_initiated), data = pf) +
   geom_point(alpha = 1/20, position = position_jitter(h = 0)) +
   xlim(13, 90) +
   coord_trans(y = 'sqrt')


age_groups <- group_by(pf, age)
pf.fc_by_age <- summarize(age_groups,
          friend_count_mean = mean(friend_count),
          friend_count_median = median(friend_count),
          n = n())

head(pf.fc_by_age)

pf.fc_by_age <- arrange(pf.fc_by_age, age)

head(pf.fc_by_age)


pf.fc_by_age <- pf %>%
   group_by(age) %>%
   summarize(friend_count_mean = mean(friend_count),
             friend_count_median = mean(friend_count),
             n = n()) %>%
   arrange(age)

head(pf.fc_by_age, 20)




ggplot(aes(x = age, y = friend_count_mean), data = pf.fc_by_age) +
   geom_line()


ggplot(aes(x = age, y = friendships_initiated), data = pf) +
   geom_point(alpha = 1/20,
              position = position_jitter(h = 0),
              color = 'orange') +
   xlim(13, 90) +
   coord_trans(y = 'sqrt') +
   geom_line(stat = 'summary',
             fun.y = mean) +
   geom_line(stat = 'summary',
             fun.y = quantile,
             fun.args = list(probs = 0.1),
             linetype = 2,
             color = 'blue') +
   geom_line(stat = 'summary',
             fun.y = quantile,
             fun.args = list(probs = 0.5),
             color = 'blue') +
   geom_line(stat = 'summary',
             fun.y = quantile,
             fun.args = list(probs = 0.9),
             linetype = 2,
             color = 'blue') +
   coord_cartesian(xlim = c(13, 90), ylim = c(0, 2000))

names(pf)


ggplot(aes(x = www_likes_received, y = likes_received), data = pf) +
   geom_point() +
   xlim(0, quantile(pf$www_likes_received, 0.95)) +
   ylim(0, quantile(pf$likes_received, 0.95)) +
   geom_smooth(method = 'lm', color = 'red')
   

with(subset(pf), cor.test(likes_received, www_likes_received))

install.packages('car')
library(alr3)

data(Mitchell)



ggplot(aes(x = Month, y = Temp), data = Mitchell) +
   geom_point() +
   scale_x_discrete(breaks = seq(0, 203, 12))

?scale_x_discrete

summary(Mitchell$Month)



with(Mitchell, cor.test(Month, Temp))



install.packages('pbkrtest')
library(pbkrtest)

data(Mitchell)



head(pf)


head(pf$age + (1 - (pf$dob_month / 12)))
head(pf$age)
head(pf$dob_month)


pf$age_with_months <- pf$age + (12 - pf$dob_month) / 12


ggplot(aes(x = likes_received, y = www_likes_received), data = pf) +
   geom_point(alpha = 1/20) +
   scale_x_log10() +
   scale_y_log10()


# Create a new data frame called
# pf.fc_by_age_months that contains
# the mean friend count, the median friend
# count, and the number of users in each
# group of age_with_months. The rows of the
# data framed should be arranged in increasing
# order by the age_with_months variable.

# For example, the first two rows of the resulting
# data frame would look something like...

# age_with_months  friend_count_mean	friend_count_median	n
#              13            275.0000                   275 2
#        13.25000            133.2000                   101 11


pf.fc_by_age_months <-
pf %>%
   group_by(age_with_months) %>%
   summarize(friend_count_mean = mean(friend_count),
             friend_count_median = median(friend_count),
             n = n()) %>%
   arrange(age_with_months)


a <- ggplot(aes(x = age, y = friend_count_mean), data = subset(pf.fc_by_age, age < 71)) +
   geom_line() +
   geom_smooth()

b <- ggplot(aes(x = age_with_months, y = friend_count_mean), data = subset(pf.fc_by_age_months, age_with_months < 71)) +
   geom_line() +
   geom_smooth()

c <- ggplot(aes(x = round(age / 5) * 5, y = friend_count), data = subset(pf, age < 71)) +
   geom_line(stat = 'summary', fun.y = mean)


grid.arrange(b, a, c, ncol=1)




install.packages('gridExtra') 
library(gridExtra) 


# Create a new scatterplot showing friend_count_mean
# versus the new variable, age_with_months. Be sure to use
# the correct data frame (the one you create in the last
# exercise) AND subset the data to investigate
# users with ages less than 71.



pf.fc_by_age_months <- 

   
pf.fc_by_age <- pf %>%
   group_by(age) %>%
   summarize(friend_count_mean = mean(friend_count),
             friend_count_median = mean(friend_count),
             n = n()) %>%
   arrange(age)




   
mean friend count
median friend count
# users in each group with months


   
   coord_trans(x = 'identity', y = 'log10')



?coord_trans



?scale_x_log10   

cor.test(pf$age, pf$friend_count, method = "spearman")

with(subset(pf, age <= 70), cor.test(likes_received, www_likes_received, method = "spearman"))


?cor.test



ggplot(aes(x = age, y = friend_count_mean), data = pf.fc_by_age) +
   geom_point(alpha = 1/20, position = position_jitter(h = 0)) +
   xlim(13, 90) +
   coord_trans(y = 'sqrt')

