source("R_codes/cleaning_data.R")
source("R_codes/theme_settings.R")

chart18_data <- dfw_county_adoption %>%
  left_join(
    dfw_counties_income,
    by = "County"
  ) %>%
  left_join(
    dfw_ev_stations_counts,
    by = "County"
  )

chart18 <- ggplot(
  data = chart18_data,
  mapping = aes(
    x = median_household_income,
    y = `Adoption Rate`,
    size = charging_stations,
    text = paste0(
      "<b>", County, " County</b>",
      "<br>Median Household Income of <b>",
      scales::dollar(median_household_income), "</b>",
      "<br>EV Adoption Rate of <b>",
      scales::percent(`Adoption Rate`, accuracy = 0.1), "</b>",
      "<br>No. of Charging Stations: <b>",
      scales::comma(charging_stations), "</b>"
    )
  )
) + 
  geom_point(
    color = ev_colors[["primary"]],
    alpha = 0.7
  ) +
    scale_size_area(
    max_size = 18
  ) +
    scale_x_continuous(
    labels = scales::label_comma()
  ) +
    scale_y_continuous(
    labels = scales::label_percent(accuracy = 0.1)
  ) +
    labs(
    title = "EV Adoption Rates vs. Median Household Income",
    subtitle = "Bubble size shows the number of public charging stations in each DFW county",
    x = "Median Household Income (in USD)",
    y = "EV Adoption Rate (%)",
    size = "Charging Stations",
    caption = paste0(
      "Sources: U.S. Census Bureau (2020–2024 ACS); ",
      "DFW Clean Cities and AFDC (January 1, 2026)"
    )
  ) +
  ev_theme()

## chart18