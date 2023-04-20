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
## 1. Anzahl: 'Total' - ('Heizöl' + 'Gas'+ (0.1 * 'Fernwärme'))
## 2. Anteil: 1 - ('Heizöl' + 'Gas'+ (0.1 * 'Fernwärme')) / 'Total'

## Cross check of the totals with the FSO: https://www.pxweb.bfs.admin.ch/sq/b740e708-f521-4cd5-8eb0-661e1685e6de

# Import data -------------------------------------------------------------


ds <- create_dataset("G1")
ds <- download_data(ds)

g1_data <- ds$data



# Computation: Anzahl & Anteil -----------------------------------------------------

# Renaming of columns in preparation to bring data into a uniform structure
g1_data <- g1_data %>%
  dplyr::rename("Gebiet" = Kanton, "Variable" = `Hauptenergiequelle der Heizung`, "Wert" = Gebäude)

## Splitting Fernwärme into fossil and fossil-free
## Assigning 10% of heating to means of fossil fuel
g1_fernwaerme_fossil <- g1_data %>%
  dplyr::filter(startsWith( Variable, "Fernwärme")) %>%
  dplyr::mutate(Variable = "Fernwärme fossil") %>%
  dplyr::group_by(Jahr, Gebiet, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Wert = Wert * 0.1)

# ...and 90% of heating to means of fossil-free fuel
g1_fernwaerme_fossilfree <- g1_data %>%
  dplyr::filter(startsWith( Variable, "Fernwärme")) %>%
  dplyr::mutate(Variable = "Fernwärme fossil-free") %>%
  dplyr::group_by(Jahr, Gebiet, Variable) %>%
  dplyr::summarise(Wert = sum(Wert)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Wert = Wert * 0.9)

g1_computed <- g1_data %>%
  # Fernwärme has been calculated separately, so remove it from the data
  dplyr::filter(!startsWith(Variable, "Fernwärme")) %>%
  # Add Fernwärme splits (fossil vs. fossil-free) to the data.frame
  dplyr::bind_rows(g1_fernwaerme_fossil) %>%
  dplyr::bind_rows(g1_fernwaerme_fossilfree) %>%
  # Auxiliary variable for calculating the number of buildings with fossil vs. fossil-free sources of heating. Fossil being 'Heizöl'+'Gas'+ (0.1 * 'Fernwärme')
  dplyr::mutate(Heizquelle = dplyr::if_else(Variable %in% c("Heizöl", "Gas", "Fernwärme fossil"), "fossil", "fossil-free")) %>%
  # Calculating number of buildings by year, spacial unit, and source of heating
  dplyr::group_by(Jahr, Gebiet, Heizquelle) %>%
  dplyr::summarise(Anzahl = sum(Wert)) %>%
  dplyr::ungroup() %>%
  # Adding the total number of buildings by year and spacial unit and calculate the share by source of heating
  dplyr::group_by(Jahr, Gebiet) %>%
  dplyr::mutate(Total = sum(Anzahl),
                Anteil = (Anzahl / Total)) %>%
  # Convert table to a long format
  tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = "Einheit", values_to = "Wert") %>%
  dplyr::ungroup()


# Data structure ----------------------------------------------------------

g1_export_data <- g1_computed %>%
  dplyr::filter(Einheit != "Total") %>%
  dplyr::rename("Variable" = Heizquelle) %>%
  # Renaming values
  dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                Variable = dplyr::if_else(Variable == "fossil", "Hauptquelle der Heizung, fossil", "Hauptquelle der Heizung, fossilfrei"),
                Einheit = dplyr::case_when(Einheit == "Anzahl" ~ "Gebäude [Anz.]",
                                           Einheit == "Anteil" ~ "Gebäude [%]",
                                           TRUE ~ Einheit)) %>%
  # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$dataset_name,
                Datenquelle = ds$data_source) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)


# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- g1_export_data

# Export CSV --------------------------------------------------------------

## Temporarily storing export files in Gitea repo > output folder
## Naming convention for CSV files: [indicator number]_data.csv
export_data(ds)
