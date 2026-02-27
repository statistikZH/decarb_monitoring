# Q1 - Einwohner:innen ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('Q1')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

Q1_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

Q1_computed <- Q1_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename('Gebiet' = `Kanton (-) / Bezirk (>>) / Gemeinde (......)`, 'Variable' = `Demografische Komponente`, 'Wert' = `Demografische Bilanz nach institutionellen Gliederungen`) %>%
  # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel' + 'Gas (mono- und bivalent)'
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "- Zürich", "Kanton Zürich", Gebiet),
                Einheit = "Anzahl Personen")


# Harmonisierung Datenstruktur / Bezeichnungen  ----------------------------------------------------------

# Schritt 3 : Hier werden die Daten in die finale Form gebracht

# - Angleichung der Spaltennamen / Kategorien und Einheitslabels an die Konvention
# - Anreicherung mit Metadaten aus der Datensatzliste

Q1_export_data <- Q1_computed %>%
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- Q1_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
