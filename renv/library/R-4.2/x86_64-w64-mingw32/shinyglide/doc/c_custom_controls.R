## ----eval=FALSE---------------------------------------------------------------
#  ui <- fluidPage(
#    titlePanel("Basic shinyglide app"),
#    glide(
#      next_label = paste("Next screen", icon("play", lib = "glyphicon")),
#      previous_label = span(style = "opacity: 0.5;", "Go back"),
#  
#      screen(
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 100)
#      ),
#      screen(
#        p("Here is your plot :"),
#        plotOutput("plot")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$plot <- renderPlot({
#      hist(rnorm(input$n), main = paste("n =", input$n))
#    })
#  }
#  
#  shinyApp(ui, server)

## ----eval=FALSE---------------------------------------------------------------
#  controls <-
#  
#  ui <- fluidPage(
#    titlePanel("Basic shinyglide app"),
#    glide(
#      custom_controls = glideControls(
#        prevButton(class = "btn btn-warning"),
#        tags$button(class = "btn btn-success next-screen")
#      ),
#  
#      screen(
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 100)
#      ),
#      screen(
#        p("Here is your plot :"),
#        plotOutput("plot")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$plot <- renderPlot({
#      hist(rnorm(input$n), main = paste("n =", input$n))
#    })
#  }
#  
#  shinyApp(ui, server)

## ----eval=FALSE---------------------------------------------------------------
#  controls <- fluidRow(
#    div(class="col-xs-6 text-right",
#      prevButton(class = "btn btn-warning")
#    ),
#    div(class="col-xs-6 text-left",
#      nextButton(class = "btn btn-success")
#    )
#  )
#  
#  ui <- fluidPage(
#    titlePanel("Basic shinyglide app"),
#    glide(
#      custom_controls = controls,
#      controls_position = "top",
#      next_label = "Go next",
#      previous_label = "Go back",
#  
#      screen(
#        p("This is a sample custom controls app")
#      ),
#      screen(
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 100)
#      ),
#      screen(
#        p("Here is your plot :"),
#        plotOutput("plot")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$plot <- renderPlot({
#      hist(rnorm(input$n), main = paste("n =", input$n))
#    })
#  }
#  
#  shinyApp(ui, server)

## ----eval = FALSE-------------------------------------------------------------
#  controls <- glideControls(
#    list(
#      prevButton(class = "btn btn-warning"),
#      firstButton(class = "btn btn-danger", "First screen !")
#    ),
#    list(
#      nextButton(),
#      lastButton(
#        class = "btn btn-success",
#        HTML(paste("Last screen...", icon("ok", lib = "glyphicon")))
#      )
#    )
#  )
#  
#  ui <- fluidPage(
#    titlePanel("Basic shinyglide app"),
#    glide(
#      custom_controls = controls,
#  
#      screen(
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 100)
#      ),
#      screen(
#        p("Here is your plot :"),
#        plotOutput("plot")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$plot <- renderPlot({
#      hist(rnorm(input$n), main = paste("n =", input$n))
#    })
#  }
#  
#  shinyApp(ui, server)

## ----eval=FALSE---------------------------------------------------------------
#  modal_controls <- glideControls(
#        list(
#          prevButton(),
#          firstButton(
#            class = "btn btn-danger",
#            `data-dismiss`="modal",
#            "No, thanks !"
#          )
#        ),
#        list(
#          nextButton(),
#          lastButton(
#            class = "btn btn-success",
#            `data-dismiss`="modal",
#            "Done"
#        )
#      )
#  )

