# M5 - Fossilfreie Neuzulassungen Güterverkehr ----------------------------------------------------

## Computations:
## 1. Anzahl pro Gebiet
## 2. Anteil pro Gebiet und Jahr

# Import data -------------------------------------------------------------

ds <- create_dataset("M2")
ds <- download_data(ds)

m2_data <- ds$data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Variable" = Treibstoff, "Wert" = `Bestand der Sachentransportfahrzeuge`)

# Computation: Anzahl & Anteil -----------------------------------------------------

m2_computed <- m2_data  %>%
  # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel' + 'Gas (mono- und bivalent)'
  dplyr::mutate(Treibstoff_Typ = dplyr::if_else(Variable %in% c("Benzin", "Diesel"), "fossil", "fossil-free")) %>%
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

m2_export_data <- m2_computed %>%
  dplyr::filter(Einheit != "Total") %>%
  dplyr::rename("Variable" = Treibstoff_Typ) %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Variable = dplyr::if_else(Variable == "fossil", "fossiler Treibstoff", "fossilfreier Treibstoff"),
                Einheit = dplyr::case_when(Einheit == "Anzahl" ~ paste0(ds$dimension_label, " [Anz.]"),
                                           Einheit == "Anteil" ~ paste0(ds$dimension_label, " [%]"),
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m2_export_data


# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
