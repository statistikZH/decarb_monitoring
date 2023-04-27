# EV3 - Anteil erneuerbar erzeugter Strom an Gesamtverbrauch Strom ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('EV3')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

EV3_data <- ds$data

# Berechnungen -----------------------------------------------------

EV3_computed <- EV3_data %>%
  dplyr::mutate(Gebiet = ds$gebiet_name) %>%
  tidyr::pivot_wider(names_from = Strom, values_from = Wert) %>%
  dplyr::mutate(nicht_erneuerbar = total - erneuerbar,
                anteil_erneuerbar = erneuerbar / total,
                anteil_nicht_erneuerbar = (total - erneuerbar) / total) %>%
  tidyr::pivot_longer(cols = c(total, erneuerbar, nicht_erneuerbar, anteil_erneuerbar, anteil_nicht_erneuerbar), values_to = "Wert")

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

EV3_export_data <- EV3_computed %>%
  dplyr::filter(name != "total") %>%
  dplyr::rename("Variable" = name) %>%
  # Renaming values
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Einheit = dplyr::case_when(
                  Variable %in% c("erneuerbar", "nicht_erneuerbar") ~ ds$dimension_label,
                  TRUE ~ "Prozent (%)"
                )) %>%
  dplyr::mutate(Variable = dplyr::if_else(Variable %in% c("erneuerbar", "anteil_erneuerbar"), "Erneuerbar erzeugter Strom", "Nicht-erneuerbar erzeugter Strom")) %>%
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- EV3_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
