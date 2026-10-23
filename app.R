library(shiny)
library(ggplot2)
library(plotly)
library(readxl)
library(dplyr)
library(scales)

# 1. Load and Clean Data
hpi_raw <- read_excel("HPI3.xlsx")

df_hpi <- hpi_raw %>%
  mutate(
    LifeExpectancy = as.numeric(`Life Expectancy`),
    Wellbeing = as.numeric(`Life satisfaction`),
    Population = as.numeric(`Population`),
    GDPperCapita = as.numeric(`GDP per capita`),
    Region = as.factor(`Continent`)
  ) %>%
  filter(!is.na(LifeExpectancy) & !is.na(GDPperCapita) & !is.na(Population))

# 2. UI Layout
ui <- fluidPage(
  titlePanel("Happy Planet Index Dashboard"),
  sidebarLayout(
    sidebarPanel(
      # Input 1: Filter by Region
      selectInput("region_filter", "Select Region(s):", 
                  choices = unique(df_hpi$Region), 
                  selected = unique(df_hpi$Region), 
                  multiple = TRUE),
      
      # Input 2: Slider for GDP Range
      sliderInput("gdp_slider", "GDP per Capita Range ($):",
                  min = min(df_hpi$GDPperCapita, na.rm = TRUE),
                  max = max(df_hpi$GDPperCapita, na.rm = TRUE),
                  value = c(min(df_hpi$GDPperCapita, na.rm = TRUE), 
                            max(df_hpi$GDPperCapita, na.rm = TRUE)),
                  step = 1000, pre = "$")
    ),
    mainPanel(
      plotlyOutput("bubbleChart18")
    )
  )
)

# 3. Server Logic
server <- function(input, output, session) {
  
  # Shared Reactive Dataset feeding charts
  filtered_data <- reactive({
    df_hpi %>%
      filter(
        Region %in% input$region_filter,
        GDPperCapita >= input$gdp_slider[1],
        GDPperCapita <= input$gdp_slider[2]
      )
  })
  
  # Render Chart 18
  output$bubbleChart18 <- renderPlotly({
    data <- filtered_data()
    
    p <- ggplot(data, aes(
      x = GDPperCapita, y = LifeExpectancy, size = Population, color = Region,
      text = paste0("<b>Country: </b>", Country, "<br><b>GDP: </b>$", scales::comma(GDPperCapita))
    )) +
      geom_point(alpha = 0.7) +
      scale_size_continuous(range = c(2, 14)) +
      scale_x_continuous(labels = scales::dollar_format()) +
      labs(
        title = "Relationship Among GDP, Life Expectancy, and Population",
        x = "GDP per Capita (USD)", y = "Life Expectancy (Years)",
        caption = "Source: Happy Planet Index (HPI3.xlsx)"
      ) +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
}

# 4. Run the App
shinyApp(ui = ui, server = server)
