# G4 - Heizgradtage

# Import data -------------------------------------------------------------

ds <- create_dataset("G4")
ds <- download_data(ds)

g4_data <- ds$data

# Computation:  -----------------------------------------------------

# None

# Data structure ----------------------------------------------------------

g4_export_data <- g4_data %>%
  dplyr::select(4:ncol(g4_data)) %>%
  janitor::row_to_names(16) %>%
  dplyr::slice(1) %>%
  dplyr::mutate(dplyr::across(.fns = as.numeric)) %>%
  tidyr::pivot_longer(cols = everything(), names_to = c("Jahr"), values_to = "Wert") %>%
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Einheit = paste("Anzahl", ds$dataset_name,"[Anz.]", sep = " ")) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source,
                Variable = ds$dataset_name) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

ds$export_data <- g4_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)

