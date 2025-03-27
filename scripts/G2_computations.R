# G2 - Anteil erneuerbar erzeugte Wärme an Gesamtverbrauch Wärme ----------------------------------------------------

# Import data -------------------------------------------------------------

ds <- create_dataset("G2")
ds <- download_data(ds)

g2_data <- ds$data
g2_data_eb <- ds$dep$EV1

# Filtering and joining -----------------------------------------------------
g2_data_eb_sub <- g2_data_eb |>
  dplyr::filter(Energiesektor == "Waerme") |>
  dplyr::group_by(Jahr,Energiesektor) |>
  dplyr::summarise(Wert = sum(Wert)) |>
  dplyr::mutate(Waerme = "erneuerbar", Einheit = "MWh") |>
  dplyr::select(Jahr, Waerme, Wert, Einheit)

g2_data_sub <- g2_data |>
  dplyr::filter(Energiesektor == "Waerme") |>
  dplyr::mutate(Waerme = "total", Wert = Wert * 1000, Einheit = "MWh") |>
  dplyr::select(Jahr, Waerme, Wert, Einheit)

g2_data_joined <- dplyr::bind_rows(g2_data_sub,g2_data_eb_sub)


# Computation: Anzahl & Anteil -----------------------------------------------------

g2_computed <- g2_data_joined  |>
  dplyr::mutate(Gebiet = ds$gebiet_name) |>
  tidyr::pivot_wider(names_from = Waerme, values_from = Wert) |>
  dplyr::mutate(nicht_erneuerbar = total - erneuerbar,
                anteil_erneuerbar = erneuerbar / total,
                anteil_nicht_erneuerbar = (total - erneuerbar) / total) |>
  tidyr::pivot_longer(cols = c(total, erneuerbar, nicht_erneuerbar, anteil_erneuerbar, anteil_nicht_erneuerbar), values_to = "Wert")


# Data structure ----------------------------------------------------------
g2_export_data <- g2_computed |>
    dplyr::filter(name != "total") |>
    dplyr::rename("Variable" = name) |>
    # Renaming values
  dplyr::mutate(Gebiet = "Kanton Zürich",
                Einheit = dplyr::case_when(
                  Variable %in% c("erneuerbar", "nicht_erneuerbar") ~ ds$dimension_label,
                  TRUE ~ "Prozent (%)"
                )) |>
  dplyr::mutate(Variable = dplyr::if_else(Variable %in% c("erneuerbar", "anteil_erneuerbar"), "Erneuerbar", "Nicht-erneuerbar")) |>
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
    dplyr::mutate(Indikator_ID = ds$dataset_id,
                  Indikator_Name = ds$indicator_name,
                  Datenquelle = ds$data_source) |>
    dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- g2_export_data


# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
