library(dplyr)

##################
# 1) Merges the training and the test sets to create one data set.

# 2) Extracts columns containing mean and standard deviation for each measurement (Hint: Since some
#    feature/column names are repeated, you may need to use the make.names() function in R)

# 3) Creates variables called ActivityLabel and ActivityName that label all observations with the
#    corresponding activity labels and names respectively

# 4) From the data set in step 3, creates a second, independent tidy data set with the average of
#    each variable for each activity and each subject.

##################
# 1) Merges the training and the test sets to create one data set.

# read the data
training.X <- read.table("UCI HAR Dataset/train/X_train.txt", header=FALSE)
training.Y <- read.table("UCI HAR Dataset/train/Y_train.txt", header=FALSE)
test.X <- read.table("UCI HAR Dataset/test/X_test.txt", header=FALSE)
test.Y <- read.table("UCI HAR Dataset/test/Y_test.txt", header=FALSE)

# add the corresponding subject and feature variables as the first columns
training.data <- cbind(training.Y, training.X)
test.data <- cbind(test.Y, test.X)

# combine the training and test data
combined.data <- rbind(training.data, test.data)

# clean up
rm(training.data, test.data, test.Y, test.X, training.Y, training.X)

##################
# 2) Extracts columns containing mean and standard deviation for each measurement (Hint: Since some
#    feature/column names are repeated, you may need to use the make.names() function in R)

# read variable (feature) names, create a complete variable name vector, and set them as the column names
features <- read.table("UCI HAR Dataset/features.txt")$V2
variables <- append(c("ActivityLabel"), make.names(as.character(features), unique=TRUE))
colnames(combined.data) <- variables

# grab just the columns dealing with mean and standard deviation
combined.data.meanstd <- subset(combined.data, , grepl("ActivityLabel|mean|std", variables))

# clean up
rm(features, variables, combined.data)

##################
# 3) Creates variables called ActivityLabel and ActivityName that label all observations with the
#    corresponding activity labels and names respectively

# read in the activity name data and set column names for the join
activity.label <- read.table("UCI HAR Dataset/activity_labels.txt")
colnames(activity.label) <- c("ActivityLabel", "ActivityName")

# join the activity.label table with the combined.data.meanstd table to get the activity names
# note that we reorganize the column order to put the activity name at the start since
# the join put it at the end
combined.data.meanstd <- inner_join(combined.data.meanstd, activity.label)[c(1,81,2:80)]

# clean up
rm(activity.label)

##################
# 4) From the data set in step 3, creates a second, independent tidy data set with the average of
#    each variable for each activity and each subject.

# read in the subject data, appending the training and test data together, and set a column header
training.subject <- read.table("UCI HAR Dataset/train/subject_train.txt", header=FALSE)
test.subject <- read.table("UCI HAR Dataset/test/subject_test.txt", header=FALSE)
combined.subject <- rbind(training.subject, test.subject)
colnames(combined.subject) <- c("SubjectLabel")

# prepend the subject to our data table
combined.data.meanstd <- cbind(combined.subject, combined.data.meanstd)

# group the data by subject and activity, taking the average of the rest of the columns
summary.data <-
  combined.data.meanstd %>%
  group_by(SubjectLabel, ActivityLabel, ActivityName) %>%
  summarise_each(funs(mean))

# save the data to an external file
write.csv(summary.data, file = "summary_data.csv")

# clean up
rm(training.subject, test.subject, combined.subject, combined.data.meanstd, summary.data)
