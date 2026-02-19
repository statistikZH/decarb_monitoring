# M1 - Antriebsart bei Personenwagen - Fahrzeugbestand ----------------------------------------------------

## Additional remarks:
## Groupings Antriebsart: 1: Benzin, Diesel; 2: "Hybrid" -> [Benzin-elektrisch: Normal-Hybrid,Diesel-elektrisch: Normal-Hybrid];
## 3: "PlugIn-Hybrid" ->  [Benzin-elektrisch: Plug-in-Hybrid, Diesel-elektrisch: Plug-in-Hybrid]; 4: Gas [Gas (mono- und bivalent)], Anderer; 5: Wasserstoff; 6: Elektrisch

## Computations:
## 1. Anzahl: 'Total' (Treibstoffe[alle])
## 2. Anteil Elektrofahrzeuge (ohne Hybrid): 1 - ('Elektrisch' + 'Wasserstoff') / 'Total'

# Import data -------------------------------------------------------------

ds <- create_dataset("M1")
ds <- download_data(ds)

m1_data <- ds$data

# Filter auf Daten Kanton ZH sowie CH
data_sdmx <- m1_data |>
  dplyr::select(UV_HGDE_KT, UV_RV_FUEL, TIME_PERIOD, OBS_VALUE) |>
  dplyr::filter(UV_HGDE_KT %in% stringr::str_split(ds$gebiet_id, ",")[[1]])

# Datenreihen vervollständigen -> expand_grid
# Eindeutige Treibstoff, Zeitstempel und Kategorien extrahieren
unique_kt <- unique(data_sdmx$UV_HGDE_KT)
unique_fuel <- unique(data_sdmx$UV_RV_FUEL)
unique_time <- unique(data_sdmx$TIME_PERIOD)

# Kombinationen von Kanton, Zeitstempel und Treibstoffkategorie generieren
all_combinations <- expand.grid(UV_HGDE_KT = unique_kt, UV_RV_FUEL = unique_fuel, TIME_PERIOD = unique_time)

# Vollständige Datenreihe
data_sdmx <- all_combinations |>
  dplyr::left_join(data_sdmx) |>
  dplyr::mutate(OBS_VALUE = ifelse(is.na(OBS_VALUE), 0, OBS_VALUE))

# Computation: Anzahl & Anteil -----------------------------------------------------

# Initial data restructuring and renaming before we do the actual computations
m1_cleaned <- data_sdmx |>
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = UV_HGDE_KT, "Variable" = UV_RV_FUEL, "Jahr" = TIME_PERIOD, "Wert" = OBS_VALUE) |>
  dplyr::filter(Variable != "_T") |>
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
  dplyr::group_by(Gebiet, Jahr, Variable) |>
  dplyr::summarise(Wert = sum(Wert))

# Auxiliary variable for calculating the number of cars counting as Elektrofahrzeuge (ohne Hybrid); being 'Elektrisch'+'Wasserstoff'
m1_elektro <- m1_cleaned |>
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) |>
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") |>
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, Variable) |>
  dplyr::summarise(Wert = sum(Wert)) |>
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
m1_total <- m1_cleaned  |>
  dplyr::group_by(Gebiet, Jahr) |>
  dplyr::summarise(Total = sum(Wert))

m1_computed <- m1_cleaned |>
  dplyr::bind_rows(m1_elektro) |>
  dplyr::left_join(m1_total, by = c("Gebiet", "Jahr")) |>
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet) |>
  dplyr::mutate(Anteil = (Wert / Total)) |>
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) |>
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") |>
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

m1_export_data <- m1_computed |>
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "1", "Kanton Zürich", "Schweiz"),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Personenwagen (Anzahl)",
                                           Einheit == "Anteil" ~ "Personenwagen [%]",
                                           TRUE ~ Einheit)) |>
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) |>
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m1_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben
export_data(ds)
