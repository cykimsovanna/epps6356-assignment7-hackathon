# ============================================================
# EPPS 6356 - HACKATHON 2.0
# EV Adoption and Charging Infrastructure Across 16 DFW Counties
# Circular Bar Chart - Final Layout
# ============================================================


# ============================================================
# 1. LOAD LIBRARIES
# ============================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readxl)
library(readr)
library(sf)
library(tigris)
library(scales)
library(patchwork)

# Load the team's existing theme
source("R_codes/theme_settings.R")


# ============================================================
# 2. DEFINE DFW COUNTIES
# ============================================================

dfw_counties <- c(
  "Collin", "Dallas", "Denton", "Ellis",
  "Erath", "Hood", "Hunt", "Johnson",
  "Kaufman", "Navarro", "Palo Pinto", "Parker",
  "Rockwall", "Somervell", "Tarrant", "Wise"
)


# ============================================================
# 3. LOAD EV REGISTRATION DATA
# ============================================================

ev_raw <- read_excel(
  "data/ev_registration_report_20260101.xlsx",
  sheet = "County - Adoption"
)

print(names(ev_raw))

dfw_county_adoption <- ev_raw %>%
  filter(County %in% dfw_counties) %>%
  transmute(
    County,
    ev_registrations = as.numeric(`Electric Vehicles`),
    ev_adoption_rate = as.numeric(`Adoption Rate`) * 100
  )


# ============================================================
# 4. LOAD CHARGING STATION DATA
# ============================================================

stations_raw <- read_csv(
  "data/electric_fuel_stations_historical_day_20260101.csv",
  col_types = cols(.default = col_character())
)

stations_clean <- stations_raw %>%
  filter(`Fuel Type Code` == "ELEC") %>%
  mutate(
    Latitude = as.numeric(Latitude),
    Longitude = as.numeric(Longitude)
  ) %>%
  filter(
    !is.na(Latitude),
    !is.na(Longitude)
  )


# ============================================================
# 5. GET COUNTY BOUNDARIES
# ============================================================

dfw_counties_borders <- tigris::counties(
  state = "TX",
  year = 2025,
  cb = TRUE
) %>%
  filter(NAME %in% dfw_counties) %>%
  st_transform(4326) %>%
  select(County = NAME)


# ============================================================
# 6. ASSIGN STATIONS TO COUNTIES
# ============================================================

dfw_ev_stations <- st_as_sf(
  stations_clean,
  coords = c("Longitude", "Latitude"),
  crs = 4326,
  remove = FALSE
) %>%
  st_join(
    dfw_counties_borders,
    join = st_within
  ) %>%
  filter(!is.na(County))


# ============================================================
# 7. COUNT CHARGING STATIONS AND PORTS
# ============================================================

dfw_charging_counts <- dfw_ev_stations %>%
  st_drop_geometry() %>%
  mutate(
    level1_ports = as.numeric(`EV Level1 EVSE Num`),
    level2_ports = as.numeric(`EV Level2 EVSE Num`),
    dc_fast_ports = as.numeric(`EV DC Fast Count`)
  ) %>%
  group_by(County) %>%
  summarise(
    charging_stations = n_distinct(ID),
    
    charging_ports = sum(
      coalesce(level1_ports, 0) +
        coalesce(level2_ports, 0) +
        coalesce(dc_fast_ports, 0)
    ),
    
    .groups = "drop"
  )


# ============================================================
# 8. COMBINE ALL FOUR MEASUREMENTS
# ============================================================

county_metrics <- dfw_county_adoption %>%
  left_join(
    dfw_charging_counts,
    by = "County"
  ) %>%
  mutate(
    charging_stations = coalesce(charging_stations, 0L),
    charging_ports = coalesce(charging_ports, 0)
  ) %>%
  arrange(County)

print(county_metrics)


# ============================================================
# 9. RESHAPE DATA
# ============================================================

