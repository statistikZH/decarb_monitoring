# M5 - Durchschnittliche CO₂-Emissionen der Personenwagen ----------------------------------------------------


# Import data -------------------------------------------------------------

ds <- create_dataset("M5")
ds <- download_data(ds)

# in this case two datasets are necessary (ZH data straight from the ressource and CH data is computed)
m5_data_zh <- ds$data
m5_data_ch <- ds$data_dep

# Computation of weighted mean (CH mean CO2) -----------------------------------------------------



# First, we reshape both datasets to have the same long format
co2_long <- ds$data %>%
  tidyr::pivot_longer(cols = -date, names_to = "Canton", values_to = "Mean_CO2") %>%
  dplyr::mutate(date = dplyr::case_when( #temporary fix as the original data has an error!
    date == 20201101 ~ 20210101, # replace 11th January 2020 with 1st January 2021
    TRUE ~ as.numeric(date)))

car_long <- ds$data_dep %>%
  tidyr::pivot_longer(cols = -date, names_to = "Canton", values_to = "Num_Cars")

# Then, we join both datasets on 'date' and 'Canton'
combined_data <- co2_long %>%
  dplyr::inner_join(car_long, by = c("date", "Canton")) %>%
  dplyr::rename("Jahr" = date) %>%
  dplyr::mutate(Jahr = lubridate::ymd(Jahr))


# Calculate the total number of cars per year in the country
total_cars <- combined_data %>%
  dplyr::group_by(Jahr) %>%
  dplyr::summarize(Total_Cars = sum(Num_Cars))

# Calculate the proportion of cars for each canton relative to the total number of cars in the country
combined_data <- combined_data %>%
  dplyr::left_join(total_cars, by = "Jahr") %>%
  dplyr::mutate(Car_Proportion = Num_Cars / Total_Cars)

# Calculate the weighted mean CO2 value for each canton
combined_data <- combined_data %>%
  dplyr::mutate(Weighted_CO2 = Mean_CO2 * Car_Proportion)

# Calculate the overall mean CO2 value for the country per year
overall_mean_CO2 <- combined_data %>%
  dplyr::group_by(Jahr) %>%
  dplyr::summarize(Country_Mean_CO2 = sum(Weighted_CO2)) %>%
  dplyr::rename("Wert" = Country_Mean_CO2) %>%
  dplyr::mutate(Gebiet = "Schweiz")

# Data structure ----------------------------------------------------------

m5_export_data <- m5_data_zh %>%
  dplyr::select(date, ZH) %>%
  dplyr::rename("Jahr" = date, "Wert" = ZH) %>%
  dplyr::mutate(Gebiet = "Kanton Zürich") %>%
  dplyr::mutate(Jahr = dplyr::case_when( #temporary fix as the original data has an error!
    Jahr == 20201101 ~ 20210101, # replace 11th January 2020 with 1st January 2021
    TRUE ~ as.numeric(Jahr)
  )) %>%
  dplyr::mutate(Jahr = lubridate::ymd(Jahr)) %>%
  dplyr::bind_rows(overall_mean_CO2) %>%
  dplyr::mutate(Variable = ds$dimension_label,
                Indikator_ID = ds$dataset_id,
                Einheit = ds$dimension_unit,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::mutate(Jahr = lubridate::year(Jahr)) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- m5_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
