dashboardPage(
  skin = "blue",
  dashboardHeader(title = "ShinyTwit"),
  ## Sidebar content
  dashboardSidebar(
    sidebarMenu(
      menuItem("Trending", tabName = "dataInput", icon = icon("upload")),
      menuItem("Search", tabName = "regressions", icon = icon("random")),
      menuItem("Analytics", tabName = "mixmod", icon = icon("cubes"))
    )
  ),
  dashboardBody( # Body content
    tabItems(
      tabItem( # First tab content
        tabName = "dataInput",
        fluidRow(
          column(
            width = 9,
            box(
              title = "Twitter Review: ", status = "success", height =
                "900", width = "12", solidHeader = T,
              tabsetPanel(
                tabPanel(
                  "Location",
                  box(
                    width = 12,
                    leafletOutput("map", height = 750)
                  )
                ),
                tabPanel(
                  "Table",
                  box(
                    width = 12,
                    DT::dataTableOutput("trends"), style = "height:700px; overflow-y: scroll;overflow-x: scroll;"
                  )
                ),
                tabPanel(
                  'Word Map',
                  column(
                    width = 12, align = "center",
                    numericInput('NWords', 'Number of words', 10, 50), 
                    box(
                      width = 12,
                      withSpinner(plotOutput("textClean_pairs")),style = "height:700px;width:600;"#overflow-y: scroll;overflow-x: scroll;"
                    )
                  )
                )
              )
            )
          ),
          column(
            width = 3, align = "center",
            # box(
            #   title = "Current Trends: ", status = "warning", height =
            #     "400", width = "400", solidHeader = T,
            #   plotOutput("p"), style = "height:350px;width:400;"#overflow-y: scroll;overflow-x: scroll;"
            # ),
            box(
              title = "Top in Trends: ", status = "success", height =
                "900", width = "400", solidHeader = T,
              uiOutput("top"),
              tabsetPanel(
                tabPanel(
                  "Sentiment",
                  column(12,
                         align = "center",
                         withSpinner(plotOutput("p1_top")),
                         withSpinner(plotOutput("p3_top"))
                  )
                ),
                tabPanel(
                  "Users & Words",
                  column(12,
                         align = "center",
                         withSpinner(plotOutput("users_top")),
                         withSpinner(plotOutput("p"))
                  )
                )
              )
            )
          )
        )
      ),
      tabItem( # First tab content
        tabName = "regressions",
        fluidRow(
          column(
            width = 3,
            box(
              title = "Twitter Input: ", status = "success", height =
                "1595", width = "12", solidHeader = T,
              textInput("trending", "Hashtag", "#Champion", width = 200),
              numericInput("TweetsN", "Number of tweets", 5, min = 1, max = 10001, width = 200),
              actionButton("looktrending", "Lookup") # updated from July 28
            )
          ),
          column(
            width = 9,
            box(
              title = "Twitter Input: ", status = "success", height =
                "1595", width = "12", solidHeader = T,
              tabsetPanel(
                tabPanel(
                  "Sentiment Plot",
                  box(
                    width = 12,
                    column(12,
                           align = "center",
                           withSpinner(plotOutput("p1")), style = "height:800px;width:600;overflow-y: scroll;overflow-x: scroll;"
                    )
                  )
                ),
                tabPanel(
                  "WordCloud",
                  box(
                    width = 12,
                    column(12,
                           align = "center",
                           withSpinner(plotOutput("p2")), style = "height:800px;width:600;overflow-y: scroll;overflow-x: scroll;"
                    )
                  )
                ),
                tabPanel(
                  "Word Frequency",
                  box(
                    width = 12,
                    column(12,
                           align = "center",
                           withSpinner(plotOutput("p3")), style = "height:800px;width:600;overflow-y: scroll;overflow-x: scroll;"
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)
