# M6 - Anteile ÖV und MIV im Personenverkehr ----------------------------------------------------


# Import data -------------------------------------------------------------

ds <- create_dataset("M6")
ds <- download_data(ds)

m6_data_oev <- ds$data
m6_data_miv <- ds$data_dep


# Computation - None  -----------------------------------------------------


# Data structure ----------------------------------------------------------

m6_export_data <- m6_data_oev %>%
  dplyr::bind_rows(m6_data_miv) %>%
  dplyr::filter(GEBIET_NAME == "Zürich - ganzer Kanton") %>%
  dplyr::rename("Gebiet" = GEBIET_NAME, "Variable" = INDIKATOR_NAME, "Wert" = INDIKATOR_VALUE, "Jahr" = INDIKATOR_JAHR) %>%
  dplyr::select(Jahr, Gebiet, Variable, Wert) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Variable = dplyr::if_else(Variable == "MIV-Anteil (Modal Split) [%]", "MIV", "ÖV"),
                Wert = Wert / 100,
                Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Einheit = "Prozent (%)",
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# # Daten MIV noch nicht nachgeführt, temporärer Workaround
# m6_data_miv <- m6_export_data %>%
#   dplyr:: mutate(Variable = "MIV", Wert = 1 - Wert)
#
# m6_export_data <- m6_export_data %>%
#   dplyr::bind_rows(m6_data_miv)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m6_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
