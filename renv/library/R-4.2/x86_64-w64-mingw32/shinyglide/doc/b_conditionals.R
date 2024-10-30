## ----eval = FALSE-------------------------------------------------------------
#  ui <- fluidPage(
#    glide(
#      screen(
#        next_condition = "input.n > 0",
#  
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 0)
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
#      disable_type = "hide",
#  
#      screen(
#        next_condition = "input.n > 0",
#  
#        p("Please choose a value for n :"),
#        numericInput("n", "n :", value = 0)
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
#      disable_type = "hide",
#  
#      screen(
#        p("Do you want to see the next screen ?"),
#        checkboxInput("check", "Yes, of course !", value = FALSE)
#      ),
#      screenOutput("check_screen"),
#      screen(
#        p("And this is the last screen")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$check_screen <- renderUI({
#      if(!input$check) return(NULL)
#      p("Here it is !")
#    })
#    outputOptions(output, "check_screen", suspendWhenHidden = FALSE)
#  }
#  
#  shinyApp(ui, server)

## ----eval=FALSE---------------------------------------------------------------
#  outputOptions(output, "your_screen_id", suspendWhenHidden = FALSE)

## ----eval = FALSE-------------------------------------------------------------
#  ui <- fluidPage(
#    glide(
#      disable_type = "hide",
#  
#      screen(
#        p("Do you want to see the next screen ?"),
#        checkboxInput("check", "Yes, of course !", value = FALSE)
#      ),
#      screenOutput("check_screen"),
#      screen(
#        p("And this is the last screen")
#      )
#    )
#  )
#  
#  server <- function(input, output, session) {
#    output$check_screen <- renderUI({
#      Sys.sleep(2)
#      if(!input$check) return(NULL)
#      p("Here it is !")
#    })
#    outputOptions(output, "check_screen", suspendWhenHidden = FALSE)
#  }
#  
#  shinyApp(ui, server)

