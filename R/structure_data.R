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






#' method for Q1 - population data
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
structure_data.Q1 <- function(ds){

  dimension_col <- rlang::sym(ds$dimension1_col)
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

#' Helper function to retrieve population data
#'
#' @return
#' @export
#'
#' @examples
download_per_capita <- function(){

  create_dataset("Q1") %>%
    download_data() %>%
    structure_data() -> capita_df

  pop_data <- capita_df$export_data %>%
    dplyr::select(Jahr, Gebiet, "Einwohner" = Wert) %>%
    dplyr::mutate(Jahr = as.numeric(Jahr))

  return(pop_data)
}

