if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  lhs, gridExtra,stringr, parallel, factoextra, shiny, shinydashboard, DT, robustbase, data.table, htmlwidgets,
  parallel, lhs, ggplot2, rstudioapi, boot, dplyr, rhandsontable,
  RColorBrewer,wordcloud,tm,twitteR,ROAuth,plyr,stringr,base64enc,
  NLP,syuzhet,SnowballC,stringi,topicmodels,wordcloud,ggplot2, tidyr, taskscheduleR, qdap,
  rtweet,dplyr,tidytext, leaflet, rgdal, htmlwidgets, shinycssloaders, widyr, ggraph, igraph
)
download.file(url="http://curl.haxx.se/ca/cacert.pem",destfile="cacert.pem")
# Set constant requestURL
requestURL <- "https://api.twitter.com/oauth/request_token"
# Set constant accessURL
accessURL <- "https://api.twitter.com/oauth/access_token"
# Set constant authURL
authURL <- "https://api.twitter.com/oauth/authorize"
consumerKey <- "mQlBizLfUy4kAhX7KpL4tHLIR"
consumerSecret <- "Panl7AQPfAKGp36S6priHnZnxSXXI07z33vL7X2SJV2V7cXYfZ" 
accessToken <- "889840922825019393-rDamD3WqBEwv9SNovddqYeZat5sXHlh"
accessTokenSecret <- "adifAyNKgcT5lY5H1KsN2DkDzXfcvtnQtTARvtyNLYArU"

setup_twitter_oauth(consumerKey,
                    consumerSecret,
                    accessToken,
                    accessTokenSecret)
twitter_tokens<- create_token(app = "ShinyTwit", consumer_key = consumerKey,
                              consumer_secret = consumerSecret,
                              accessToken,
                              accessTokenSecret)

options(warn = -1)