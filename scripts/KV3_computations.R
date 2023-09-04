# KV3 - Treibhausgasemissionen kantonale Fahrzeugflotte ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KV3')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung
# temp fix for reading in data
KV3_data <- ds$data

# Berechnungen -----------------------------------------------------
# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

KV3_computed <- KV3_data %>%
  dplyr::mutate(Gebiet = "Kanton Zürich") %>%
  # nur die Variable Treibhausgasemissionen wird hier betrachtet
  dplyr::select(-c("Fahrzeugbestand", "Verkehrsleistung", "Treibhausgasemissionen")) %>%
  # hier könnte bei Bedarf noch "Emissionen_pro_km" bei values_from ergänzt werden
  tidyr::pivot_wider(names_from = Fahrzeugtyp, values_from = c(Emissionen_pro_km)) %>%
  dplyr::mutate(total_emissionen = `Personenwagen (M1)` + `Lieferwagen (N1)` + `Lastwagen (N2/N3)`,
                anteil_personenwagen = `Personenwagen (M1)` / total_emissionen,
                anteil_lieferwagen = `Lieferwagen (N1)` / total_emissionen,
                anteil_lastwagen = `Lastwagen (N2/N3)` / total_emissionen) %>%
  tidyr::pivot_longer(cols = c(dplyr::starts_with("anteil"), dplyr::contains("wagen")), values_to = "Wert") %>%
  dplyr::select(-total_emissionen) %>%
  dplyr::mutate(Einheit = dplyr::case_when(
    stringr::str_detect(name, "anteil") ~ "Prozent (%)",
    TRUE ~ "g CO2eq/km"
  )) %>%
  dplyr::mutate(name = dplyr::case_when(
    stringr::str_detect(name, "anteil_personenwagen") ~ "Personenwagen (M1)",
    stringr::str_detect(name, "anteil_lieferwagen") ~ "Lieferwagen (N1)",
    stringr::str_detect(name, "anteil_lastwagen") ~ "Lastwagen (N2/N3)",
    TRUE ~ name
  )) %>%
  dplyr::rename("Variable" = name)




# Die Voraussetzung für den letzten Schritt (3) ist ein Datensatz im long Format nach folgendem Beispiel:

# # A tibble: 216 × 5
#    Jahr  Gebiet  Treibstoff_Typ Einheit         Wert
#    <chr> <chr>   <chr>          <chr>          <dbl>
#  1 2005  Schweiz fossil         Anzahl  306455
#  2 2005  Schweiz fossil         Total   307161
#  3 2005  Schweiz fossil         Anteil       0.998
#  4 2005  Schweiz fossil-free    Anzahl     706
#  5 2005  Schweiz fossil-free    Total   307161

# Harmonisierung Datenstruktur / Bezeichnungen  ----------------------------------------------------------

# Schritt 3 : Hier werden die Daten in die finale Form gebracht

# - Angleichung der Spaltennamen / Kategorien und Einheitslabels an die Konvention
# - Anreicherung mit Metadaten aus der Datensatzliste

KV3_export_data <- KV3_computed %>%
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::mutate(Einheit = case_when(Einheit == "g CO2eq/km" ~ ds$dimension_unit,
                              TRUE ~ as.character(Einheit))) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KV3_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
