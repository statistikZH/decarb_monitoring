# Q1 - Einwohner:innen ----------------------------------------------------
## Indicator:
indicator_id <- "Q1"
indicator_name <- "Einwohner:innen"
## Variable:
variable <- "Ständige Wohnbevölkerung"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2010
## Data url: https://www.bfs.admin.ch/asset/de/px-x-0103010000_102
## Data sources:
data_source <- "Statistik der Bevölkerung und der Haushalte STATPOP (BFS)"

## Computations: None

# Import data -------------------------------------------------------------

## Setting the range of the time series, and continue the range every new year
start_year <- "2010"
end_year <- lubridate::year(Sys.Date()- lubridate::years(1))
year_range <- start_year:end_year

## Path name of the data cube
q1_px_path <- "px-x-0103010000_102"

## Pre-constructed list element containing all query parameters
q1_query_list <- list("Jahr"=as.character(year_range),
                      "Kanton"=c("8100","ZH"), # Spatial level: Schweiz und Kanton Zürich
                      "Bevölkerungstyp"=c("1")) # Indicator: Ständige Wohnbevölkerung

## Download data based on query list and convert to data.frame
q1_data <- get_pxdata(q1_px_path, q1_query_list) %>%
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename("Gebiet" = Kanton, "Indikator" = Bevölkerungstyp, "Wert" = `Ständige und nichtständige Wohnbevölkerung`)


# Data structure ----------------------------------------------------------

q1_export_data <- q1_data %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = "Personen [Anz.]") %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = indicator_id,
                Indikator_Name = indicator_name,
                Variable = variable,
                Datenquelle = data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, "Variable" = Indikator, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
dir.create("output", showWarnings = FALSE)

output_file <- paste0(indicator_id, "_data.csv")

utils::write.table(q1_export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
