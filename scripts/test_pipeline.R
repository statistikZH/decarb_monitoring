ids <- c("A1", "G1", "Q1", "M1", "M8", "KG(a)")


ds_list <- purrr::map(ids, create_dataset)

ds_new_list <- purrr::map(ds_list, download_data)
