# IG3 - Treibhauswirkung Kältemittel in grösseren Kälteanlagen ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('IG3')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

IG3_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# keine computation nötig
IG3_computed <- IG3_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename('Wert' = durchschnittliches_GWP) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Variable = "Durchschnittliche Treibhauswirkung (Global Warming Potential - GWP)")


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

IG3_export_data <- IG3_computed %>%
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Einheit = ds$dimension_unit,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- IG3_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
