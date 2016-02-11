movies <- read.table("movieLens.txt", header = FALSE, sep = "|", quote="\"")

str(movies)

colnames(movies) <- c("ID", "Title", "ReleaseDate", "VideoReleaseDate", "IMDB", "Unknown", "Action", "Adventure", "Animation", "Childrens", "Comedy", "Crime", "Documentary", "Drama", "Fantasy", "FilmNoir", "Horror", "Musical", "Mystery", "Romance", "SciFi", "Thriller", "War", "Western")

movies$ID = NULL
movies$ReleaseDate = NULL
movies$VideoReleaseDate = NULL
movies$IMDB = NULL

movies = unique(movies)

str(movies)

table(movies$Romance & movies$Drama)


?table

distances = dist(movies[2:20], method = "euclidian")
clusterMovies = hclust(distances, method = "ward.D")



plot(clusterMovies)

clusterGroups <- cutree(clusterMovies, k = 10)

clusterGroups2 <- cutree(clusterMovies, k = 2)

clusterGroups2

tapply(movies$Unknown, clusterGroups2, mean)
tapply(movies$Action, clusterGroups2, mean)
tapply(movies$Adventure, clusterGroups2, mean)
tapply(movies$Animation, clusterGroups2, mean)
tapply(movies$Childrens, clusterGroups2, mean)
tapply(movies$Comedy, clusterGroups2, mean)
tapply(movies$Crime, clusterGroups2, mean)
tapply(movies$Documentary, clusterGroups2, mean)
tapply(movies$Drama, clusterGroups2, mean)
tapply(movies$Fantasy, clusterGroups2, mean)
tapply(movies$FilmNoir, clusterGroups2, mean)
tapply(movies$Horror, clusterGroups2, mean)
tapply(movies$Musical, clusterGroups2, mean)
tapply(movies$Mystery, clusterGroups2, mean)
tapply(movies$Romance, clusterGroups2, mean)
tapply(movies$SciFi, clusterGroups2, mean)
tapply(movies$Thriller, clusterGroups2, mean)
tapply(movies$War, clusterGroups2, mean)
tapply(movies$Western, clusterGroups2, mean)



str(movies)

tapply(movies$Action, clusterGroups, mean)
tapply(movies$Romance, clusterGroups, mean)

subset(movies, Title == "Men in Black (1997)")
clusterGroups[257]
cluster2 <- subset(movies, clusterGroups == 2)
cluster2$Title[1:10]
head(cluster2)
