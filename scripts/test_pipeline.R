ids <- c("A1", "G1", "Q1", "M1", "M8", "KG(a)")


ds_list <- purrr::map(ids, create_dataset)

ds_new_list <- purrr::map(ds_list, download_data, .progress = TRUE)

new_ds <- create_dataset("Q1")
new_ds <- download_data(new_ds)
new_ds <- structure_data(new_ds)
export_data(new_ds)





