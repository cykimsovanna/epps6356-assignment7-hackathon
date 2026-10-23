source("R_codes/cleaning_data.R")
source("R_codes/theme_settings.R")

chart9_data <- dfw_county_adoption %>%
  left_join(dfw_ev_stations_counts, by = "County") %>%
  left_join(dfw_ev_ports_counts, by = "County")

chart9 <- ggplot(
  data = chart9_data,
  mapping = aes(
    x = charging_ports,
    y = `Adoption Rate`,
    text = paste0(
      County, " County",
      "<br>No. of Charging Ports: ", scales::comma(charging_ports),
      "<br>EV Adoption Rate of ", scales::percent(`Adoption Rate`, accuracy = 0.1)
    )
  )
) +
  geom_point(
    color = ev_colors[["primary"]],
    size = 3
  ) +
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 0.1)
  ) +
  labs(
    title = "EV Adoption Rates vs. EV Charging Availability",
    subtitle = "Across all 16 DFW counties (as of 01/01/2026)",
    x = "Number of Public EV Charging Ports",
    y = "EV Adoption Rate (%)",
    caption = "Sources: DFW Clean Cities EV Registration Report; Alternative Fuels Data Center (AFDC)"
  ) +
  ev_theme()

chart9

# Optional interactive version
chart9_interactive <- plotly::ggplotly(
  chart9,
  tooltip = "text"
)

chart9_interactive