chart_actual <- county_metrics %>%
  pivot_longer(
    cols = c(
      ev_registrations,
      charging_stations,
      charging_ports,
      ev_adoption_rate
    ),
    names_to = "metric",
    values_to = "actual_value"
  ) %>%
  mutate(
    metric = recode(
      metric,
      ev_registrations = "EV Registrations",
      charging_stations = "Charging Stations",
      charging_ports = "Charging Ports",
      ev_adoption_rate = "EV Adoption Rate (%)"
    )
  )


# ============================================================
# 10. NORMALIZE VALUES TO 0-100
# ============================================================

chart_data <- chart_actual %>%
  group_by(metric) %>%
  mutate(
    normalized_value = if (
      any(is.finite(actual_value)) &&
      max(actual_value, na.rm = TRUE) > 0
    ) {
      actual_value /
        max(actual_value, na.rm = TRUE) * 100
    } else {
      0
    }
  ) %>%
  ungroup()


# ============================================================
# 11. PREPARE CIRCULAR BAR POSITIONS
# ============================================================

county_order <- dfw_counties

metric_order <- c(
  "EV Registrations",
  "Charging Stations",
  "Charging Ports",
  "EV Adoption Rate (%)"
)

bars_per_county <- length(metric_order)
gap_size <- 2

chart_data <- chart_data %>%
  mutate(
    County = factor(County, levels = county_order),
    metric = factor(metric, levels = metric_order)
  ) %>%
  arrange(County, metric) %>%
  group_by(County) %>%
  mutate(
    metric_id = row_number()
  ) %>%
  ungroup() %>%
  mutate(
    county_id = as.integer(County),
    
    bar_id = (county_id - 1) *
      (bars_per_county + gap_size) + metric_id,
    
    bar_height = normalized_value
  )

total_positions <- length(county_order) *
  (bars_per_county + gap_size)

inner_radius <- 30


# ============================================================
# 12. DEFINE PURPLE COLOR PALETTE
# ============================================================

metric_colors <- c(
  "EV Registrations" = "purple4",
  "Charging Stations" = "darkorchid3",
  "Charging Ports" = "violet",
  "EV Adoption Rate (%)" = "#B57EDC"
)


# ============================================================
# 13. COUNTY LABEL POSITIONS
# ============================================================

county_labels <- chart_data %>%
  group_by(County) %>%
  summarise(
    label_position = mean(bar_id),
    .groups = "drop"
  ) %>%
  mutate(
    angle = 90 -
      360 * (label_position - 0.5) / total_positions,
    
    hjust = ifelse(angle < -90, 1, 0),
    
    angle = ifelse(
      angle < -90,
      angle + 180,
      angle
    )
  )


# ============================================================
# 14A. CREATE CIRCULAR CHART - RIGHT SIDE
# ============================================================

circular_plot <- ggplot(
  chart_data,
  aes(
    x = bar_id,
    y = bar_height,
    fill = metric
  )
) +
  
  geom_col(
    width = 0.92,
    color = "white",
    linewidth = 0.2
  ) +
  
  geom_text(
    data = county_labels,
    aes(
      x = label_position,
      y = 116,
      label = County,
      angle = angle,
      hjust = hjust
    ),
    inherit.aes = FALSE,
    size = 4,
    family = ev_font,
    color = "grey15",
    fontface = "bold"
  ) +
  
  coord_polar(
    theta = "x",
    start = 0,
    clip = "off"
  ) +
  
  scale_y_continuous(
    limits = c(-inner_radius, 130),
    breaks = c(0, 25, 50, 75, 100),
    expand = c(0, 0)
  ) +
  
  scale_x_continuous(
    limits = c(0.5, total_positions + 0.5),
    breaks = NULL,
    expand = c(0, 0)
  ) +
  
  scale_fill_manual(
    values = metric_colors,
    name = NULL
  ) +
  
  ev_theme() +
  
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    
    panel.grid.major.y = element_line(
      color = "grey90",
      linewidth = 0.35
    ),
    
    plot.title = element_blank(),
    plot.subtitle = element_blank(),
    plot.caption = element_blank(),
    
    legend.position = "none",
    
    panel.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    plot.margin = margin(
      t = 15,
      r = 15,
      b = 15,
      l = 15
    )
  )


