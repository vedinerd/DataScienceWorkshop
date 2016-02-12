tweets <- read.csv("tweets.csv", stringsAsFactors = FALSE)
tweets$Negative = as.factor(tweets$Avg <= -1)

table(tweets$Negative)

library(tm)
library(SnowballC)

corpus = Corpus(VectorSource(tweets$Tweet))
corpus[[1]]$content



corpus <- tm_map(corpus, tolower)
corpus <- tm_map(corpus, PlainTextDocument)
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeWords, c("apple", stopwords("english")))
corpus[[1]]$content
corpus <- tm_map(corpus, stemDocument)


frequencies <- DocumentTermMatrix(corpus)

frequencies

inspect(frequencies[1000:1005,505:515])

findFreqTerms(frequencies, lowfreq = 20)
findFreqTerms(frequencies, lowfreq = 100)

sparse <- removeSparseTerms(frequencies, 0.995)

sparse

tweetsSparse <- as.data.frame(as.matrix(sparse))
colnames(tweetsSparse) <- make.names(colnames(tweetsSparse))

tweetsSparse$Negative <- tweets$Negative

library(caTools)

set.seed(123)

split <- sample.split(tweetsSparse$Negative, SplitRatio = 0.7)
trainSparse <- subset(tweetsSparse, split == TRUE)
testSparse <- subset(tweetsSparse, split == FALSE)

library(rpart)
library(rpart.plot)

tweetCART <- rpart(Negative ~ ., data = trainSparse, method = "class")
prp(tweetCART)

predictCART <- predict(tweetCART, newdata = testSparse, type = "class")

table(testSparse$Negative, predictCART)
(294+18)/(294+6+37+18)

table(testSparse$Negative)
300/355

library(randomForest)

set.seed(123)

tweetRF <- randomForest(Negative ~ ., data = trainSparse)

predictRF <- predict(tweetRF, newdata = testSparse)

table(testSparse$Negative, predictRF)
(293+21)/(293+7+34+21)

prp(tweetRF)

tweetLog <- glm(Negative ~ ., data = trainSparse, family = binomial)

predictions <- predict(tweetLog, newdata = testSparse, type = "response")

table(testSparse$Negative, predictions)

(253+33)/(253+47+22+33)


emails <- read.csv("energy_bids.csv", stringsAsFactors = FALSE)
str(emails)

strwrap(emails$email[2])

emails$responsive[2]

table(emails$responsive)

library(tm)
corpus = Corpus(VectorSource(emails$email))
strwrap(corpus[[1]])
corpus <- tm_map(corpus, tolower)
corpus = tm_map(corpus, PlainTextDocument)
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeWords, stopwords("english"))
corpus <- tm_map(corpus, stemDocument)

strwrap(corpus[[1]])


dtm <- DocumentTermMatrix(corpus)

dtm

dtm <- removeSparseTerms(dtm, 0.97)
dtm
labeledTerms <- as.data.frame(as.matrix(dtm))
labeledTerms$responsive <- emails$responsive

str(labeledTerms)


library(caTools)
set.seed(144)
spl <- sample.split(labeledTerms$responsive, 0.7)
train <- subset(labeledTerms, spl == TRUE)
test <- subset(labeledTerms, spl == FALSE)

library(rpart)
library(rpart.plot)

emailCART <- rpart(responsive ~ ., data = train, method = "class")

prp(emailCART)
pred <- predict(emailCART, newdata = test)

 
pred[1:10,]

pred.prob <- pred[,2]

table(test$responsive, pred.prob >= 0.5)

(195+25)/(195+20+17+25)

table(test$responsive)

(215)/(215+42)



