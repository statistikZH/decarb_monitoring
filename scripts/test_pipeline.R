ids <- c("A1", "G1", "Q1", "M1", "M8", "KG_a", "G3", "M2", "M3", "M4", "M5", "IG1", "LF2")

ds_list <- purrr::map(ids, create_dataset)

ds_new_list <- purrr::map(ds_list, download_data, .progress = TRUE)

ds <- create_dataset("LF2")
ds <- download_data(ds)
ds <- structure_data(ds)
export_data(ds)





