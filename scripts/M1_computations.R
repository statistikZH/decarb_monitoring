# M1 - Anteil fossilfreie Personenwagen im Fahrzeugbestand ----------------------------------------------------
## Indicator:
indicator_id <- "M1"
indicator_name <- "Fossilfreie Personenwagen im Fahrzeugbestand"
## Variable:
variable <- "Treibstoff"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2005
## Data url: https://www.bfs.admin.ch/asset/de/px-x-1103020100_105
## Data sources:
data_source <- "Strassenfahrzeugbestand MFZ, Bundesamt für Strassen (ASTRA) - IVZ-Fahrzeuge"

## Computations:
## 1. Anzahl: 'Total' - ('Benzin' + 'Diesel')
## 2. Anteil: 1 - ('Benzin' + 'Diesel') / 'Total'

## Cross check of the totals with the FSO: https://www.pxweb.bfs.admin.ch/sq/d37712cd-4d15-4218-a379-2928bbd9a9a7

# Import data -------------------------------------------------------------

## Setting the range of the time series, and continue the range every new year
start_year <- "2005"
end_year <- lubridate::year(Sys.Date()- lubridate::years(1))
year_range <- start_year:end_year

## Path name of the data cube
m1_px_path <- "px-x-1103020100_105"

## Pre-constructed list element containing all query parameters
m1_query_list <- list("Jahr"=c("2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"),
                      "Kanton"=c("0","1"), # Spatial unit: Schweiz and Kanton Zürich
                      "Treibstoff"=c("100","200","300","310","400","410","500","550","600","9900")) # Indicator: Treibstoff. Fetching all types in order to compute a total

## Download data based on query list and convert to data.frame
m1_data <- get_pxdata(m1_px_path, m1_query_list) %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Variable" = Treibstoff, "Wert" = `Bestand der Personenwagen`)


# Computation: Anzahl & Anteil -----------------------------------------------------

m1_computed <- m1_data %>%
  # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel'
  dplyr::mutate(Treibstoff_Typ = dplyr::if_else(Variable %in% c("Benzin", "Diesel"), "fossil", "fossil-free")) %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Jahr, Gebiet, Treibstoff_Typ) %>%
  dplyr::summarise(Anzahl = sum(Wert)) %>%
  dplyr::ungroup() %>%
  # Adding the total number of cars by year and spacial unit and calculate the share by fuel type
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Total = sum(Anzahl),
                Anteil = (Anzahl / Total)) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

m1_export_data <- m1_computed %>%
  dplyr::filter(Einheit != "Total") %>%
  dplyr::rename("Variable" = Treibstoff_Typ) %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Variable = dplyr::if_else(Variable == "fossil", "fossiler Treibstoff", "fossilfreier Treibstoff"),
                Einheit = dplyr::case_when(Einheit == "Anzahl" ~ "Personenwagen [Anz.]",
                                           Einheit == "Anteil" ~ "Personenwagen [%]",
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

utils::write.table(m1_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
