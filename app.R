x <- c(
  "gridExtra", "stringr", "shiny", "shinydashboard", "DT",
  "data.table", "htmlwidgets", "ggplot2", "boot", "dplyr", "rhandsontable",
  "RColorBrewer", "wordcloud", "tm", "twitteR", "ROAuth", "plyr", "stringr", "base64enc",
  "NLP", "syuzhet", "SnowballC", "stringi", "wordcloud", "ggplot2", "tidyr",
  "rtweet", "dplyr", "rtweet", "shinydashboard", "tidytext", "leaflet", "htmlwidgets",
  "shinycssloaders", "widyr", "igraph"
)

# sudo su - -c "R -e \"install.packages(c('wordcloud','tm','twitteR','ROAuth','plyr','stringr','base64enc'), repos='http://cran.rstudio.com/')\""

# sudo su - -c "R -e \"install.packages(c('NLP','syuzhet','SnowballC','stringi','ggplot2','stringr','tidyr'), repos='http://cran.rstudio.com/')\""

# sudo su - -c "R -e \"install.packages(c('rtweet','dplyr','shinydashboard','tidytext','htmlwidgets','shinycssloaders','widyr', 'igraph', 'ggraph'), repos='http://cran.rstudio.com/')\""


lapply(x, FUN = function(X) {
  do.call("library", list(X))
})

download.file(url = "http://curl.haxx.se/ca/cacert.pem", destfile = "cacert.pem")
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

options(httr_oauth_cache = T)


setup_twitter_oauth(
  consumerKey,
  consumerSecret,
  accessToken,
  accessTokenSecret
)


twitter_tokens <- create_token(
  app = "ShinyTwit", consumer_key = consumerKey,
  consumer_secret = consumerSecret,
  accessToken,
  accessTokenSecret
)
options(warn = -1)


cleanText <- function(x) {
  # extract text
  x_text <- x$text
  # convert all text to lower case
  x_text <- tolower(x_text)
  # Replace blank space ("rt")
  x_text <- gsub("rt", "", x_text)
  # Replace @UserName
  x_text <- gsub("@\\w+", "", x_text)
  # Remove punctuation
  x_text <- gsub("[[:punct:]]", "", x_text)
  # Remove links
  x_text <- gsub("http\\w+", "", x_text)
  # Remove tabs
  x_text <- gsub("[ |\t]{2,}", "", x_text)
  # Remove blank spaces at the beginning
  x_text <- gsub("^ ", "", x_text)
  # Remove blank spaces at the end
  x_text <- gsub(" $", "", x_text)
  return(x_text)
}

