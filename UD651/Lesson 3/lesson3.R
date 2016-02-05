# setup
install.packages('ggplot2')
library(ggplot2)
install.packages('gridExtra') 
library(gridExtra) 

names(pf)

ggplot(aes(x = friend_count), data = pf) + 
   geom_bar() + 
   scale_x_discrete(breaks = 1:31) 

ggplot(data = pf, aes(x = friend_count)) + 
   geom_bar() + 
   scale_x_discrete(breaks = 1:31) + 
   facet_wrap(~dob_month, ncol = 3) 




qplot(x = friend_count, data=pf)
summary(pf$friend_count)
summary(log10(pf$friend_count + 1))
summary(sqrt(pf$friend_count))




qplot( x = friend_count, y = ..count../sum(..count..),
       data = subset(pf, !is.na(gender)),
       xlab = 'Friend Count',
       ylab = 'Proportion of Users with that friend count',
       binwidth = 10, geom = 'freqpoly', color = gender) +
   scale_x_continuous(lim = c(0, 1000), breaks = seq(0, 1000, 50))



qplot(data = subset(pf, !is.na(gender)),
      x = www_likes,
      geom = 'freqpoly',
      color = gender) +
   scale_x_continuous(lim = c(0, 2000), breaks = seq(0, 2000, 50)) +
   scale_x_log10()

by(pf$www_likes, pf$gender, sum)


summary(pf$www_likes)







grid.arrange(
qplot(x = friend_count, data = pf),
qplot(x = friend_count, data = pf) +
   scale_y_log10(),
qplot(x = friend_count, data = pf) +
   scale_y_sqrt(), ncol=1)



p1 <- ggplot(aes(x = friend_count), data = pf) + geom_histogram()
p2 <- p1 + scale_x_log10()
p3 <- p1 + scale_x_sqrt()

grid.arrange(p1, p2, p3, ncol = 1)


qplot(x = friend_count, data = subset(pf, !is.na(gender)), binwidth = 25) +
   scale_x_continuous(limits = c(0, 1000), breaks = seq(0, 1000, 50)) +
   facet_wrap(~gender) 


qplot(x = gender,
      y = friend_count,
      data = subset(pf, !is.na(gender)),
      geom = 'boxplot') +
   coord_cartesian(ylim = c(0, 250, 50))


by(pf$friendships_initiated, pf$gender, summary)
by(pf$friendships_initiated, pf$gender, sum)


summary(pf$mobile_likes)
summary(pf$mobile_likes > 0)

pf$mobile_check_in <- NA
pf$mobile_check_in <- ifelse(pf$mobile_likes > 0, 1, 0)
pf$mobile_check_in <- factor(pf$mobile_check_in)
summary(pf$mobile_check_in)


pf$mobile_check_in

sum(pf$mobile_check_in == 1) / length(pf$mobile_check_in)


ifelse(pf$mobile_likes > 0, 1, 0)


mean.default(pf$mobile_check_in)



names(pf)



+
   scale_y_continuous(limits = c(0, 1000), breaks = seq(0, 1000, 50)) +
   facet_wrap(~gender) 



table(pf$gender)
by(pf$friend_count, pf$gender, summary)

qplot(x = tenure/365, data = pf,
      xlab = 'Number of years using Facebook',
      ylab = 'Number of users in sample',
      binwidth = 1, color = I('black'), fill = I('#099DD9')) +
   scale_x_continuous(breaks = seq(1, 7, 1), lim = c(0, 7))
   
qplot(x = age, data = pf,
      binwidth = 1,
      color = I('black'), fill = I('#099DD9')) +
scale_x_continuous(breaks = seq(13, 120, 1), lim = c(13, 120))


qplot(x = age, data = pf,
      color = I('black'), fill = I('#099DD9'))







