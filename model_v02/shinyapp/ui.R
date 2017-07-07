library(shiny)
library(shinydashboard)
library(markdown)

ui <- dashboardPage(
      dashboardHeader(title="Next Word Prediction"),
      dashboardSidebar(
            sidebarMenu(
                  menuItem("Prediction", tabName = "algorithm", icon = icon("sliders")),
                  menuItem("Instruction", tabName = "instruction", icon = icon("info-circle")),
                  menuItem("Algorithm", tabName = "model", icon = icon("info-circle"))
            )
      ),
      dashboardBody(
            tabItems(
                  tabItem(
                        tabName = "algorithm",
                        h2(strong("N-gram Text Predictor")),
                        p("Please allow a momentum to load the app. Type in the indicated box when prompted to."),
                        hr(),
                        fluidRow(
                              column(width = 6,
                                    box(width = 12, height = "300px", status = "primary", 
                                          title = HTML('<span class="fa-stack fa-lg" style="color:#1E77AB">
                                                <i class="fa fa-square fa-stack-2x"></i>
                                                <i class="fa fa-keyboard-o fa-inverse fa-stack-1x"></i>
                                                </span> <span style="font-weight:bold;font-size:24px">
                                                Type in a phrase</span>'),
                                          textInput(inputId="text", label=""),
                                          h2(verbatimTextOutput("prediction"))
                                    ),
                                    box(width = 12, height = "300px", status = "success",
                                        title = HTML('<span class="fa-stack fa-lg" style="color:#2AB27B">
                                                      <i class="fa fa-square fa-stack-2x"></i>
                                                      <i class="fa fa-cogs fa-inverse fa-stack-1x"></i>
                                                      </span> <span style="font-weight:bold;font-size:24px">
                                                      Parameters</span>'),
                                        selectInput("preference",
                                                    "Pick backoff method:",
                                                    c("Naive backoff","Katz backoff"), 
                                                    "Katz backoff"),
                                        br(),
                                        sliderInput("maxResults",
                                                    "Number of predictions to display",
                                                    1, 5, 1)
                                        )
                                    ),
                              column(width = 6, 
                                    box(width=12, height = "620px", status = "warning",
                                          title = HTML('<span class="fa-stack fa-lg" style="color:#FF773D">
                                                      <i class="fa fa-square fa-stack-2x"></i>
                                                      <i class="fa fa-bar-chart fa-inverse fa-stack-1x"></i>
                                                      </span> <span style="font-weight:bold;font-size:24px">
                                                      Probabilities of predicted words</span>'),
                                          plotOutput("pw_plot", height = "500px")
                                    )
                              )
                        )
                  ),
                  tabItem(tabName = "instruction",
                          tabBox( width = 12,
                                 tabPanel(includeMarkdown("Instruction.md"))
                          )
                  ),
                  tabItem(tabName = "model",
                          tabBox( width = 12,
                                 tabPanel(includeMarkdown("Model.md"))
                          )
                  )
            )
      )
)