server <- function(input, output, session) {
  options(shiny.maxRequestSize = 70 * 1024^2) # Max csv data limit set to 60 mb

  # Page 1 view, maps
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap) %>%
      setView(lng = -4, lat = 52.54, zoom = 3)
  })


  # Show popup on click
  observeEvent(input$map_click, {
    click <- input$map_click
    text <- paste("Lattitude ", click$lat, "Longtitude ", click$lng)
    proxy <- leafletProxy("map")
    proxy %>%
      clearPopups() %>%
      addPopups(click$lng, click$lat, text)
  })



  # Page 1 view, functions & plots
  trends <- reactive({
    req(input$map_click)
    click <- input$map_click
    woeid <- closestTrendLocations(lat = click$lat, long = click$lng)
    current_trends <- getTrends(as.numeric(woeid[3]))
    current_trends <- as.data.frame(current_trends)
    current_trends$trend_date <- Sys.Date()
    names(current_trends)[1] <- "Trending"
    current_trends
  })

  # Dynamic trends selection & sentiment analysis
  output$trends <- DT::renderDT({
    req(input$map_click)
    as.data.frame(trends())
  })


  output$top <- renderUI({
    datas <- trends()
    selectInput(inputId = "xE", label = "Sentiment & Frequency, N = 300", choices = datas$Trending)
  })


  Trending_top <- reactive({
    req(input$xE)
    x <- searchTwitter(input$xE, n = 300, lang = "en")
    x <- twListToDF(x)
  })


  textClean_top <- reactive({
    x <- Trending_top()
    cleanText(x)
  })


  sentim_top <- reactive({
    x_text <- textClean_top()
    x_text.text.corpus <- Corpus(VectorSource(x_text))
    x_text.text.corpus <- tm_map(x_text.text.corpus, function(x) removeWords(x, stopwords()))
    mysentiment_x <- get_nrc_sentiment((x_text))
  })

  plotData <- reactive({
    req(textClean_top())
    x_text <- textClean_top()
    x_text.text.corpus <- Corpus(VectorSource(x_text))
    x_text.text.corpus <- tm_map(x_text.text.corpus, function(x) removeWords(x, stopwords()))
    dtm <- TermDocumentMatrix(x_text.text.corpus)
    m <- as.matrix(dtm)
    v <- sort(rowSums(m), decreasing = TRUE)
    d <- data.frame(word = names(v), freq = v)
    d
  })

  output$users_top <- renderPlot({
    req (input$xE)
    users <- search_users(input$xE,
      n = 300
    )
    users$location[which(users$location == "")] <- NA

    # print (head(users))
    users %>%
      dplyr::count(location, sort = TRUE) %>%
      dplyr::mutate(location = reorder(location, n)) %>%
      dplyr::top_n(10) %>%
      na.omit() %>%
      ggplot(aes(x = location, y = n)) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Location",
        y = "Count",
        title = "Twitter users - unique locations "
      )
  })#, height = 330, width = 350

  # Word cloud
  output$p <- renderPlot({
    req(trends())
    req(plotData())
    datas <- plotData()
    x <- datas[, 1]
    y <- seq(1, length(x))
    # y <- y^2
    wordcloud(x, sqrt(rev(y)), scale = c(1.2, 0.2), min.freq = 1, colors = brewer.pal(8, "Dark2"), random.order = TRUE, use.r.layout = FALSE, max.words = 200, rot.per = 0.35)
  })#, height = 320, width = 350


  # plotting the sentiments with scores
  output$p1_top <- renderPlot({
    req (input$xE)
    mysentiment_x <- sentim_top()
    Sentimentscores_x <- data.frame(colSums(mysentiment_x[, ]))
    names(Sentimentscores_x) <- "Score"
    Sentimentscores_x <- cbind("sentiment" = rownames(Sentimentscores_x), Sentimentscores_x)
    rownames(Sentimentscores_x) <- NULL
    ggplot(data = Sentimentscores_x, aes(x = sentiment, y = Score)) + geom_bar(aes(fill = sentiment), stat = "identity") +
      theme(legend.position = "none") +
      xlab("Sentiments") + ylab("scores") +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      ggtitle(paste("Sentiments of people behind the tweets on", input$xE, sep = " "))
  })#, height = 330, width = 350



  output$p3_top <- renderPlot({
    req(input$xE)
    d <- plotData()
    rownames(d) <- NULL
    # print (d)
    d <- d[1:10, ]

    ggplot(data = d, aes(x = reorder(word, -freq), freq)) + geom_bar(aes(fill = freq), stat = "identity") +
      theme(legend.position = "none") +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      xlab("Words") + ylab("frequency") + ggtitle(paste("Words frequency of the tweets on", input$xE, sep = " "))
  })#, height = 320, width = 350



  # Page 2 data exploration
  # Separate analysis
  Trending <- eventReactive(input$looktrending, {
    req(input$TweetsN)
    req(input$trending)
    x <- searchTwitter(input$trending, n = input$TweetsN, lang = "en")
    x <- twListToDF(x)
  })


  output$textClean_pairs <- renderPlot({
    x <- Trending_top()
    x$stripped_text <- gsub("http.*", "", x$text)
    x$stripped_text <- gsub("https.*", "", x$stripped_text)
    x_clean <- x %>%
      dplyr::select(stripped_text) %>%
      unnest_tokens(word, stripped_text)

    x_tweets_paired_words <- x %>%
      dplyr::select(stripped_text) %>%
      unnest_tokens(paired_words, stripped_text, token = "ngrams", n = 2)
    #
    x_tweets_paired_words %>%
      dplyr::count(paired_words, sort = TRUE)

    x_tweets_separated_words <- x_tweets_paired_words %>%
      tidyr::separate(paired_words, c("word1", "word2"), sep = " ")
    #
    x_tweets_filtered <- x_tweets_separated_words %>%
      filter(!word1 %in% stop_words$word) %>%
      filter(!word2 %in% stop_words$word)
    #
    # print (x_tweets_filtered)
    x_words_counts <- x_tweets_filtered %>%
      dplyr::count(word1, word2, sort = TRUE)

    #
    # # plot climate change word network
    req(input$NWords)
    x_words_counts %>%
      filter(n >= input$NWords) %>%
      graph_from_data_frame() %>%
      ggraph(layout = "fr") +
      geom_edge_link(aes(edge_alpha = n, edge_width = n)) +
      geom_node_point(color = "darkslategray4", size = 3) +
      geom_node_text(aes(label = name), vjust = 1.8, size = 5) +
      labs(
        title = paste("Word Network: Tweets using the hashtag", input$xE, sep = " "),
        x = "", y = ""
      )
  }, height = 700, width = 900)


  textClean <- reactive({
    x <- Trending()
    cleanText(x)
  })

  sentim <- reactive({
    x_text <- textClean()
    # convert into corpus type
    x_text.text.corpus <- Corpus(VectorSource(x_text))
    # clean up by removing stop words
    x_text.text.corpus <- tm_map(x_text.text.corpus, function(x) removeWords(x, stopwords()))
    # getting emotions using in-built function
    mysentiment_x <- get_nrc_sentiment((x_text))
  })

  output$p1 <- renderPlot({
    req (input$xE)
    mysentiment_x <- sentim()
    Sentimentscores_x <- data.frame(colSums(mysentiment_x[, ]))
    names(Sentimentscores_x) <- "Score"
    Sentimentscores_x <- cbind("sentiment" = rownames(Sentimentscores_x), Sentimentscores_x)
    rownames(Sentimentscores_x) <- NULL
    # plotting the sentiments with scores
    ggplot(data = Sentimentscores_x, aes(x = sentiment, y = Score)) + geom_bar(aes(fill = sentiment), stat = "identity") +
      theme(legend.position = "none") +
      xlab("Sentiments") + ylab("scores") + ggtitle(paste("Sentiments of people behind the tweets on", input$trending, sep = " "))
  }, height = 850, width = 1050)

  output$p2 <- renderPlot({
    req(textClean())
    x_text <- textClean()
    # convert into corpus type
    x_text.text.corpus <- Corpus(VectorSource(x_text))
    # clean up by removing stop words
    x_text.text.corpus <- tm_map(x_text.text.corpus, function(x) removeWords(x, stopwords()))
    dtm <- TermDocumentMatrix(x_text.text.corpus)
    m <- as.matrix(dtm)
    v <- sort(rowSums(m), decreasing = TRUE)
    d <- data.frame(word = names(v), freq = v)
    # dev.cur(width = 1000, height = 1000, unit = "px")
    wordcloud(
      words = d$word, scale = c(4, .5), freq = sqrt(d$freq), min.freq = 1,
      max.words = 200, random.order = TRUE, use.r.layout = FALSE,
      rot.per = 0.35,
      colors = brewer.pal(8, "Dark2")
    )
  }, height = 650, width = 750)

  output$p3 <- renderPlot({
    req(textClean())
    x_text <- textClean()
    # convert into corpus type
    x_text.text.corpus <- Corpus(VectorSource(x_text))
    # clean up by removing stop words
    x_text.text.corpus <- tm_map(x_text.text.corpus, function(x) removeWords(x, stopwords()))
    dtm <- TermDocumentMatrix(x_text.text.corpus)
    m <- as.matrix(dtm)
    v <- sort(rowSums(m), decreasing = TRUE)
    d <- data.frame(word = names(v), freq = v)

    barplot(d[1:30, ]$freq,
      las = 2, names.arg = d[1:30, ]$word,
      col = "lightblue", main = "Most frequent words",
      ylab = "Word frequencies"
    )
  }, height = 750, width = 750)
}

ui <- fluidPage(
  mainPanel(
    "Location",
    div(
      class = "outer",
      tags$head(
        # Include our custom CSS
        includeCSS("styles.css") 
      ),
      leafletOutput("map", height = "100%", width = "100%")
    )
  ),

  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                width = "500", height = "auto",
    uiOutput("top"),
    tabsetPanel(
      tabPanel(
        "Sentiment",
        withSpinner(plotOutput("p1_top")),
        withSpinner(plotOutput("p3_top"))
      ),
      tabPanel(
        "WordCloud",
        withSpinner(plotOutput("users_top")),
        withSpinner(plotOutput("p"))
      )
    )
  )
)

shinyApp(ui, server)
