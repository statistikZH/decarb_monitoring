#' creates a dataset object for the decarb monitoring datasets
#'
#' A dataset object needs to be created for the download, the computation
#' as well as the publishing process
#'
#' A dataset object inherits the following classes:
#' - dataset_id -> needed for the download as well as the publishing process
#' - data_format -> needed for the download process
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
  data <- readxl::read_excel("dataset_parameter_list.xlsx") %>%
    dplyr::filter(DATASET_ID == dataset_id) %>%
    dplyr::select(
      DATASET_ID,
      DATASET_NAME,
      DATA_FORMAT,
      DATA_URL,
      DATA_ID,
      DATA_FILE,
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
    class = c(data$dataset_id, data$data_format)
  )

  return(ds_list)
}