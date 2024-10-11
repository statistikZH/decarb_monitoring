# KV4 - Alternative Antriebe in der kantonalen Flotte bei neu beschafften Fahrzeugen ---------

# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KV4')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung
# temp fix for reading in data
KV4_data <- ds$data

# Berechnungen -----------------------------------------------------
# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Anzahl Fahrzeuge pro Jahr und Fahrzeugkategorie
KV4_comp1 <- KV4_data %>%
  dplyr::group_by(Fahrzeugtyp, Jahr) %>%
  dplyr::mutate(total_fhz = sum(Anzahl_Fzg)) %>%
  dplyr::mutate(Wert = round(Anzahl_Fzg/total_fhz * 100, 0), Einheit = "Prozent (%)")

KV4_computed <- KV4_comp1 %>%
  dplyr::select(-total_fhz, -Anzahl_Fzg) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich") %>%
  dplyr::relocate(Variable = Antriebstechnologie, .before = Wert) %>%
  dplyr::relocate(Gebiet, .after = Jahr)

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


# Enrich KV4_computed with metadata
KV4_export_data <- KV4_computed %>%
  dplyr::mutate(
    Indikator_ID = ds$dataset_id,
    Indikator_Name = ds$indicator_name,
    Datenquelle = ds$data_source,
    Fahrzeugtyp = dplyr::case_when(
      Fahrzeugtyp == "Schwere Nutzfahrzeuge (N2/N3)" ~ "Lastwagen (N2/N3)",
      TRUE ~ as.character(Fahrzeugtyp)
    )
  ) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, "Gruppe" = Fahrzeugtyp, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- KV4_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben
export_data(ds)
