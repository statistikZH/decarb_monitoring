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
#' ds
#'
#' indicator_init("M3", ds)

indicator_init <- function(indicator_id, indicator_dataset){

# Check if a script for the Indicator exists already and abort if this is the case
if(file.exists(paste0("scripts/", indicator_id,"_computations.R"))) cli::cli_abort( "x" = "You've supplied a {.cls {class(n)}} vector.")

  ?cli_abort


# Template for the Script
template <- "# {{indicator_id}} - {{indicator_description}} ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset( {{indicator_id}} )
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung


m5_data <- ds$data

# Computation: Anzahl & Anteil -----------------------------------------------------
# Schritt 2 : hier können die Berechnungen

# Es

m5_export_data <- m5_computed %>%
# Berechnungen hier
tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = 'Einheit', values_to = 'Wert') %>%
  dplyr::ungroup()

# Übergang zu Computations -> Welche Voraussetzungen müssen erfüllt sein?

# Data structure ----------------------------------------------------------

## https://github.com/statistikZH/decarb_monitoring/tree/dev#export

m5_export_data <- m5_computed %>%
 # Umformatierungen hier
# Angaben die aus dem ds Objekt kommen wieder anfügen (Variablenname / Datenquelle etc.) -> Code einfügen
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
dir.create('output', showWarnings = FALSE)

-> export_data funktion einfügen

output_file <- paste0(indicator, '_data.csv')

utils::write.table(m5_export_data, paste0('./output/', output_file), fileEncoding = 'UTF-8', row.names = FALSE, sep = ',')"

# Define the parameter values
params <- list(indicator = "M3", title = "Ein toller Indikatorentitel")

# Use Whisker to replace the placeholders in the template with the parameter values
filled_template <- whisker::whisker.render(template, params)

# Print the filled template
cat(filled_template, file=paste0(indicator, "_computations.R"))

}
