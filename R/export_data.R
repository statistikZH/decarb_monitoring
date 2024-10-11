#' Title
#'
#' @param ds
#'
#' @return
#' @export
#'
#' @examples
export_data <- function(ds, interactive = TRUE){

  # expected_variables <- c("Jahr", "Gebiet", "Indikator_ID", "Indikator_Name", "Variable", "Wert", "Einheit", "Datenquelle")
  # conditionally define expected_variables -> M2/M4 with additional attribute "gruppe"
  expected_variables <- if (any(ds$dataset_id %in% c("M2", "M4", "KV4"))) {
    c("Jahr", "Gebiet", "Indikator_ID", "Indikator_Name", "Gruppe", "Variable", "Wert", "Einheit", "Datenquelle")
  } else {
    c("Jahr", "Gebiet", "Indikator_ID", "Indikator_Name", "Variable", "Wert", "Einheit", "Datenquelle")
  }

  #check if export data contains all necessary variables
  if(!setequal(expected_variables, colnames(ds$export_data)))
  {
    unmatched_var <- setdiff(colnames(ds$export_data), expected_variables)
    cli::cli_abort(c("Export dataset contains variables which are different from the expected ones.",
                   "i" = "Unmatched variable: {unmatched_var}"))
  }

  dir.create("output", showWarnings = FALSE)

  output_file <- paste0(ds$dataset_id, "_data.csv")

  output_path <- paste0("./output/", output_file)

  # Check if the file already exists
  if (fs::file_exists(output_path)) {
    if (interactive) {
      # Display a styled warning message with an emoji
      cli::cli_alert_warning("The file already exists. Are you sure you want to overwrite it?")

      # Prompt the user for input with styled text
      user_input <- readline(prompt = cli::cli_text("{.white Type 'yes' or 'no': }"))

      if (tolower(user_input) == "yes") {
        utils::write.table(ds$export_data, output_path, fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
        message("File has been overwritten.")
      } else {
        message("File has not been overwritten.")
      }
    } else {
      utils::write.table(ds$export_data, output_path, fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
      message("Interactive mode disabled. File has been overwritten.")
    }
  } else {
    utils::write.table(ds$export_data, output_path, fileEncoding = "UTF-8", row.names = FALSE, sep = ",")
  }
}
