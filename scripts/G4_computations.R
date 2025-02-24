# G4 - Heizgradtage

# Ab Ende 2024 stehen die Daten nicht mehr über das UGZ Stadt Zürich zur Verfügung
# gma 2025-02-19: Verwendung Datensatz MeteoSchweiz. Berechnung HGT erfolgt neu innerhalb Skript
# Datensatz liegt bis auf Stufe Tag ab 1864-01-01 vor...

# Import data -------------------------------------------------------------

ds <- create_dataset("G4")
ds <- download_data(ds)

g4_data <- ds$data

# Computation:  -----------------------------------------------------

# None

# Data structure ----------------------------------------------------------

g4_export_data <- g4_data |>
  dplyr::select(date,tre200d0) |>
  dplyr::mutate(date = as.POSIXct(as.character(date), format = "%Y%m%d", tz = "UTC")) |>
  dplyr::mutate(hgt = dplyr::if_else(tre200d0 > 12, 0, 20 - tre200d0)) |>
  dplyr::group_by(Jahr = lubridate::year(date)) |>
  dplyr::summarise(Wert = sum(hgt, na.rm = TRUE), .groups = 'drop') |>
  dplyr::mutate(Gebiet = "Zürich Fluntern",
                Einheit = ds$dimension_unit,
                Wert = round(Wert, 0)) |>
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source,
                Variable = ds$dataset_name) |>
  dplyr::filter(Jahr >= 1990) |>
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

ds$export_data <- g4_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)

