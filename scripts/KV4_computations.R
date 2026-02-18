# KV4 - Alternative Antriebe in der kantonalen Flotte bei neu beschafften Fahrzeugen ---------

# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('KV4')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung
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
