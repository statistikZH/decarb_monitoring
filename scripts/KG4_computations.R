# KG4 - Treibhausgas-Fussabdruck ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KG4')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

KG4_data <- ds$data

# Einlesen von Populationsdaten für per_capita
KG4_pop <- decarbmonitoring::download_per_capita() %>%
  dplyr::filter(Gebiet == "Schweiz")



# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

KG4_computed <- KG4_data %>%
  # HIER JEDES JAHR ANPASSEN!
  dplyr::slice(5:25) %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Jahr" = 1, "Wert" = 2) %>%
  dplyr::mutate(Jahr = as.numeric(Jahr),
                Wert = as.numeric(Wert)) %>%
  # Join mit Populationsdaten um Pro-Kopf zu berechnen
  dplyr::left_join(KG4_pop, by = "Jahr") %>%
  # nur Jahre mit Einwohnerdaten behalten
  tidyr::drop_na() %>%
  # Pro-Kopf berechnen
  dplyr::mutate(per_capita = Wert / Einwohner) %>%
  dplyr::mutate(Einheit = "Mio. Tonnen CO2-eq (pro Kopf)")
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

KG4_export_data <- KG4_computed %>%
  # Total wird nicht mehr benötigt
  dplyr::select(-Wert) %>%
  dplyr::rename("Wert" = "per_capita") %>%
  dplyr::mutate(Variable = "Treibhausgas") %>%
  # Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KG4_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
