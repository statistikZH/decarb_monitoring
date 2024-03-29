# M8 - Endenergieverbrauch fossiler Treibstoffe ----------------------------------------------------

## Computations:
## 1. Verbrauch: Gigawattstunden (GWh)
## 2. Verbrauch pro Einwohner: GWh/Einwohner



# Import data -------------------------------------------------------------

ds <- create_dataset("M8")
ds <- download_data(ds)

m8_data <- ds$data %>%
  dplyr::filter(Energiesektor == "Treibstoff") %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Variable" = Energiesektor)



# Computation: Anzahl & Anzahl pro Einwohner -----------------------------------------------------

## Getting population data for Kanton Zürich from indicator Q1
m8_population <- decarbmonitoring::download_per_capita() %>%
  dplyr::filter(Gebiet == "Kanton Zürich")


m8_computed <- m8_data %>%
  # Joining population data
  dplyr::left_join(m8_population, by = "Jahr") %>%
  # Compute per capita
  dplyr::mutate(`MWh pro Person` = (Wert / Einwohner)*1000) %>% # pro Einwohner wird in MWh angegeben
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `MWh pro Person`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

m8_export_data <- m8_computed %>%
  # Renaming values
  dplyr::mutate(Einheit = dplyr::if_else(Einheit == "Value", "Gigawattstunden (GWh)", "Megawattstunden pro Person (MWh/Person)")) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Variable = ds$dimension1_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m8_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
