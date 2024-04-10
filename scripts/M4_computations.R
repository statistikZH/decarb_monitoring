# M4 - Antriebsart bei Gütertransportfahrzeugen - Neuzulassungen ----------------------------------------------------

## Additional remarks:
## Groupings Antriebsart: 1: Benzin, Diesel; 2: "Hybrid" -> [Benzin-elektrisch: Normal-Hybrid,Diesel-elektrisch: Normal-Hybrid];
## 3: "PlugIn-Hybrid" ->  [Benzin-elektrisch: Plug-in-Hybrid, Diesel-elektrisch: Plug-in-Hybrid]; 4: Gas [Gas (mono- und bivalent)], Anderer; 5: Wasserstoff; 6: Elektrisch


## Computations:
## 1. Anzahl: 'Total' (Treibstoffe[alle])
## 2. Anteil Elektrofahrzeuge (ohne Hybrid): 1 - ('Elektrisch' + 'Wasserstoff') / 'Total'

# Import data -------------------------------------------------------------

ds <- create_dataset("M4")
ds <- download_data(ds)

m4_data <- ds$data

# Computation: Anzahl & Anteil -----------------------------------------------------

# Initial data restructuring and renaming before we do the actual computations
m4_cleaned <- m4_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Fahrzeugart" = `Fahrzeuggruppe / -art`, "Variable" = Treibstoff, "Wert" =  `Neue Inverkehrsetzungen von Strassenfahrzeugen`) %>%
  # clean the strings in Fahrzeugart -> reomve "... ", e. g. "... Lastwagen" to "Lastwagen"
  dplyr::mutate(Fahrzeugart = gsub("^\\.\\.\\. ", "", Fahrzeugart)) %>%
  # Doing the new grouping of the available categories
  dplyr::mutate(gruppe = dplyr::if_else(Fahrzeugart %in% c("Sattelmotorfahrzeug","Sattelschlepper", "Lastwagen"), "Lastwagen", Fahrzeugart)) %>%
  # Doing the new grouping of the Variable
  dplyr::mutate(Variable = dplyr::case_when(Variable %in% c("Benzin", "Diesel") ~ "Benzin, Diesel",
                                            Variable %in% c("Benzin-elektrisch: Normal-Hybrid","Diesel-elektrisch: Normal-Hybrid") ~ "Hybrid",
                                            Variable %in% c("Benzin-elektrisch: Plug-in-Hybrid", "Diesel-elektrisch: Plug-in-Hybrid") ~ "PlugIn-Hybrid",
                                            Variable == "Gas (mono- und bivalent)" ~"Gas",
                                            Variable %in% c("Anderer", "Ohne Motor") ~"Andere",
                                            TRUE ~ Variable
  )) %>%
  # Now sum up by the new groups
  dplyr::group_by(Gebiet, Jahr, gruppe, Variable) %>%
  dplyr::summarise(Wert = sum(Wert))

# Auxiliary variable for calculating the number of cars counting as Elektrofahrzeuge (ohne Hybrid); being 'Elektrisch'+'Wasserstoff'
m4_elektro <- m4_cleaned %>%
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) %>%
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, gruppe, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
m4_total <- m4_cleaned %>%
  dplyr::group_by(Gebiet, Jahr, gruppe) %>%
  dplyr::summarise(Total = sum(Wert))

m4_computed <- m4_cleaned %>%
  dplyr::bind_rows(m4_elektro) %>%
  dplyr::left_join(m4_total, by = c("Gebiet", "Jahr", "gruppe")) %>%
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet, gruppe) %>%
  dplyr::mutate(Anteil = round((Wert / Total),3)) %>%
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()

# Data structure ----------------------------------------------------------

m4_export_data <- m4_computed %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Neuzulassungen Sachentransportfahrzeuge (Anzahl)",
                                           Einheit == "Anteil" ~ "Neuzulassungen Sachentransportfahrzeuge [%]",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, gruppe, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m4_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
