# M2 - Antriebsart bei Gütertransportfahrzeugen - Fahrzeugbestand ----------------------------------------------------

## Additional remarks:
## Groupings Antriebsart: 1: Benzin, Diesel; 2: "Hybrid" -> [Benzin-elektrisch: Normal-Hybrid,Diesel-elektrisch: Normal-Hybrid];
## 3: "PlugIn-Hybrid" ->  [Benzin-elektrisch: Plug-in-Hybrid, Diesel-elektrisch: Plug-in-Hybrid]; 4: Gas [Gas (mono- und bivalent)], Anderer; 5: Wasserstoff; 6: Elektrisch


## Computations:
## 1. Anzahl: 'Total' (Treibstoffe[alle])
## 2. Anteil Elektrofahrzeuge (ohne Hybrid): 1 - ('Elektrisch' + 'Wasserstoff') / 'Total'

# Import data -------------------------------------------------------------

ds <- create_dataset("M2")
ds <- download_data(ds)

m2_data <- ds$data

# Filter auf Daten Kanton ZH sowie CH
data_sdmx <- m2_data |>
  dplyr::select(UV_HGDE_KT, UV_RV_VEHICLE_GROUP_AND_TYPE, UV_RV_FUEL, TIME_PERIOD, OBS_VALUE) |>
  dplyr::filter(UV_HGDE_KT %in% stringr::str_split(ds$gebiet_id, ",")[[1]])

# Datenreihen vervollständigen -> expand_grid
# Eindeutige Treibstoff, Zeitstempel und Kategorien extrahieren
unique_kt <- unique(data_sdmx$UV_HGDE_KT)
unique_fuel <- unique(data_sdmx$UV_RV_FUEL)
unique_time <- unique(data_sdmx$TIME_PERIOD)

# Kombinationen von Kanton, Zeitstempel und Treibstoffkategorie generieren
all_combinations <- expand.grid(UV_HGDE_KT = unique_kt, UV_RV_FUEL = unique_fuel, TIME_PERIOD = unique_time)

# Vollständige Datenreihe, beim Attribut
data_sdmx <- all_combinations |>
  dplyr::left_join(data_sdmx) |>
  dplyr::mutate(OBS_VALUE = ifelse(is.na(OBS_VALUE), 0, OBS_VALUE))


# Computation: Anzahl & Anteil -----------------------------------------------------

# Initial data restructuring and renaming before we do the actual computations
m2_cleaned <- data_sdmx |>
  dplyr::rename("Gebiet" = UV_HGDE_KT, "Variable" = UV_RV_FUEL, "Jahr" = TIME_PERIOD, "Wert" = OBS_VALUE) |>
  dplyr::filter(Variable != "_T") |>
  # Doing the new grouping of the available categories
  dplyr::mutate(Gruppe = dplyr::if_else(UV_RV_VEHICLE_GROUP_AND_TYPE %in% c(35,36,38), "Lastwagen", "Lieferwagen")) |>
  # Doing the new grouping of the Variable
  dplyr::mutate(Variable = dplyr::case_when(Variable %in% c("PC", "DC") ~ "Benzin, Diesel",
                                            Variable %in% c("PH","DH") ~ "Hybrid",
                                            Variable %in% c("HP", "HD") ~ "PlugIn-Hybrid",
                                            Variable == "EL" ~"Elektrisch",
                                            Variable == "GA" ~"Gas",
                                            Variable == "FC" ~"Wasserstoff",
                                            Variable %in% c("NM", "_O") ~"Andere",
                                            TRUE ~ Variable
  )) |>
  # Now sum up by the new groups
  dplyr::group_by(Gebiet, Jahr, Gruppe, Variable) |>
  dplyr::summarise(Wert = sum(Wert))

# Auxiliary variable for calculating the number of cars counting as Elektrofahrzeuge (ohne Hybrid); being 'Elektrisch'+'Wasserstoff'
m2_elektro <- m2_cleaned |>
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) |>
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") |>
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, Gruppe, Variable) |>
  dplyr::summarise(Wert = sum(Wert)) |>
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
m2_total <- m2_cleaned |>
  dplyr::group_by(Gebiet, Jahr, Gruppe) |>
  dplyr::summarise(Total = sum(Wert))

m2_computed <- m2_cleaned |>
  dplyr::bind_rows(m2_elektro) |>
  dplyr::left_join(m2_total, by = c("Gebiet", "Jahr", "Gruppe")) |>
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet, Gruppe) |>
  dplyr::mutate(Anteil = round((Wert / Total),3)) |>
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) |>
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") |>
  dplyr::ungroup()

# Data structure ----------------------------------------------------------
m2_export_data <- m2_computed |>
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "1", "Kanton Zürich", "Schweiz"),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Anzahl",
                                           Einheit == "Anteil" ~ "Prozent (%)",
                                           TRUE ~ Einheit)) |>
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) |>
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Gruppe, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m2_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
