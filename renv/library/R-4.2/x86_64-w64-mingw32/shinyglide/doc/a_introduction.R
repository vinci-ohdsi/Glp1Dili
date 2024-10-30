## ----eval = FALSE-------------------------------------------------------------
#  ui <- fluidPage(
#    titlePanel("App title"),
#    glide(
#      ...
#    )
#  )

## ----eval = FALSE-------------------------------------------------------------
#  ui <- fluidPage(
#    titlePanel("App title"),
#    glide(
#      screen(
#        p("This is the first screen of this glide.")
#      ),
#      screen(
#        p("This is the second and final screen.")
#      )
#    )
#  )

## ----eval = FALSE-------------------------------------------------------------
#  ui <- fluidPage(
#    titlePanel("Basic shinyglide app"),
#    glide(
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
#  ui <- fluidPage(
#    glide(
#      id = "plot-glide",
#      height = "450px",
#      controls_position = "top",
#      next_label = "Go to next screen",
#      previous_label = "Go back",
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
#  div(`data-glide-el`="controls",
#    a(`data-glide-dir`="<", href="#", "Go back")
#  )

## ----eval=FALSE---------------------------------------------------------------
#  div(`data-glide-el`="controls",
#    tags$button(`data-glide-dir`="<<", href="#", "Back to start")
#  )

## ----eval=FALSE---------------------------------------------------------------
#  ui <- fluidPage(
#    glide(
#      id = "myglide",
#      screen(h1("First screen")),
#      screen(h1("Second screen")),
#      screen(h1("Third screen"))
#    ),
#    textOutput("index")
#  )
#  
#  server <- function(input, output, session){
#    output$index <- renderText(
#      input$shinyglide_index_myglide
#    )
#  }

