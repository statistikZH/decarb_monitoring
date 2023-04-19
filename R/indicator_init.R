#' Initialisiere ein neues Skript für einen neuen Indikator
#'
#' @param indicator_id ID of the indicator available in the indicator-list dataset
#' @param indicator_dataset indicator list
#'
#' @return script
#'
#' @import whisker whisker.render
#'
#' @export
#'
#' @examples
#'
#' indicator_init("M3", ds)
#'
#' indicator_init("M100",ds_l)

# indicator_id <- "M10"
# dataset_list <- data.frame()

indicator_init <- function(indicator_id, dataset_list){

## Checks -----------

# Check if a script for the Indicator exists already and abort if this is the case
if(file.exists(paste0("scripts/", indicator_id,"_computations.R"))) cli::cli_abort(c("x" = "Skript für diesen Indikator besteht bereits"))

# Check if the indicator is listed in the Indicator-List
if(!is.list(dataset_list)) cli::cli_alert_warning("Datensatz-Liste ist keine Liste sondern vom Typ {.cls {typeof(dataset_list)}}.")

# Extrahiere Indikator-Informationen aus der Liste
indicator_info <- purrr::keep(ds_list, purrr::map(ds_list, purrr::pluck, "dataset_id") == indicator_id)

# Check ob der Indikator in der Liste besteht
if(length(indicator_info)==0) cli::cli_alert_warning("Der Indikator mit der ID {.strong {indicator_id}} ist nicht in der Datensatzliste vorhanden.")

# Beschreibung extrahieren falls ja
indicator_name <- ifelse(length(indicator_info)==1,indicator_info[[1]]$dataset_name, NA)

# Checke if ein Datensatzbeschrieb besteht
if(is.na(indicator_name)) cli::cli_alert_warning("Der Datensatzbeschrieb ist leer.")

##  Template -----------

# Template for the Script
template <- "# {{indicator_id}} - {{indicator_name}} ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('{{indicator_id}}')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

indicator_data <- ds$data

# Computation: Anzahl & Anteil -----------------------------------------------------
# Schritt 2 : hier werden Berechnungen vorgenommen

# BEISPIEL (Fahrzeuge nach Treibstoff) - dieser Block muss an den neuen Indikator angepasst werden  ---------

indicator_export_data <- indicator_computed %>%
# Berechnungen hier (Beispiel : Fahrzeuge nach Treibstoff)
  # Renaming of columns in preparation to bring data into a uniform structure
  dplyr::rename('Gebiet' = Kanton, 'Variable' = Treibstoff, 'Wert' = `Neue Inverkehrsetzungen von Strassenfahrzeugen`) %>%
  # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel' + 'Gas (mono- und bivalent)'
  dplyr::mutate(Treibstoff_Typ = dplyr::if_else(Variable %in% c('Benzin', 'Diesel', 'Gas (mono- und bivalent)'), 'fossil', 'fossil-free')) %>%
  # Calculating number of cars by year, spacial unit, and fuel type
  dplyr::group_by(Jahr, Gebiet, Treibstoff_Typ) %>%
  dplyr::summarise(Anzahl = sum(Wert)) %>%
  dplyr::ungroup() %>%
  # Adding the total number of cars by year and spacial unit and calculate the share by fuel type
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Total = sum(Anzahl),
                Anteil = (Anzahl / Total)) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = 'Einheit', values_to = 'Wert') %>%
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

# Data structure ----------------------------------------------------------
# Schritt 3 : Hier werden die Daten in die finale Form gebracht

## https://github.com/statistikZH/decarb_monitoring/tree/dev#export

indicator_export_data <- indicator_computed %>%
# BEISPIEL - dieser Block muss an den neuen Indikator angepasst werden--------
# dplyr::filter(Einheit != 'Total') %>%
# dplyr::rename('Variable' = Treibstoff_Typ) %>%
# # Renaming values
# dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == 'Zürich', 'Kanton Zürich', Gebiet),
#               Variable = dplyr::if_else(Variable == 'fossil', 'fossiler Treibstoff', 'fossilfreier Treibstoff'),
#               Einheit = dplyr::case_when(Einheit == 'Anzahl' ~ paste0(ds$dimension_label, ' [Anz.]'),
#                                          Einheit == 'Anteil' ~ paste0(ds$dimension_label, ' [%]'),
#                                          TRUE ~ Einheit)) %>%
# ----------------------
# Hinzufügen der Indikatoren-Metadaten zum Datensatz
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)

# output_file <- paste0(indicator, '_data.csv')
#
# utils::write.table(m5_export_data, paste0('./output/', output_file), fileEncoding = 'UTF-8', row.names = FALSE, sep = ',')"

# Vorlage-Skript generieren ----

# Define the parameter values
params <- list(indicator_id = indicator_id, indicator_name = indicator_name)

# Use Whisker to replace the placeholders in the template with the parameter values
filled_template <- whisker::whisker.render(template, params)

# Print the filled template
cat(filled_template, file=paste0(indicator_id, "_computations.R"))

}
