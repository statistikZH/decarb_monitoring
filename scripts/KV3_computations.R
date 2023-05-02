# KV3 - Treibhausgasemissionen kantonale Fahrzeugflotte ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KV3')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

KV3_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

KV3_computed <- KV3_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename('Gebiet' = Kanton, 'Variable' = Treibstoff, 'Wert' = `Neue Inverkehrsetzungen von Strassenfahrzeugen`) %>%
  # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel' + 'Gas (mono- und bivalent)'
  dplyr::mutate(Treibstoff_Typ = dplyr::if_else(Variable %in% c('Benzin', 'Diesel', 'Gas (mono- und bivalent)'), 'fossil', 'fossil-free')) %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Jahr, Gebiet, Treibstoff_Typ) %>%
  dplyr::summarise(Anzahl = sum(Wert)) %>%
  dplyr::ungroup() %>%
  # Adding the total number of cars by year and spacial unit and calculate the share by fuel type
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Total = sum(Anzahl),
                Anteil = (Anzahl / Total)) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = 'Einheit', values_to = 'Wert') %>%
  dplyr::ungroup()

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
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KV3_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)