# ============================================================
# 14B. CREATE TEXT PANEL - LEFT SIDE
# ============================================================

legend_data <- data.frame(
  metric = factor(
    names(metric_colors),
    levels = names(metric_colors)
  ),
  y = c(0.22, 0.17, 0.12, 0.07)
)

text_panel <- ggplot() +
  
  # UPDATED TITLE
  annotate(
    "text",
    x = 0.02,
    y = 0.94,
    label = paste(
      "EV Adoption and",
      "Charging Infrastructure",
      "Across 16 DFW Counties",
      sep = "\n"
    ),
    hjust = 0,
    vjust = 1,
    size = 3.7,
    fontface = "bold",
    family = ev_font,
    color = "grey15",
    lineheight = 1.15
  ) +
  
  # UPDATED DATE AND NORMALIZATION
  annotate(
    "text",
    x = 0.02,
    y = 0.66,
    label = paste(
      "Data Year: January 1, 2026",
      "Normalized to a 0–100 scale",
      sep = "\n"
    ),
    hjust = 0,
    vjust = 1,
    size = 3.1,
    family = ev_font,
    color = "grey40",
    lineheight = 1.5
  ) +
  
  # MEASUREMENTS HEADING
  annotate(
    "text",
    x = 0.02,
    y = 0.32,
    label = "MEASUREMENTS",
    hjust = 0,
    vjust = 1,
    size = 3.4,
    fontface = "bold",
    family = ev_font,
    color = "grey15"
  ) +
  
  # LEGEND COLOR SQUARES
  geom_tile(
    data = legend_data,
    aes(
      x = 0.05,
      y = y,
      fill = metric
    ),
    width = 0.035,
    height = 0.025
  ) +
  
  # LEGEND LABELS
  geom_text(
    data = legend_data,
    aes(
      x = 0.10,
      y = y,
      label = metric
    ),
    hjust = 0,
    size = 3.0,
    family = ev_font,
    color = "grey25"
  ) +
  
  scale_fill_manual(
    values = metric_colors
  ) +
  
  coord_cartesian(
    xlim = c(0, 1),
    ylim = c(0, 1),
    clip = "on",
    expand = FALSE
  ) +
  
  theme_void() +
  
  theme(
    legend.position = "none",
    
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    plot.margin = margin(
      t = 20,
      r = 15,
      b = 20,
      l = 30
    )
  )


# ============================================================
# 14C. COMBINE LEFT PANEL + RIGHT CIRCULAR CHART
# ============================================================

circular_area_chart <- (
  text_panel + circular_plot
) +
  
  plot_layout(
    widths = c(1.05, 1.95)
  ) +
  
  plot_annotation(
    caption = paste0(
      "Sources: DFW Clean Cities EV Registration Report ",
      "and Alternative Fuels Data Center (AFDC)"
    ),
    
    theme = theme(
      plot.background = element_rect(
        fill = "white",
        color = NA
      ),
      
      # ONE-LINE CENTERED SOURCE
      plot.caption = element_text(
        size = 9,
        hjust = 0.5,
        color = "grey40",
        family = ev_font,
        margin = margin(t = 20)
      ),
      
      plot.margin = margin(
        t = 20,
        r = 20,
        b = 20,
        l = 20
      )
    )
  )


# ============================================================
# 15. DISPLAY CHART
# ============================================================

print(circular_area_chart)


# ============================================================
# 16. SAVE CHART
# ============================================================

dir.create(
  "figures",
  showWarnings = FALSE
)

ggsave(
  filename = "figures/dfw_combined_circular_area.png",
  plot = circular_area_chart,
  width = 18,
  height = 11,
  dpi = 300,
  bg = "white"
)


# ============================================================
# 17. EXPORT DATA FOR SHINY
# ============================================================

write.csv(
  chart_data,
  "figures/dfw_combined_circular_area_data.csv",
  row.names = FALSE
)

cat(
  "\nUpdated circular chart saved successfully!\n"
)