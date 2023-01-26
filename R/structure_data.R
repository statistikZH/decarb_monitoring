#' structure data generic
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
structure_data <- function(ds) {
  UseMethod("structure_data")
}



#' method for G1
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
structure_data.G1 <- function(ds){

  dimension_col <- rlang::sym(ds$dimension_col)
  dimension_unit <- rlang::sym(ds$dimension_unit)
  gebiet_col <- rlang::sym(ds$gebiet_col)

  ds$data <- dplyr::rename(
    ds$data,
    "Gebiet" = !!gebiet_col,
    "Variable" = !!dimension_col,
    "Wert" = !!dimension_unit
  )


  ds$data %>%
    dplyr::filter(startsWith(Variable, "Fernwärme")) %>%
    dplyr::mutate(Variable = "Fernwärme fossil") %>%
    dplyr::group_by(Jahr, Gebiet, Variable) %>%
    dplyr::summarise(Wert = sum(Wert)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(Wert = Wert * 0.1) -> g1_fernwaerme_fossil

  ds$data %>%
    dplyr::filter(startsWith(Variable, "Fernwärme")) %>%
    dplyr::mutate(Variable = "Fernwärme fossil-free") %>%
    dplyr::group_by(Jahr, Gebiet, Variable) %>%
    dplyr::summarise(Wert = sum(Wert)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(Wert = Wert * 0.9) -> g1_fernwaerme_fossilfree


  ds$data %>%
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
    dplyr::ungroup() -> ds$computed_data


  ds$computed_data %>%
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
    dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle) -> ds$export_data

  return(ds)
}



#' method for Q1
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
structure_data.Q1 <- function(ds){

  dimension_col <- rlang::sym(ds$dimension_col)
  dimension_unit <- rlang::sym(ds$dimension_unit)
  gebiet_col <- rlang::sym(ds$gebiet_col)


  ds$data <- dplyr::rename(
    ds$data,
    "Gebiet" = !!gebiet_col,
    "Variable" = !!dimension_col,
    "Wert" = !!dimension_unit
  )

  # no computation taking place

  ds$data %>%
    # Renaming values
    dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                  Einheit = "Personen [Anz.]") %>%
    # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
    dplyr::mutate(Indikator_ID = ds$dataset_id,
                  Indikator_Name = ds$dataset_name,
                  Datenquelle = ds$data_source) %>%
    dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle) -> ds$export_data


  return(ds)
}


#' Title
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
structure_data.M1 <- function(ds){

  dimension_col <- rlang::sym(ds$dimension_col)
  dimension_unit <- rlang::sym(ds$dimension_unit)
  gebiet_col <- rlang::sym(ds$gebiet_col)


  ds$data <- dplyr::rename(
    ds$data,
    "Gebiet" = !!gebiet_col,
    "Variable" = !!dimension_col,
    "Wert" = !!dimension_unit
  )

  # computations

  ds$data %>%
    # Auxiliary variable for calculating the number of fossil vs. fossil-free passenger cars. Fossil being 'Benzin' + 'Diesel'
    dplyr::mutate(Treibstoff_Typ = dplyr::if_else(Variable %in% c("Benzin", "Diesel"), "fossil", "fossil-free")) %>%
    # Calculating number of cars by year, spacial unit, and fuel type
    dplyr::group_by(Jahr, Gebiet, Treibstoff_Typ) %>%
    dplyr::summarise(Anzahl = sum(Wert)) %>%
    dplyr::ungroup() %>%
    # Adding the total number of cars by year and spacial unit and calculate the share by fuel type
    dplyr::group_by(Jahr, Gebiet) %>%
    dplyr::mutate(Total = sum(Anzahl),
                  Anteil = (Anzahl / Total)) %>%
    # Convert table to a long format
    tidyr::pivot_longer(cols = c(Anzahl, Total, Anteil), names_to = "Einheit", values_to = "Wert") %>%
    dplyr::ungroup() -> ds$computed_data

  # structure

  ds$computed_data %>%
    dplyr::filter(Einheit != "Total") %>%
    dplyr::rename("Variable" = Treibstoff_Typ) %>%
    # Renaming values
    dplyr::mutate(Gebiet = dplyr::if_else(Gebiet == "Zürich", "Kanton Zürich", Gebiet),
                  Variable = dplyr::if_else(Variable == "fossil", "fossiler Treibstoff", "fossilfreier Treibstoff"),
                  Einheit = dplyr::case_when(Einheit == "Anzahl" ~ "Personenwagen [Anz.]",
                                             Einheit == "Anteil" ~ "Personenwagen [%]",
                                             TRUE ~ Einheit)) %>%
    # Manually adding columns for Indikator_ID, Indikator_Name, Einheit and Datenquelle
    dplyr::mutate(Indikator_ID = ds$dataset_id,
                  Indikator_Name = ds$dataset_name,
                  Datenquelle = ds$data_source) %>%
    dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle) -> ds$export_data



  return(ds)
}

#' Title
#'
#' @return
#' @export
#'
#' @examples
structure_data.A1 <- function(){
  # code me!
}

#TODO: missing indicators, think about KG(a) --> second ds in download/import or in structure?
#TODO: A1 + M8 having pop data stored for restructuring --> new class for download/structure?
