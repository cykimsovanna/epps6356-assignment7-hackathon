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

# ============================================================
# 2. LOAD SHARED DATA AND THEME
# ============================================================

source("R_codes/theme_settings.R")
source("R_codes/cleaning_data.R")

# ============================================================
# 3. PREPARE COUNTY-LEVEL METRICS
# ============================================================

county_metrics <- dfw_county_adoption %>%
  left_join(
    dfw_ev_stations_counts,
    by = "County"
  ) %>%
  left_join(
    dfw_ev_ports_counts,
    by = "County"
  ) %>%
  transmute(
    County,
    ev_registrations = `Electric Vehicles`,
    charging_stations = coalesce(charging_stations, 0L),
    charging_ports = coalesce(charging_ports, 0),
    ev_adoption_rate = `Adoption Rate` * 100
  ) %>%
  arrange(County)

# ============================================================
# 4. RESHAPE DATA
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
# 5. NORMALIZE VALUES TO 0–100
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
# 6. PREPARE CIRCULAR BAR POSITIONS
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
# 7. DEFINE PURPLE COLOR PALETTE
# ============================================================

metric_colors <- c(
  "EV Registrations" = "purple4",
  "Charging Stations" = "darkorchid3",
  "Charging Ports" = "violet",
  "EV Adoption Rate (%)" = "thistle2"
)


# ============================================================
# 8. CALCULATE COUNTY LABEL POSITIONS
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

sector_width <- bars_per_county + gap_size

county_dividers <- data.frame(
  boundary = (seq_along(county_order) - 1) *
    sector_width +
    bars_per_county +
    gap_size / 2 + 0.5
)

# ============================================================
# 9A. CREATE CIRCULAR CHART - RIGHT SIDE
# ============================================================

circular_plot <- ggplot(
  chart_data,
  aes(
    x = bar_id,
    y = bar_height,
    fill = metric
  )
) +
  
  geom_segment(
    data = county_dividers,
    aes(
      x = boundary,
      xend = boundary,
      y = 0,
      yend = 110
    ),
    inherit.aes = FALSE,
    color = "grey92",
    linewidth = 0.3
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
# 9B. CREATE TEXT PANEL - LEFT SIDE
# ============================================================

legend_data <- data.frame(
  metric = factor(
    names(metric_colors),
    levels = names(metric_colors)
  ),
  y = c(0.26, 0.21, 0.16, 0.11)
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
    size = 5.5,
    fontface = "bold",
    family = ev_font,
    color = "grey15",
    lineheight = 1.05
  ) +
  
  # UPDATED DATE AND NORMALIZATION
  annotate(
    "text",
    x = 0.02,
    y = 0.66,
    label = paste(
      "Date: January 1, 2026",
      "Normalized to a 0–100 scale",
      sep = "\n"
    ),
    hjust = 0,
    vjust = 1,
    size = 4.6,
    family = ev_font,
    color = "grey40",
    lineheight = 1.5
  ) +
  
  # MEASUREMENTS HEADING
  annotate(
    "text",
    x = 0.02,
    y = 0.32,
    label = "Metrics",
    hjust = 0,
    vjust = 1,
    size = 4.8,
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
    size = 4.3,
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
# 9C. COMBINE TEXT PANEL AND CIRCULAR CHART
# ============================================================

circular_area_chart <- (
  text_panel + circular_plot
) +
  
  plot_layout(
    widths = c(0.75, 2.25)
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
# 10. DISPLAY CHART
# ============================================================

print(circular_area_chart)


# ============================================================
# 11. SAVE CHART
# ============================================================

dir.create(
  "figures",
  showWarnings = FALSE
)

ggsave(
  filename = "figures/dfw_combined_circular_area.png",
  plot = circular_area_chart,
  width = 11,
  height = 8.5,
  dpi = 300,
  bg = "white"
)


# ============================================================
# 12. EXPORT DATA FOR SHINY
# ============================================================

write.csv(
  chart_data,
  "figures/dfw_combined_circular_area_data.csv",
  row.names = FALSE
)

cat(
  "\nUpdated circular chart saved successfully!\n"
)