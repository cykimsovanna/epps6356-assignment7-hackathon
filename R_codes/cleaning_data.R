library(readxl)
library(readr)
library(dplyr)
library(sf)
library(tigris)
library(tidycensus)

# DFW Clean Cities Data
data_ev_registration <- "data/ev_registration_report_20260101.xlsx"
### excel_sheets(data_ev_registration)

## Choosing the 16 DFW Counties
dfw_counties <- c(
  "Collin",
  "Dallas",
  "Denton",
  "Ellis",
  "Erath",
  "Hood",
  "Hunt",
  "Johnson",
  "Kaufman",
  "Navarro",
  "Palo Pinto",
  "Parker",
  "Rockwall",
  "Somervell",
  "Tarrant",
  "Wise"
)

## County-level EV adoption rate
dfw_county_adoption <- read_excel(
  data_ev_registration,
  sheet = "County - Adoption"
) %>%
  filter(County %in% dfw_counties)

## County-level EV registrations by car model
dfw_county_models <- read_excel(
  data_ev_registration,
  sheet = "County"
) %>%
  filter(County %in% dfw_counties)

## Checking Integrity
### nrow(dfw_county_adoption)
### nrow(dfw_county_models)

### dim(dfw_county_adoption)
### dim(dfw_county_models)

### str(dfw_county_adoption)
### colSums(is.na(dfw_county_adoption))

#=======================================================================

# AFDC Data
data_ev_stations <- read_csv(
  "data/electric_fuel_stations_historical_day_20260101.csv",
  col_types = cols(.default = col_character())
  ) # to avoid error and treat all columns as strings

## Locating each station by its county
data_ev_stations <- data_ev_stations %>%
  mutate(
    Latitude = as.numeric(Latitude),
    Longitude = as.numeric(Longitude)
  )

dfw_counties_borders <- tigris::counties(
  state = "TX",
  year = 2025,
  cb = TRUE
) %>%
  filter(NAME %in% dfw_counties) %>%
  st_transform(4326) %>%
  select(County = NAME)

### nrow(dfw_counties_borders)

dfw_ev_stations <- st_as_sf(
  data_ev_stations,
  coords = c("Longitude", "Latitude"),
  crs = 4326,
  remove = FALSE
) %>%
  st_join(
    dfw_counties_borders,
    join = st_within
  ) %>%
  filter(!is.na(County))

### nrow(dfw_ev_stations)
### unique(dfw_ev_stations$County)

## Counting charging stations by county
dfw_ev_stations_counts <- dfw_ev_stations %>%
  st_drop_geometry() %>%
  group_by(County) %>%
  summarise(
    charging_stations = n_distinct(ID),
    .groups = "drop"
  ) %>%
  arrange(desc(charging_stations))

### nrow(dfw_ev_stations)
### sum(dfw_ev_stations_counts$charging_stations)

# Counting charging ports by county
dfw_ev_ports_counts <- dfw_ev_stations %>%
  st_drop_geometry() %>%
  mutate(
    level1_ports = as.numeric(`EV Level1 EVSE Num`),
    level2_ports = as.numeric(`EV Level2 EVSE Num`),
    dc_fast_ports = as.numeric(`EV DC Fast Count`)
  ) %>%
  group_by(County) %>%
  summarise(
    charging_ports = sum(
      level1_ports,
      level2_ports,
      dc_fast_ports,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(desc(charging_ports))

#=======================================================================

# ACS Data
dfw_counties_income <- tidycensus::get_acs(
  geography = "county",
  variables = "B19013_001",
  state = "TX",
  year = 2024,
  survey = "acs5"
  ) %>%
  mutate(
    County = sub(" County, Texas$", "", NAME)
  ) %>%
  filter(
    County %in% dfw_counties
  ) %>%
  transmute(
    County,
    median_household_income = estimate,
    income_moe = moe
  )
