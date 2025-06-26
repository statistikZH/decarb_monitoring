# G5 - Heizungsersatz - Anzahl fossil betriebener Feuerungen ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('G5')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

G5_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

G5_computed <- G5_data |>
  dplyr::select(-n_Gemeinden) |>
  dplyr::filter(Jahr >= 2015 & Jahr <= 2023) |>
  tidyr::pivot_longer(!Jahr, names_to = "Variable", values_to = "Wert")

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

G5_export_data <- G5_computed |>
# Anreicherung  mit Metadaten
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Einheit = ds$dimension_unit,
                Datenquelle = ds$data_source) |>
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- G5_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
