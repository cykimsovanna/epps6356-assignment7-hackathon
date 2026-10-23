source("R_codes/cleaning_data.R")
source("R_codes/theme_settings.R")

chart9_data <- dfw_county_adoption %>%
  left_join(dfw_ev_stations_counts, by = "County") %>%
  left_join(dfw_ev_ports_counts, by = "County")
