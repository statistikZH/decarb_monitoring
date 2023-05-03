# EV2 - Produktion von Strom aus erneuerbaren Energieträgern ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('EV2')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

EV2_data <- ds$data

# Berechnungen -----------------------------------------------------

# Bevölkerungszahlen benötigt für per_capita (gefiltert auf Kanton Zürich)
EV2_pop <- decarbmonitoring::download_per_capita()%>%
  dplyr::filter(Gebiet == "Kanton Zürich")

# Annahme: nur das total pro Jahr sowie per_capita vom total pro Jahr werden visualisiert

EV2_computed <- EV2_data %>%
  dplyr::filter(Energiesektor == "Strom") %>%
  dplyr::mutate(Wert = dplyr::case_when(
    is.na(Wert) ~ 0,
    TRUE ~ as.numeric(Wert)
  )) %>%
  dplyr::group_by(Jahr) %>%
  dplyr::summarise(Total = sum(Wert)) %>%
  dplyr::left_join(EV1_pop, by = "Jahr") %>%
  dplyr::mutate(per_capita = Total / Einwohner) %>%
  dplyr::select(-Einwohner) %>%
  tidyr::pivot_longer(cols = c("Total", "per_capita"), names_to = "Einheit", values_to = "Wert") %>%
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

EV2_export_data <- EV2_computed %>%
  # Renaming values
  dplyr::mutate(Einheit = dplyr::case_when(Einheit == "Total" ~ "Megawattstunden (MWh)",
                                           Einheit == "per_capita" ~ "Megawattstunden pro Person (MWh/Person)",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source,
                Variable = "Strom aus erneuerbaren Energieträgern") %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)


# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- EV2_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
