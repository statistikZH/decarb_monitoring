#' Initialisiere ein neues Skript für einen neuen Indikator
#'
#' @param indicator_id ID of the indicator available in the indicator-list dataset
#'
#' @return script
#'
#'
#'
#' @export
#'
#' @examples
#' \dontrun{#' indicator_init("M3")
#'}


indicator_init <- function(indicator_id){

  #Prüfung einbauen -> Gibt es den Datensatz überhaupt in der Liste (besteht der Indikator und mit Status 1?)
dataset_info <- create_dataset(indicator_id)

## Checks -----------

# Gibt es für den Indikator bereits ein bestehendes Skript?
if(file.exists(paste0("scripts/", indicator_id,"_computations.R"))) cli::cli_abort(c("x" = "Skript für diesen Indikator besteht bereits"))

# Besteht der Indikator in der Indikatoren-Liste?
if(length(dataset_info$dataset_name)==0) cli::cli_abort(c("i"="Der Indikator mit der ID {.strong {indicator_id}} ist nicht in der Datensatzliste vorhanden."))

# Extrahiere die Beschreibung, falls eine vorhanden ist
indicator_name <- ifelse(length(dataset_info$dataset_name)==1,dataset_info$dataset_name,"")

# Prüfe ob eine Beschreibung hinterlegt ist
if(is.na(indicator_name)) cli::cli_alert_warning("Der Datensatzbeschrieb ist leer.")

##  Template -----------

# Template for the Script
template <- "# {{indicator_id}} - {{indicator_name}} ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('{{indicator_id}}')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

{{indicator_id}}_data <- ds$data

# Berechnungen -----------------------------------------------------

# Schritt 2 : Falls die zu publizierenden Werte noch berechnet werden müssen, können hier Aggregierungs- und Transformationsschritte vorgenommen werden.

# Beispiele :
# - neue Kategorien oder Totale bilden
# - Anteile berechnen
# - Umbenennung von Kategorien

# Beispiel : Fahrzeuge nach Treibstoff - dieser Block dient nur der Veranschaulichung ---------

{{indicator_id}}_computed <- {{indicator_id}}_data %>%
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

# Harmonisierung Datenstruktur / Bezeichnungen  ----------------------------------------------------------

# Schritt 3 : Hier werden die Daten in die finale Form gebracht

# - Angleichung der Spaltennamen / Kategorien und Einheitslabels an die Konvention
# - Anreicherung mit Metadaten aus der Datensatzliste

{{indicator_id}}_export_data <- {{indicator_id}}_computed %>%
# Beispiel - dieser Block dient nur der Veranschalichung und muss je nach Fall angepasst werden --------
# dplyr::filter(Einheit != 'Total') %>%
# dplyr::rename('Variable' = Treibstoff_Typ) %>%
# # Renaming values
# dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == 'Zürich', 'Kanton Zürich', Gebiet),
#               Variable = dplyr::if_else(Variable == 'fossil', 'fossiler Treibstoff', 'fossilfreier Treibstoff'),
#               Einheit = dplyr::case_when(Einheit == 'Anzahl' ~ paste0(ds$dimension_label, ' [Anz.]'),
#                                          Einheit == 'Anteil' ~ paste0(ds$dimension_label, ' [%]'),
#                                          TRUE ~ Einheit)) %>%
# ----------------------
# Anreicherung  mit Metadaten
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- {{indicator_id}}_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)"

# Vorlage-Skript generieren ----

# Define the parameter values
params <- list(indicator_id = indicator_id, indicator_name = indicator_name)

# Use Whisker to replace the placeholders in the template with the parameter values
filled_template <- whisker::whisker.render(template, params)

# Print the filled template
cat(filled_template, file=paste0("scripts/",indicator_id, "_computations.R"))

}
