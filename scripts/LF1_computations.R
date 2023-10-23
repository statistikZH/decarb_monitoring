# LF1 - Anzahl Rindvieh ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('LF1')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

LF1_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Einlesen von Populationsdaten für per_capita
LF1_pop <- decarbmonitoring::download_per_capita()

LF1_computed <- LF1_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Variable" = 1, "Gebiet" = 2, "Wert" = 4) %>%
  # remove unwanted artifacts in Gebiet variable
  dplyr::mutate(Gebiet = stringr::str_remove(Gebiet, stringr::fixed("** "))) %>%
  # prepare for join with pop data
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich" | Gebiet =="- Zürich", "Kanton Zürich", Gebiet),
                Jahr = as.numeric(Jahr)) %>%
  # join with population data
  dplyr::left_join(LF1_pop, by = c("Jahr", "Gebiet")) %>%
  # delete NA (years with no pop data) %>%
  tidyr::drop_na() %>%
  dplyr::mutate("Anzahl Rinder pro Person" = Wert / Einwohner) %>%
  tidyr::pivot_longer(cols = c("Wert", "Anzahl Rinder pro Person"), names_to = "Einheit") %>%
  dplyr::select(-Einwohner) %>%
  dplyr::rename("Wert" = "value") %>%
  dplyr::mutate(Einheit = dplyr::if_else(Einheit == "Wert", "Anzahl Rinder (Absolut)", Einheit))


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

LF1_export_data <- LF1_computed %>%
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source,
                Variable = ds$dataset_name) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- LF1_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
