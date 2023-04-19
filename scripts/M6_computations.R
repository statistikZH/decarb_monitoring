# M6 - Anteile ÖV und MIV im Personenverkehr ----------------------------------------------------


# Import data -------------------------------------------------------------

ds <- create_dataset("M6")
ds <- download_data(ds)

m6_data <- ds$data

# Computation - None  -----------------------------------------------------


# Data structure ----------------------------------------------------------

m6_export_data <- m6_data %>%
  dplyr::filter(GEBIET_NAME == "Zürich - ganzer Kanton") %>%
  dplyr::rename("Gebiet" = GEBIET_NAME, "Variable" = INDIKATOR_NAME, "Wert" = INDIKATOR_VALUE, "Jahr" = INDIKATOR_JAHR) %>%
  dplyr::select(Jahr, Gebiet, Variable, Wert) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Variable = "ÖV-Anteil (Modal Split)",
                Wert = Wert / 100,
                Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Einheit = "Verkehrsmittelwahl [%]",
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m6_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
