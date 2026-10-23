library(shiny)
library(ggplot2)
library(plotly)
library(readxl)
library(dplyr)
library(scales)

# 1. Load Data
df_ev_adoption <- read_excel("data/ev_registration_report_20260101.xlsx", sheet = "County - Adoption") %>%
  filter(!is.na(County))

# Define the 16 DFW Counties for default pre-selection
dfw_counties <- c(
  "Collin", "Dallas", "Denton", "Ellis", "Erath", "Hood", "Hunt", "Johnson",
  "Kaufman", "Navarro", "Palo Pinto", "Parker", "Rockwall", "Somervell", "Tarrant", "Wise"
)

# 2. UI Layout
ui <- fluidPage(
  titlePanel("Texas EV Infrastructure & Adoption Dashboard"),
  sidebarLayout(
    sidebarPanel(
      # Dropdown with the 16 DFW counties pre-selected by default
      selectInput("county_filter", "Select County/Counties to Display:", 
                  choices = unique(df_ev_adoption$County), 
                  selected = dfw_counties, 
                  multiple = TRUE),
      
      # Slider for total vehicles range
      sliderInput("vehicle_slider", "Total Vehicles Range:",
                  min = min(df_ev_adoption$`All Vehicles`, na.rm = TRUE),
                  max = max(df_ev_adoption$`All Vehicles`, na.rm = TRUE),
                  value = c(min(df_ev_adoption$`All Vehicles`, na.rm = TRUE), 
                            max(df_ev_adoption$`All Vehicles`, na.rm = TRUE)),
                  step = 10000)
    ),
    mainPanel(
      plotlyOutput("bubbleChart18_EV", height = "550px")
    )
  )
)

# 3. Server Logic
server <- function(input, output, session) {
  
  # Reactive dataset: filters strictly by selected county/counties
  filtered_ev_data <- reactive({
    req(input$county_filter) # Ensure at least one county is selected
    
    df_ev_adoption %>%
      filter(
        County %in% input$county_filter,
        `All Vehicles` >= input$vehicle_slider[1],
        `All Vehicles` <= input$vehicle_slider[2]
      )
  })
  
  # Render Bubble Chart
  output$bubbleChart18_EV <- renderPlotly({
    data <- filtered_ev_data()
    
    p <- ggplot(data, aes(
      x = `Electric Vehicles`, 
      y = `Adoption Rate`, 
      size = `All Vehicles`, 
      color = County,
      text = paste0(
        "<b>County: </b>", County, 
        "<br><b>Electric Vehicles: </b>", scales::comma(`Electric Vehicles`),
        "<br><b>Adoption Rate: </b>", scales::percent(`Adoption Rate`, accuracy = 0.01),
        "<br><b>Total Vehicles: </b>", scales::comma(`All Vehicles`)
      )
    )) +
      geom_point(alpha = 0.85) +
      scale_size_continuous(range = c(6, 20), labels = scales::comma) +
      scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
      scale_x_continuous(labels = scales::comma) +
      labs(
        title = "EV Adoption Rate vs. Total Electric Vehicles",
        x = "Total Electric Vehicles Registered", 
        y = "EV Adoption Rate",
        size = "Total Fleet Size"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold", size = 14, color = "#2c3e50")
      )
    
    ggplotly(p, tooltip = "text")
  })
}

# 4. Run App
shinyApp(ui = ui, server = server)