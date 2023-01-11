# G1 - Anteil fossilfreier Wärmeerzeuger in Wohn- und Nichtwohngebäuden ----------------------------------------------------
## Indicator:
indicator_id <- "G1"
indicator_name <- "Fossilfreie Wärmeerzeuger in Gebäuden"
## Variable:
variable <- "Hauptquelle der Heizung"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2021
## Data url: https://www.bfs.admin.ch/asset/de/px-x-0902010000_102
## Data sources:
data_source <- "Gebäude- und Wohnungsstatistik GWS, BFS"

## Computations:
## 1. Anzahl: 'Total' - ('Heizöl' + 'Gas'+ (0.1 * 'Fernwärme'))
## 2. Anteil: 1 - ('Heizöl' + 'Gas'+ (0.1 * 'Fernwärme')) / 'Total'

## Additional remarks:
## Annahme: 10% der Fernwärme mittels fossilem Energieträger für QS mit den kantonalen Daten vergleichen, die beim Stat. Amt vorliegen.
## Für Differenzierung auch Parameter 'Gebäudekategorie' mitberücksichtigen.

## Cross check of the totals with the FSO: https://www.pxweb.bfs.admin.ch/sq/b740e708-f521-4cd5-8eb0-661e1685e6de

# Import data -------------------------------------------------------------

## Set the range of the time series and continue for each additional year
start_year <- "2021"
end_year <- lubridate::year(Sys.Date()- lubridate::years(1))
year_range <- start_year:end_year

## Path name of the data cube
g1_px_path <- "px-x-0902010000_102"

## Pre-constructed list element containing all query parameters
g1_query_list <- list("Jahr"= c("0"), # All available years
                      "Kanton"=c("8100","01"), # Spatial unit: Schweiz and Kanton Zürich
                      "Hauptenergiequelle der Heizung"=c("0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23") # Indicator: Hauptenergiequelle der Heizung. Fetching all types in order to compute a total
                      )


## Download data based on query list and convert to data.frame
g1_data <- decarbmonitoring::get_pxdata(g1_px_path, g1_query_list) %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Variable" = `Hauptenergiequelle der Heizung`, "Wert" = Gebäude)


# Computation: Anzahl & Anteil -----------------------------------------------------

## Splitting Fernwärme into fossil and fossil-free
## Assigning 10% of heating to means of fossil fuel
g1_fernwaerme_fossil <- g1_data %>%
  dplyr::filter(startsWith( Variable, "Fernwärme")) %>%
  dplyr::mutate(Variable = "Fernwärme fossil") %>%
  dplyr::group_by(Jahr, Gebiet, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Wert = Wert * 0.1)

# ...and 90% of heating to means of fossil-free fuel
g1_fernwaerme_fossilfree <- g1_data %>%
  dplyr::filter(startsWith( Variable, "Fernwärme")) %>%
  dplyr::mutate(Variable = "Fernwärme fossil-free") %>%
  dplyr::group_by(Jahr, Gebiet, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Wert = Wert * 0.9)

g1_computed <- g1_data %>%
  # Fernwärme has been calculated separately, so remove it from the data
  dplyr::filter(!startsWith(Variable, "Fernwärme")) %>%
  # Add Fernwärme splits (fossil vs. fossil-free) to the data.frame
  dplyr::bind_rows(g1_fernwaerme_fossil) %>%
  dplyr::bind_rows(g1_fernwaerme_fossilfree) %>%
  # Auxiliary variable for calculating the number of buildings with fossil vs. fossil-free sources of heating. Fossil being 'Heizöl'+'Gas'+ (0.1 * 'Fernwärme')
  dplyr::mutate(Heizquelle = dplyr::if_else(Variable %in% c("Heizöl", "Gas", "Fernwärme fossil"), "fossil", "fossil-free")) %>%
  # Calculating number of buildings by year, spacial unit, and source of heating
  dplyr::group_by(Jahr, Gebiet, Heizquelle) %>%
  dplyr::summarise(Anzahl = sum(Wert)) %>%
  dplyr::ungroup() %>%
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Total = sum(Anzahl),
                Anteil = (Anzahl / Total)) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

g1_export_data <- g1_computed %>%
  dplyr::filter(Einheit != "Total") %>%
  dplyr::rename("Variable" = Heizquelle) %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Variable = dplyr::if_else(Variable == "fossil", "Hauptquelle der Heizung, fossil", "Hauptquelle der Heizung, fossilfrei"),
                Einheit = dplyr::case_when(Einheit == "Anzahl" ~ "Gebäude [Anz.]",
                                           Einheit == "Anteil" ~ "Gebäude [%]",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = indicator_id,
                Indikator_Name = indicator_name,
                Datenquelle = data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
dir.create("output", showWarnings = FALSE)

output_file <- paste0(indicator_id, "_data.csv")

utils::write.table(g1_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
