# Author: Youssef El Faqir El Rhazoui
# Date: 19/04/2019
# You have to set the workspace on the repo root path

rm(list=ls())

library(twitteR)

source ("twitter_scripts/twitter_conexion.R")

# Get cities dataframe
cities <- read.csv("datawarehouse/top10_population_cities.csv", sep = ";", fileEncoding = "UTF-8", header=TRUE)

# Check if there are today's trends
date <- Sys.Date()
str <- paste("datawarehouse/raw/trends/trends_", date, ".csv", sep="")
previous_trends <- data.frame()
if (file.exists(str)) {
  previous_trends <- read.csv(str, sep = ";", fileEncoding = "UTF-8", header=TRUE)
  print(sprintf("'%s' already exist, appending new trends...", str))
}

# Let's get city trends
city_trend <- data.frame()
trends <- data.frame()

for(i in 1:nrow(cities)){
  city_trend <- getTrends(woeid = cities[i, ]$Woeid)
  city_trend[, c("City")] <- cities[i, ]$Name
  
  # if there are previous trends, we'll filter news
  if(nrow(previous_trends) > 0) {
    filter_ <- data.frame()
    for(j in 1:nrow(city_trend)) {
      prev_cities <- previous_trends[previous_trends$woeid == city_trend$woeid, ]
      if(! city_trend[j, ]$name %in% prev_cities$name ) {
          filter_ <- rbind(filter_, city_trend[j, ])
      }
    }
    city_trend <- filter_
  }
  
  trends <- rbind(trends, city_trend)
}
print(sprintf("Collected %d trends of %d cities", nrow(trends), nrow(cities)))

# Time to search tweets
tweets <- data.frame()

for(i in 1:nrow(trends)){
  city <- cities[which(cities$Woeid == trends[i, ]$woeid), ]
  str_geo <- paste(city$Latitude, city$Longitude, city$Radius, sep=",")
  trend_tweets <- searchTwitter(trends[i, ]$name, n=500, geocode=str_geo)

  if (length(trend_tweets) > 0){
    # clean response
    aux <- vector(mode="character")
    for(tweet in trend_tweets){
      aux <- c(aux, tweet$text)
    }

    aux <- data.frame(Tweets = aux, stringsAsFactors = FALSE)
    aux[, c("Trending")] <- trends[i, ]$name
    aux[, c("City")] <- city$Name
    aux[, c("Woeid")] <- city$Woeid

    tweets <- rbind(tweets, aux)
  }
  print(sprintf("Collected %d tweets from %d of %d trends", nrow(tweets), i, nrow(trends)))
}


# Save tweets and trends in a file
write.table(trends, row.names = FALSE, file = str, sep = ";", fileEncoding = "UTF-8", append = TRUE)
str <- paste("datawarehouse/raw/tweets/tweets_", date, ".csv", sep="")
write.table(tweets, row.names = FALSE, file = str, sep = ";", fileEncoding = "UTF-8", append = TRUE)