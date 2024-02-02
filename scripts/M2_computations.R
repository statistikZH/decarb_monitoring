# M2 - Antriebsart bei Gütertransportfahrzeugen - Fahrzeugbestand ----------------------------------------------------

## Additional remarks:
## Groupings Antriebsart: 1: Benzin, Diesel; 2: "Hybrid" -> [Benzin-elektrisch: Normal-Hybrid,Diesel-elektrisch: Normal-Hybrid];
## 3: "PlugIn-Hybrid" ->  [Benzin-elektrisch: Plug-in-Hybrid, Diesel-elektrisch: Plug-in-Hybrid]; 4: Gas [Gas (mono- und bivalent)], Anderer; 5: Wasserstoff; 6: Elektrisch


## Computations:
## 1. Anzahl: 'Total' (Treibstoffe[alle])
## 2. Anteil Elektrofahrzeuge (ohne Hybrid): 1 - ('Elektrisch' + 'Wasserstoff') / 'Total'

# Import data -------------------------------------------------------------

ds <- create_dataset("M2")
ds <- download_data(ds)

m2_data <- ds$data

# Computation: Anzahl & Anteil -----------------------------------------------------

# Initial data restructuring and renaming before we do the actual computations
m2_cleaned <- m2_data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Variable" = Treibstoff, "Wert" = `Bestand der Sachentransportfahrzeuge`) %>%
  # Doing the new grouping of the Variable
  dplyr::mutate(Variable = dplyr::case_when(Variable %in% c("Benzin", "Diesel") ~ "Benzin, Diesel",
                                            Variable %in% c("Benzin-elektrisch: Normal-Hybrid","Diesel-elektrisch: Normal-Hybrid") ~ "Hybrid",
                                            Variable %in% c("Benzin-elektrisch: Plug-in-Hybrid", "Diesel-elektrisch: Plug-in-Hybrid") ~ "PlugIn-Hybrid",
                                            Variable == "Gas (mono- und bivalent)" ~ "Gas",
                                            Variable == "Anderer" ~ "Andere",
                                            TRUE ~ Variable
  )) %>%
  # Now sum up by the new groups
  dplyr::group_by(Gebiet, Jahr, Variable) %>%
  dplyr::summarise(Wert = sum(Wert))

# Auxiliary variable for calculating the number of cars counting as Elektrofahrzeuge (ohne Hybrid); being 'Elektrisch'+'Wasserstoff'
m2_elektro <- m2_cleaned %>%
  dplyr::filter(Variable %in% c("Elektrisch", "Wasserstoff")) %>%
  dplyr::mutate(Variable = "Elektrofahrzeuge (ohne Hybrid)") %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Gebiet, Jahr, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Treibstoffe[alle])
m2_total <- m2_cleaned %>%
  dplyr::group_by(Gebiet, Jahr) %>%
  dplyr::summarise(Total = sum(Wert))

m2_computed <- m2_cleaned %>%
  dplyr::bind_rows(m2_elektro) %>%
  dplyr::left_join(m2_total, by = c("Gebiet", "Jahr")) %>%
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Anteil = round((Wert / Total),3)) %>%
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()

# Data structure ----------------------------------------------------------

m2_export_data <- m2_computed %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ "Gütertransportfahrzeuge (Anzahl)",
                                           Einheit == "Anteil" ~ "Gütertransportfahrzeuge [%]",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m2_export_data


# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)

