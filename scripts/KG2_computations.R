# KG2 - Anteil erneuerbares Kerosin an totalem Kerosin Flughafen Zürich ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KG2')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

KG2_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Anteil berechnen
KG2_computed <- KG2_data %>%
  # wide format für Berechnung
  tidyr::pivot_wider(names_from = Treibstoff, values_from = Kerosin) %>%
  dplyr::mutate(Anteil_SAF = SAF / total) %>%
  tidyr::pivot_longer(cols = c(total, SAF, Anteil_SAF), values_to = "Wert")

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

KG2_export_data <- KG2_computed %>%
  dplyr::filter(name != "total") %>%
  dplyr::rename("Variable" = name) %>%
  # Renaming values
  dplyr::mutate(Gebiet = "Flughafen Zürich",
                Einheit = dplyr::case_when(
                  Variable == "SAF" ~ "Tonnen Kerosin",
                  TRUE ~ "Tonnen Kerosin [%]"
                )) %>%
  dplyr::mutate(Variable = "Erneuerbares Kerosin") %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KG2_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
