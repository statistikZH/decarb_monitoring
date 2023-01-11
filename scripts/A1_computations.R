# A1 - Abfallmenge verbrannt in KVA Kanton Zürich ----------------------------------------------------
## Indicator:
indicator_id <- "A1"
indicator_name <- "Abfallmenge verbrannt in KVA"
## Variable:
variable <- "Recycled Waste"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2010
## Data url: https://opendata.swiss/de/dataset/kehrichtverbrennungsanlagen-kva
## Data sources:
data_source <- "Bundesamt für Energie"

## Computations:
## 1.Verwertete Abfallmenge: t/a
## 2 Verwertete Abfallmenge pro Kopf: t/a/Einw.

## Remarks: Values are per waste incineration plant (KVA), i.e. the figures for ZH and CH must be aggregated.

# Import data -------------------------------------------------------------

## Set the range of the time series defined in data file
access_url <- "https://data.geo.admin.ch/ch.bfe.kehrichtverbrennungsanlagen/kehrichtverbrennungsanlagen/kehrichtverbrennungsanlagen_2056.csv.zip"

file_name <- "RecycledWaste.csv"

## Download zip folder, unzip, extract csv file...
a1_data <- get_zip_data(access_url, file_name) %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = id) %>%
  tidyr::pivot_longer(cols = matches("(\\d){4}"), names_to = "Jahr", values_to = "Wert")

# Computation: Abfallmenge (t/a) & Abfallmenge pro Einwohner (t/a/Einw.) -----------------------------------------------------

## Getting population data for Kanton Zürich from indicator Q1
a1_population <- data.table::fread("output/Q1_data.csv") %>%
  # dplyr::filter(Gebiet == "Kanton Zürich") %>%
  dplyr::select(Jahr, Gebiet, "Einwohner" = Wert)

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
  dplyr::summarize(Wert = sum(Wert, na.rm = T), Einheit = "Tonnen pro Jahr (t/a)") %>%
  dplyr::ungroup() %>%
  # Joining population data
  dplyr::left_join(a1_population, by = c("Jahr", "Gebiet")) %>%
  # Compute per capita
  dplyr::mutate(`Tonnen pro Jahr pro Einwohner (t/a/Einw.)` = Wert / Einwohner) %>%
  dplyr::rename("Unit" = Einheit, "Value" = Wert) %>%
  dplyr::select(-Einwohner) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Value, `Tonnen pro Jahr pro Einwohner (t/a/Einw.)`), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

a1_export_data <- a1_computed %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::if_else(Einheit == "Value", "Tonnen pro Jahr (t/a)", Einheit)) %>%
  dplyr::select(-Unit) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = indicator_id,
                Indikator_Name = indicator_name,
                Variable = variable,
                Datenquelle = data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
dir.create("output", showWarnings = FALSE)

output_file <- paste0(indicator_id, "_data.csv")

utils::write.table(a1_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
