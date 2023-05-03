#' Title
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
