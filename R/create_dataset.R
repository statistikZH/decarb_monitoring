#' creates a dataset object for the decarb monitoring datasets
#'
#' A dataset object needs to be created for the download, the computation
#' as well as the publishing process
#'
#' A dataset object inherits the following classes:
#' - data_organization -> needed for the download process
#' - dataset_id -> needed for the download as well as the publishing process
#' - download_format -> needed for the download process
#'
#' @param dataset_id id of the dataset
#'
#'
#' @return list containing dataset-objects
#'
#' @family Datensatz erstellen
#'
#' @export
create_dataset <- function(dataset_id) {

  # get all the metadata information for a specific dataset
  data <- readxl::read_excel("2773 Monitoring.xlsx", sheet = "ParameterlisteZH") %>%
    dplyr::filter(DATASET_ID == dataset_id, STATUS == 1) %>%
    dplyr::select(
      DATASET_ID,
      DATA_ORGANIZATION,
      DATASET_NAME,
      INDICATOR_NAME,
      DOWNLOAD_FORMAT,
      DATA_URL,
      DATA_ID,
      WHICH_DATA,
      YEAR_COL,
      YEAR_START,
      GEBIET_COL,
      GEBIET_ID,
      GEBIET_NAME,
      DIMENSION1_COL,
      DIMENSION1_ID,
      DIMENSION1_NAME,
      DIMENSION2_COL,
      DIMENSION2_ID,
      DIMENSION2_NAME,
      DIMENSION_UNIT,
      DIMENSION_LABEL,
      DATA_SOURCE,
      LAST_UPDATED,
      MODIFY_NEXT,
      DEPENDENCY
    ) %>%
    dplyr::rename_all(tolower) %>%
    as.list()

  # create S3 dataset-object with the needed classes
  ds_list <- structure(
    data,
    data = NULL,
    class = c(data$data_organization, data$download_format, data$dataset_id)
  )

  known_extensions <- c("csv", "psv", "tsv", "csvy", "sas7bdat", "sav", "zsav",
                        "dta", "xpt", "por", "xls", "xlsx", "R", "RData", "rda",
                        "rds", "rec", "mtp", "syd", "dbf", "arff", "dif", "fwf",
                        "csvgz", "parquet", "wf1", "feather", "fst", "json",
                        "mat", "ods", "html", "xml", "yml", "zip", "px")

  if(!(ds_list$download_format %in% known_extensions)){
    cli::cli_abort("Download Format aus Excel ist nicht bekannt. Auf Tippfehler überprüfen.")
  }

  return(ds_list)
}
