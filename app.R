library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)

source("R_codes/chart9_scatter.R")
source("R_codes/chart18_bubble.R")

dashboard_data <- dfw_county_adoption %>%
  left_join(
    dfw_ev_stations_counts,
    by = "County"
  ) %>%
  left_join(
    dfw_ev_ports_counts,
    by = "County"
  ) %>%
  left_join(
    dfw_counties_income,
    by = "County"
  )

# Dashboard UI
ui <- fluidPage(
    titlePanel("DFW Electric Vehicle Dashboard"),
    sidebarLayout(
        sidebarPanel(
      selectInput(
        inputId = "county_filter",
        label = "Select Counties:",
        choices = dfw_counties,
        selected = dfw_counties,
        multiple = TRUE
      ),
      sliderInput(
        inputId = "income_filter",
        label = "Median Household Income:",
        min = min(dashboard_data$median_household_income),
        max = max(dashboard_data$median_household_income),
        value = range(dashboard_data$median_household_income),
        step = 1000
      )
    ),
    
    mainPanel(
        tabsetPanel(
        tabPanel(
          "Chart 9",
          plotlyOutput("chart9_output", height = "500px")
        ),
        tabPanel(
          "Chart 18",
          plotlyOutput("chart18_output", height = "500px")
        )
        
        # third chart
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  filtered_data <- reactive({
    req(input$county_filter)
    dashboard_data %>%
      filter(
        County %in% input$county_filter,
        median_household_income >= input$income_filter[1],
        median_household_income <= input$income_filter[2]
      )
  })
  
  # Chart 9
  output$chart9_output <- renderPlotly({
    chart9_filtered <- chart9 %+% filtered_data()
    ggplotly(
      chart9_filtered,
      tooltip = "text"
    )
  })
  
  # Chart 18
  output$chart18_output <- renderPlotly({
    chart18_filtered <- chart18 %+% filtered_data()
    ggplotly(
      chart18_filtered
    )
  })
  
  # Chart X

}

# Running App
shinyApp(
  ui = ui,
  server = server
)