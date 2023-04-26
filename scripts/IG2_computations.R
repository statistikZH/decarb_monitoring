# IG2 - Antriebsart bei Industriefahrzeugen - Fahrzeugbestand ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('IG2')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

IG2_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

IG2_cleaned <- IG2_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Variable" = Treibstoff, "Wert" = `Bestand der Industriefahrzeuge`) %>%
  # Doing the new grouping of the Variable
  dplyr::mutate(Variable = dplyr::case_when(Variable %in% c("Benzin", "Diesel") ~ "Benzin, Diesel",
                                            Variable %in% c("Benzin-elektrisch: Hybrid","Diesel-elektrisch: Hybrid") ~ "Hybrid",
                                            Variable == "Gas (mono- und bivalent)" ~ "Gas",
                                            Variable == "Anderer" ~ "Andere",
                                            TRUE ~ Variable
  )) %>%
  # Now sum up by the new groups
  dplyr::group_by(Gebiet, Jahr, Variable) %>%
  dplyr::summarise(Wert = sum(Wert))



# Auxiliary variable for calculating the number of cars counting as Elektrofahrzeuge (ohne Hybrid); being 'Elektrisch'+'Wasserstoff'
IG2_fossil_free <- IG2_cleaned %>%
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) %>%
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
IG2_total <- IG2_cleaned %>%
  dplyr::group_by(Gebiet, Jahr) %>%
  dplyr::summarise(Total = sum(Wert))

IG2_computed <- IG2_cleaned %>%
  dplyr::bind_rows(IG2_fossil_free) %>%
  dplyr::left_join(IG2_total, by = c("Gebiet", "Jahr")) %>%
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Anteil = round((Wert / Total),3)) %>%
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") %>%
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

IG2_export_data <- IG2_computed %>%
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Industriefahrzeuge [Anz.]",
                                           Einheit == "Anteil" ~ "Industriefahrzeuge [%]",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- IG2_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)
