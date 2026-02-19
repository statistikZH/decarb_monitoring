# IG2 - Antriebsart bei Industriefahrzeugen - Fahrzeugbestand ----------------------------------------------------

# Import data -------------------------------------------------------------

ds <- create_dataset('IG2')
ds <- download_data(ds)

IG2_data <- ds$data

# Filter auf Daten Kanton ZH sowie CH
data_sdmx <- IG2_data |>
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

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

IG2_cleaned <- data_sdmx |>
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
IG2_fossil_free <- IG2_cleaned |>
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) |>
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") |>
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, Variable) |>
  dplyr::summarise(Wert = sum(Wert)) |>
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
IG2_total <- IG2_cleaned |>
  dplyr::group_by(Gebiet, Jahr) |>
  dplyr::summarise(Total = sum(Wert))

IG2_computed <- IG2_cleaned |>
  dplyr::bind_rows(IG2_fossil_free) |>
  dplyr::left_join(IG2_total, by = c("Gebiet", "Jahr")) |>
  dplyr::group_by(Jahr, Gebiet) |>
  dplyr::mutate(Anteil = round((Wert / Total),3)) |>
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) |>
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") |>
  dplyr::ungroup()

# Data structure ----------------------------------------------------------

IG2_export_data <- IG2_computed |>
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "1", "Kanton Zürich", "Schweiz"),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Industriefahrzeuge (Anzahl)",
                                           Einheit == "Anteil" ~ "Prozent (%)",
                                           TRUE ~ Einheit)) |>
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) |>
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- IG2_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben
export_data(ds)
