# G4 - Heizgradtage

# Import data -------------------------------------------------------------

ds <- create_dataset("G4")
ds <- download_data(ds)

g4_data <- ds$data

# Computation:  -----------------------------------------------------

# None

# Data structure ----------------------------------------------------------

g4_export_data <- g4_data %>%
  dplyr::select(4:ncol(g4_data)) %>%
  janitor::row_to_names(16) %>% View()

