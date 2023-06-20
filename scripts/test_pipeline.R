
readxl::read_excel("2773 Monitoring.xlsx", sheet = "ParameterlisteZH") %>%
  dplyr::filter(STATUS == 1) %>%
  #dplyr::filter(stringr::str_detect(DATASET_ID, pattern = "^M\\d+(_\\d+)?$")) %>%
  dplyr::pull(DATASET_ID) %>%
  purrr::map(create_dataset) -> ds_list


ds_new_list <- purrr::map(ds_list, download_data, .progress = TRUE)

ds <- create_dataset("M1")
ds <- download_data(ds)
ds <- structure_data(ds)
export_data(ds)







ds_download_list <- purrr::map(ds_list, download_data, .progress = TRUE)
