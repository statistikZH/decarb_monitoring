# G1 - Anteil fossilfreier Wärmeerzeuger in Wohn- und Nichtwohngebäuden ----------------------------------------------------
## Indicator: "Fossilfreie Wärmeerzeuger in Gebäuden"
## Variable: "Hauptquelle der Heizung"
## Spatial unit: Schweiz and Kanton Zürich
## Temporal unit: starting 2021
## Data url: https://www.bfs.admin.ch/asset/de/px-x-0902010000_102
## Data sources: "Gebäude- und Wohnungsstatistik GWS, BFS"

## Additional remarks:
## Groupings: 1: Heizöl; 2: Gas; 3: Elektrizität; 4: Holz: [Holz (generisch),Holz (Pellets),Holz (Schnitzel),Holz (Stückholz)];
## 5: Sonne: [Sonne (thermisch)]; 6: Wärmepumpe: [Wärmepumpe (Wasser),Wärmepumpe (Luft),Wärmepumpe (Gas),Wärmepumpe (Fernwärme),Wärmepumpe (Erdwärme),Wärmepumpe (Erdwärmesonde),Wärmepumpe (Erdregister),Wärmepumpe (andere Quelle),Wärmepumpe (unbestimmte Quelle)];
## 7: Fernwärme: [Fernwärme (generisch),Fernwärme (Hochtemperatur),Fernwärme (Niedertemperatur)]; 8: Andere: [Abwärme (innerhalb des Gebäudes), Andere, Keine, Unbestimmt]
## Annahme: 10% der Fernwärme mittels fossilem Energieträger für QS mit den kantonalen Daten vergleichen, die beim Stat. Amt vorliegen.
## Für Differenzierung auch Parameter 'Gebäudekategorie' mitberücksichtigen.

## Computations:
## 1. Anzahl: Hauptenergiequelle der Heizung[alle]
## 2. Anteil: 1 - ('Heizöl' + 'Gas'+ (0.1 * 'Fernwärme')) / 'Total'

## Cross check of the totals with the FSO: https://www.pxweb.bfs.admin.ch/sq/b740e708-f521-4cd5-8eb0-661e1685e6de

# Import data -------------------------------------------------------------

ds <- create_dataset("G1")
ds <- download_data(ds)

g1_data <- ds$data

url <- "https://disseminate.stats.swiss/rest/data/CH1.GWS,DF_GWS_REG4,1.0.0/A._T._T.._T.8100+ZH?startPeriod=2021&dimensionAtObservation=AllDimensions&format=csvfile"
g1_sdmx <- read.delim(url, header = TRUE, sep = ",")

g1_sdmx_mod <- g1_sdmx |>
  dplyr::filter(GWAERZH != "_T") |>
  dplyr::select(GWAERZH,KANTONSNUMMER,Jahr = TIME_PERIOD,Wert = OBS_VALUE) |>
  dplyr::mutate(Gebiet = dplyr::case_when(KANTONSNUMMER == "ZH" ~ "Zürich",
                                          KANTONSNUMMER == "8100" ~ "Schweiz",
                                          TRUE ~ KANTONSNUMMER)
                ) |>
  dplyr::mutate(Variable = dplyr::case_when(GWAERZH == "_T" ~ "Total",
                                      GWAERZH == "1" ~ "Wärmepumpe",
                                      GWAERZH == "2" ~ "Gas",
                                      GWAERZH == "3" ~ "Heizöl",
                                      GWAERZH == "4" ~ "Holz",
                                      GWAERZH == "5" ~ "Elektrizität",
                                      GWAERZH == "6" ~ "Fernwärme",
                                      GWAERZH == "7" ~ "Sonne",
                                      GWAERZH %in% c("8","9") ~ "Andere",
                                      TRUE ~ GWAERZH)
                ) |>
  dplyr::select(Gebiet,Jahr,Variable,Wert) |>
  dplyr::group_by(Gebiet, Jahr, Variable) |>
  dplyr::summarise(Wert = sum(Wert))

g1_cleaned <- g1_sdmx_mod

# Computation: Anzahl & Anteil -----------------------------------------------------

# Initial data restructuring and renaming before we do the actual computations
# g1_cleaned <- g1_data %>%
#   # Renaming of columns in preparation to bring data into a uniform structure
#   dplyr::rename("Gebiet" = Kanton, "Variable" = `Hauptenergiequelle der Heizung`, "Wert" = Gebäude) %>%
#   # Doing the new grouping of the Variable
#   dplyr::mutate(Variable = dplyr::case_when(Variable %in% c("Holz (generisch)","Holz (Pellets)","Holz (Schnitzel)","Holz (Stückholz)") ~ "Holz",
#                                             Variable == "Sonne (thermisch)" ~ "Sonne",
#                                             Variable %in% c("Wärmepumpe (Wasser)","Wärmepumpe (Luft)","Wärmepumpe (Gas)","Wärmepumpe (Fernwärme)","Wärmepumpe (Erdwärme)","Wärmepumpe (Erdwärmesonde)",
#                                                             "Wärmepumpe (Erdregister)","Wärmepumpe (andere Quelle)","Wärmepumpe (unbestimmte Quelle)") ~ "Wärmepumpe",
#                                             Variable %in% c("Fernwärme (generisch)","Fernwärme (Hochtemperatur)","Fernwärme (Niedertemperatur)") ~"Fernwärme",
#                                             Variable %in% c("Abwärme (innerhalb des Gebäudes)", "Andere", "Keine", "Unbestimmt") ~"Andere",
#                                             TRUE ~ Variable
#                                             )) %>%
#   # Now sum up by the new groups
#   dplyr::group_by(Gebiet, Jahr, Variable) %>%
#   dplyr::summarise(Wert = sum(Wert))

# Auxiliary variable for calculating the number of buildings with fossil vs. fossil-free sources of heating. Fossil being 'Heizöl'+'Gas'+ (0.1 * 'Fernwärme')
g1_fossil <- g1_cleaned %>%
  dplyr::filter(Variable %in% c("Fernwärme", "Heizöl", "Gas")) %>%
  # Only 10% of Fernwärme are attributed to come from fossil sources
  dplyr::mutate(Wert = dplyr::if_else(Variable == "Fernwärme", Wert * 0.1, Wert)) %>%
  dplyr::mutate(Variable = "Fossil") %>%
  # Calculating number of buildings by year, spacial unit, and source of heating
  dplyr::group_by(Gebiet, Jahr, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup()

# Auxiliary variable to computate the Total (Hauptenergiequelle der Heizung[alle])
g1_total <- g1_cleaned %>%
  dplyr::group_by(Gebiet, Jahr) %>%
  dplyr::summarise(Total = sum(Wert))

g1_computed <- g1_cleaned %>%
  dplyr::bind_rows(g1_fossil) %>%
  dplyr::left_join(g1_total, by = c("Gebiet", "Jahr")) %>%
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Anteil = (Wert / Total)) %>%
  # We no longer need the Total column, so we drop it
  dplyr::select(-Total) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Wert, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()

# Data structure ----------------------------------------------------------

g1_export_data <- g1_computed %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Einheit = dplyr::case_when(Einheit == "Wert" ~ ds$dimension_unit,
                                           Einheit == "Anteil" ~ "Prozent (%)",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)


# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- g1_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
