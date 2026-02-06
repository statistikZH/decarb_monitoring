# KV6 - Anzahl Dieselbusse im ZVV ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KV6')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

KV6_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

KV6_computed <- KV6_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::mutate(Einheit = "Anzahl Dieselbusse",
                Gebiet = "Kanton")

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

KV6_export_data <- KV6_computed %>%
# Beispiel - dieser Block dient nur der Veranschalichung und muss je nach Fall angepasst werden --------
# dplyr::filter(Einheit != 'Total') %>%
# dplyr::rename('Variable' = Treibstoff_Typ) %>%
# # Renaming values
# dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == 'Zürich', 'Kanton Zürich', Gebiet),
#               Variable = dplyr::if_else(Variable == 'fossil', 'fossiler Treibstoff', 'fossilfreier Treibstoff'),
#               Einheit = dplyr::case_when(Einheit == 'Anzahl' ~ paste0(ds$dimension_label, ' [Anz.]'),
#                                          Einheit == 'Anteil' ~ paste0(ds$dimension_label, ' [%]'),
#                                          TRUE ~ Einheit)) %>%
# ----------------------
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source,
                Variable = ds$dataset_name) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KV6_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
