#' Title
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
export_data <- function(ds){
  dir.create("output", showWarnings = FALSE)

  output_file <- paste0(ds$dataset_id, "_data.csv")

  utils::write.table(ds$export_data, paste0("./output/", output_file), fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
}
