# A1 - Abfallmenge verbrannt in KVA Kanton Zürich ----------------------------------------------------

## Variable: "Recycled Waste"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2010
## Data url: https://opendata.swiss/de/dataset/kehrichtverbrennungsanlagen-kva
## Data sources: "Bundesamt für Energie"

## Computations:
## 1.Verwertete Abfallmenge: t/a
## 2 Verwertete Abfallmenge pro Kopf: t/a/Einw.

## Remarks: Values are per waste incineration plant (KVA), i.e. the figures for ZH and CH must be aggregated.

# Import data -------------------------------------------------------------

ds <- create_dataset("A1")
ds <- download_data(ds)

a1_data <- ds$data %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert")

a1_2_data <- ds$dep[[1]] %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert")

a1_3_data <- ds$dep[[2]] %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert")

## Einschub - Daten unter opendata.swiss sind nicht sauber nachgeführt!
#  Der Standort KVA Josefstrasse ist mit der Aktualisierung auf die
#  2022er verschwunden...
#  BFE als Datenlieferant ist informiert und hat versprochen den Standort
#  Josefstrasse mit der Aktualisierung der 2023er Daten wieder zu integrieren
#  Vorderhand braucht es einen kleinen Einschub damit die Zeitreihe
#  vollständige Daten ausweist

dir = "C:/Users/Public/kehrichtverbrennungsanlagen_Stand2021_inkl_Josefstrasse/"

## Recycled Waste
a1_data_21 <- readr::read_delim(paste0(dir,"RecycledWaste.csv"), delim = ",") %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert") %>%
  dplyr::filter(Gebiet == "ZH_5") %>%
  dplyr::add_row(Name = "ZH Josefstrasse ", Gebiet = "ZH_5", Jahr = "2022", Wert = NA)

a1_data <- dplyr::bind_rows(a1_data, a1_data_21)

## Heat
a1_2_data_21 <- readr::read_delim(paste0(dir,"Heat.csv"), delim = ",") %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert") %>%
  dplyr::filter(Gebiet == "ZH_5") %>%
  dplyr::add_row(Name = "ZH Josefstrasse ", Gebiet = "ZH_5", Jahr = "2022", Wert = NA)

a1_2_data <- dplyr::bind_rows(a1_2_data, a1_2_data_21)

## Electricity
a1_3_data_21 <- readr::read_delim(paste0(dir,"Electricity.csv"), delim = ",") %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert") %>%
  dplyr::filter(Gebiet == "ZH_5") %>%
  dplyr::add_row(Name = "ZH Josefstrasse ", Gebiet = "ZH_5", Jahr = "2022", Wert = NA)

a1_3_data <- dplyr::bind_rows(a1_3_data, a1_3_data_21)

## Einschub beendet

# Computation: Abfallmenge (t/a) & Abfallmenge pro Einwohner (t/a/Einw.) -----------------------------------------------------

## Getting population data for Kanton Zürich from indicator Q1 with helper function
a1_population <- decarbmonitoring::download_per_capita()

a1_computed <- a1_data %>%
  # Compute Wert for Schweiz (sum of all values)
  dplyr::group_by(Jahr) %>%
  dplyr::summarise(Wert = sum(Wert, na.rm = T), Gebiet = "Schweiz") %>%
  dplyr::ungroup() %>%
  dplyr::bind_rows(a1_data, . ) %>%
  dplyr::select(-Name) %>%
  # Rename Gebiet for Kanton Zürich
  dplyr::mutate(Gebiet = dplyr::if_else(startsWith(Gebiet, "ZH"), "Kanton Zürich", Gebiet),
                Jahr = as.numeric(Jahr)) %>%
  dplyr::filter(Gebiet %in% c("Schweiz", "Kanton Zürich")) %>%
  # Compute Wert for Kanton Zürich (sum of all values for Gebiet == "Kanton Zürich")
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::summarize(Wert = sum(Wert, na.rm = T), Einheit = "Tonnen (t)") %>%
  dplyr::ungroup() %>%
  # Joining population data
  dplyr::left_join(a1_population, by = c("Jahr", "Gebiet")) %>%
  # Compute per capita
  dplyr::mutate(`Tonnen pro Person (t/Person)` = Wert / Einwohner) %>%
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `Tonnen pro Person (t/Person)`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::mutate(Variable = "Verbrannte Abfallmenge") %>%
  dplyr::ungroup()


# Computation Wärmeproduktion aus KVA pro Einwohner (Megawattstunden (MWh)) -----------------------------------------------------

a1_2_computed <- a1_2_data %>%
  # Compute Wert for Schweiz (sum of all values)
  dplyr::group_by(Jahr) %>%
  dplyr::summarise(Wert = sum(Wert, na.rm = T), Gebiet = "Schweiz") %>%
  dplyr::ungroup() %>%
  dplyr::bind_rows(a1_2_data, . ) %>%
  dplyr::select(-Name) %>%
  # Rename Gebiet for Kanton Zürich
  dplyr::mutate(Gebiet = dplyr::if_else(startsWith(Gebiet, "ZH"), "Kanton Zürich", Gebiet),
                Jahr = as.numeric(Jahr)) %>%
  dplyr::filter(Gebiet %in% c("Schweiz", "Kanton Zürich")) %>%
  # Compute Wert for Kanton Zürich (sum of all values for Gebiet == "Kanton Zürich")
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::summarize(Wert = sum(Wert, na.rm = T), Einheit = "Megawattstunden (MWh)") %>%
  dplyr::ungroup() %>%
  # Joining population data
  dplyr::left_join(a1_population, by = c("Jahr", "Gebiet")) %>%
  # Compute per capita
  dplyr::mutate(`Megawattstunden pro Person (MWh/Person)` = Wert / Einwohner) %>%
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `Megawattstunden pro Person (MWh/Person)`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::mutate(Variable = "Wärmeproduktion") %>%
  dplyr::ungroup()



# Computation Elekrizität aus KVA pro Einwohner (Megawattstunden (MWh)) -----------------------------------------------------

a1_3_computed <- a1_3_data %>%
  # Compute Wert for Schweiz (sum of all values)
  dplyr::group_by(Jahr) %>%
  dplyr::summarise(Wert = sum(Wert, na.rm = T), Gebiet = "Schweiz") %>%
  dplyr::ungroup() %>%
  dplyr::bind_rows(a1_3_data, . ) %>%
  dplyr::select(-Name) %>%
  # Rename Gebiet for Kanton Zürich
  dplyr::mutate(Gebiet = dplyr::if_else(startsWith(Gebiet, "ZH"), "Kanton Zürich", Gebiet),
                Jahr = as.numeric(Jahr)) %>%
  dplyr::filter(Gebiet %in% c("Schweiz", "Kanton Zürich")) %>%
  # Compute Wert for Kanton Zürich (sum of all values for Gebiet == "Kanton Zürich")
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::summarize(Wert = sum(Wert, na.rm = T), Einheit = "Megawattstunden (MWh)") %>%
  dplyr::ungroup() %>%
  # Joining population data
  dplyr::left_join(a1_population, by = c("Jahr", "Gebiet")) %>%
  # Compute per capita
  dplyr::mutate(`Megawattstunden pro Person (MWh/Person)` = Wert / Einwohner) %>%
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `Megawattstunden pro Person (MWh/Person)`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::mutate(Variable = "Stromproduktion") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------


a1_export_data <- a1_computed %>%
  # bind the three separate tables together
  dplyr::bind_rows(a1_2_computed, a1_3_computed) %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::if_else(Einheit == "Value", Unit, Einheit)) %>%
  dplyr::select(-Unit) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- a1_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
