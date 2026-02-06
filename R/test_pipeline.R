#' Utility function to test if the pipeline works for all IDs
#'
#' @return list object with all datasets and the data
#' @export
#'
#'
test_pipeline <- function(){
  readxl::read_excel("2773 Monitoring.xlsx", sheet = "ParameterlisteZH") %>%
    dplyr::filter(STATUS == 1) %>%
    dplyr::pull(DATASET_ID) %>%
    purrr::map(create_dataset) -> ds_list

  cli::cli_alert_success("All datasets could be created.")

  ds_new_list <- purrr::map(ds_list, download_data, .progress = TRUE)

  cli::cli_alert_success("All datasets could be downloaded.")

  return(ds_new_list)
}
