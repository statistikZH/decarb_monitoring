# M8 - Endenergieverbrauch fossiler Treibstoffe ----------------------------------------------------
## Indicator:
indicator_id <- "M8"
indicator_name <- "Endenergieverbrauch fossiler Treibstoffe"
## Variable:
variable <- "Treibstoff"
## Spatial unit:
gebiet <- "Kanton Zürich"
## Temporal unit: starting 2010
## Data url: https://www.web.statistik.zh.ch/ogd/datenkatalog/app/#/datasets/1661@awel-kanton-zuerich
## Data sources:
data_source <- "Amt für Abfall, Wasser, Energie und Luft des Kantons Zürich"

## Computations:
## 1. Verbrauch: Gigawattstunden (GWh)
## 2. Verbrauch pro Einwohner: GWh/Einwohner

# Import data -------------------------------------------------------------

## Set the range of the time series and continue for each additional year
start_year <- "2010"
end_year <- lubridate::year(Sys.Date()- lubridate::years(1))
year_range <- start_year:end_year

openzh_filename <- "KTZH_00001661_00003118.csv"

## Download data based on query list and convert to data.frame
m8_data <- get_openzh_data(openzh_filename) %>%
  dplyr::filter(Energiesektor == "Treibstoff") %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Variable" = Energiesektor)


# Computation: Anzahl & Anzahl pro Einwohner -----------------------------------------------------

## Getting population data for Kanton Zürich from indicator Q1
m8_population <- data.table::fread("output/q1_data.csv") %>%
  dplyr::filter(Gebiet == gebiet) %>%
  dplyr::select(Jahr, Gebiet, "Einwohner" = Wert)

m8_computed <- m8_data %>%
  # Joining population data
  dplyr::left_join(m8_population, by = "Jahr") %>%
  # Compute per capita
  dplyr::mutate(`GWh pro Einwohner` = Wert / Einwohner) %>%
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `GWh pro Einwohner`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

m8_export_data <- m8_computed %>%
  # Renaming values
  dplyr::mutate(Gebiet = gebiet,
                Einheit = dplyr::if_else(Einheit == "Value", "Gigawattstunden (GWh)", "Gigawattstunden pro Einwohner (GWh pro Einw.)")) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = indicator_id,
                Indikator_Name = indicator_name,
                Variable = variable,
                Datenquelle = data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
dir.create("output", showWarnings = FALSE)

output_file <- paste0(indicator_id, "_data.csv")

utils::write.table(m8_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
