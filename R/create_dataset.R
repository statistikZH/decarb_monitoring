#' creates a dataset object for the decarb monitoring datasets
#'
#' A dataset object needs to be created for the download, the computation
#' as well as the publishing process
#'
#' A dataset object inherits the following classes:
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
  data <- readxl::read_excel("dataset_parameter_list.xlsx", sheet = 2) %>%
    dplyr::filter(DATASET_ID == dataset_id) %>%
    dplyr::select(
      DATASET_ID,
      DATA_ORGANIZATION,
      DATASET_NAME,
      DOWNLOAD_FORMAT,
      DATA_URL,
      DATA_ID,
      DATA_FILE,
      SHEET_NAME,
      YEAR_COL,
      YEAR_START,
      GEBIET_COL,
      GEBIET_ID,
      DIMENSION_COL,
      DIMENSION_ID,
      DIMENSION_UNIT,
      DIMENSION_LABEL,
      DATA_SOURCE,
      LAST_UPDATED,
      MODIFY_NEXT
    ) %>%
    dplyr::rename_all(tolower) %>%
    as.list()

  # create S3 dataset-object with the needed classes
  ds_list <- structure(
    data,
    data = NULL,
    class = c(data$data_organization, data$download_format, data$dataset_id)
  )

  return(ds_list)
}
