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
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Quattrocento:wght@400;700&display=swap"
    ),
    tags$style(HTML("
      body, h1, h2, h3, h4, h5, h6,
      label, input, button, select,
      .nav-tabs, .selectize-input, .selectize-dropdown {
        font-family: 'Quattrocento', serif !important;
      }  
      .chart-title {
        text-align: center;
        font-size: 28px;
        font-weight: bold;
        margin-top: 15px;
      }
      .chart-subtitle {
        text-align: center;
        font-size: 15px;
        color: dimgray;
        margin-bottom: 10px;
      }
      .chart-caption {
        text-align: left;
        font-size: 13px;
        color: dimgray;
        margin-top: 8px;
      }
    "))
  ),

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
          h3(
            "EV Adoption Rates vs. EV Charging Availability",
            class = "chart-title"
            ),
          p(
            "Across the selected DFW counties, as of January 1, 2026",
            class = "chart-subtitle"
            ),
          plotlyOutput(
            "chart9_output", 
            height = "500px"
            ),
          p(
            "Sources: DFW Clean Cities EV Registration Report; Alternative Fuels Data Center (AFDC), January 1, 2026.",
            class = "chart-caption"
            )
        ),
        tabPanel(
          "Chart 18",
          h3(
            "EV Adoption Rates vs. Median Household Income",
            class = "chart-title"
          ),
          p(
            "Bubble size represents the number of public EV charging stations across the 16 DFW counties.",
            class = "chart-subtitle"
          ),
          plotlyOutput("chart18_output", height = "500px"
          ),
          p(
            "Sources: U.S. Census Bureau (2020–2024 ACS); DFW Clean Cities EV Registration Report and AFDC (January 1, 2026).",
            class = "chart-caption"
          )
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
    chart9_filtered <- chart9 %+% filtered_data() +
      labs(
        title = NULL,
        subtitle = NULL,
        caption = NULL
      )
    ggplotly(
      chart9_filtered,
      tooltip = "text"
    ) %>%
      plotly::layout(
        font = list(
          family = "Quattrocento",
          size = 13
        ),
        xaxis = list(
          title = list(font = list(size = 15)),
          tickfont = list(size = 12)
        ),
        yaxis = list(
          title = list(font = list(size = 15)),
          tickfont = list(size = 12)
      )
    )
  })
  
  # Chart 18
  output$chart18_output <- renderPlotly({
    chart18_filtered <- chart18 %+% filtered_data() +
      labs(
        title = NULL,
        subtitle = NULL,
        caption = NULL
      )
    ggplotly(
      chart18_filtered,
      tooltip = "text"
    ) %>%
      plotly::layout(
        font = list(
          family = "Quattrocento",
          size = 13
        ),
        xaxis = list(
          title = list(font = list(size = 15)),
          tickfont = list(size = 12)
        ),
        yaxis = list(
          title = list(font = list(size = 15)),
          tickfont = list(size = 12)
        )
      )
  })
  
  # Chart X

}

# Running App
shinyApp(
  ui = ui,
  server = server
)
