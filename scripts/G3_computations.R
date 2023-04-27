# G3 - Energiebedarf für Raumwärme und Warmwasser bei reinen Wohnbauten im Kanton Zürich nach Gebäudealtersklassen ----------------------------------------------------

# Import data -------------------------------------------------------------

ds <- create_dataset("G3")
ds <- download_data(ds)

g3_data <- ds$data

# Computation:  -----------------------------------------------------

# None

# Data structure ----------------------------------------------------------
g3_export_data <- g3_data %>%
  tidyr::drop_na() %>%
  dplyr::rename("Wert" = "Energiebedarf", "Jahr" = "Bedarfsjahr", "Variable" = "Bauperiode") %>%
  dplyr::mutate(Variable = paste("Bauperiode", Variable, sep = " ")) %>%
  # Renaming values
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Einheit = ds$dimension_unit) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- g3_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
