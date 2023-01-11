# KG(a) - Treibhausgas-Fussabdruck Schweiz ----------------------------------------------------
## Indicator:
indicator_id <- "KGa"
indicator_name <- "Treibhausgas-Fussabdruck"
## Variable:
variable <- "Treibhausgasemissionen, die durch die Endnachfrage nach Gütern und Dienstleistungen entstehen"
## Spatial unit:
gebiet <- "Schweiz"
## Temporal unit: starting 2000
## Data sources:
data_source <- "Umweltgesamtrechnung, BFS"

## Computations: (no computation required, values are pre-calculated and available at FSO)
## THG-Fussabdruck: Mio. t CO2-eq
thg_url <- "https://dam-api.bfs.admin.ch/hub/api/dam/assets/23567509/master"

## THG-Fussabdruch pro Einw.: t CO2-eq/Einw.
thg_percapita_url <- "https://dam-api.bfs.admin.ch/hub/api/dam/assets/23567513/master"

# Import data THG-Fussabdruck -------------------------------------------------------------

## File path valid for 2022. We need to check in the next update, if the link is persistent
## Download and clean data (specific to this data file)
kga_thg_data <- rio::import(file = thg_url, which = 1) %>%
  # Set column names
  data.table::setnames(.,1:2,c("Jahr", "Wert")) %>%
  # Remove first 4 rows and last 4 rows
  dplyr::slice(., 5:(nrow(.) - 4)) %>%
  # Setting values for Gebiet and Einheit manually
  dplyr::mutate(Gebiet = gebiet,
                Einheit = "Mio. t CO2-eq")

# Import data THG-Fussabdruck per capita -------------------------------------------------------------

## File path valid for 2022. We need to check in the next update, if the link is persistent


## Download and clean data (specific to this data file)
kga_thg_percapita_data <- rio::import(file = thg_percapita_url, which = 1) %>%
  # Set 4th row as column names
  data.table::setnames(.,1:2,c("Jahr", "Wert")) %>%
  # Remove first 4 rows and last 4 rows
  dplyr::slice(., 5:(nrow(.) - 4)) %>%
  # Setting values for Gebiet and Einheit manually
  dplyr::mutate(Gebiet = gebiet,
                Einheit = "t CO2-eq / Einw.")


# Data structure ----------------------------------------------------------

kga_export_data <- kga_thg_data %>%
  # binding both datasets we importated together
  dplyr::bind_rows(kga_thg_percapita_data) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Variable and Datenquelle
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

utils::write.table(kga_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
