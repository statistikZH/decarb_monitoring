# G2 - Anteil erneuerbar erzeugte Wärme an Gesamtverbrauch Wärme ----------------------------------------------------

# Import data -------------------------------------------------------------

ds <- create_dataset("G2")
ds <- download_data(ds)

g2_data <- ds$data

# Computation: Anzahl & Anteil -----------------------------------------------------

g2_computed <- g2_data %>%
  dplyr::mutate(Gebiet = ds$gebiet_name)
