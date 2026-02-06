# LF3 - Eingesetzter Stickstoffdünger ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('LF3')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

LF3_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

LF3_computed <- LF3_data %>%
  tidyr::pivot_wider(names_from = Düngerart, values_from = Wert) %>%
  dplyr::mutate(Total = rowSums(pick(tidyselect::contains("ünger")))) %>%
  tidyr::pivot_longer(cols = dplyr::where(is.double), names_to = "Variable", values_to = "Wert") %>%
  dplyr::mutate(Variable = stringr::str_replace(Variable, "_", "/")) %>%
  dplyr::select(-Einheit) %>%
  dplyr::rename(Einheit = `Einheit lang`) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich")


# Harmonisierung Datenstruktur / Bezeichnungen  ----------------------------------------------------------

# Schritt 3 : Hier werden die Daten in die finale Form gebracht

# - Angleichung der Spaltennamen / Kategorien und Einheitslabels an die Konvention
# - Anreicherung mit Metadaten aus der Datensatzliste

LF3_export_data <- LF3_computed %>%
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- LF3_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
