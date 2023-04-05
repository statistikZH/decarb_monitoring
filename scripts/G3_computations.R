# G3 - Energiebedarf für Raumwärme und Warmwasser bei reinen Wohnbauten im Kanton Zürich nach Gebäudealtersklassen ----------------------------------------------------

# Import data -------------------------------------------------------------

ds <- create_dataset("G3")
ds <- download_data(ds)

g3_data <- ds$data

# Computation:  -----------------------------------------------------

