#' Method dispatch for the data download
#'
#' @param ds dataset object to be processed
#'
#' @family Download
#'
#' @export
download_data <- function(ds) UseMethod("download_data")

#' Download method for data_format px which is unique to the BFS
#' Downloads the data from a data cube based on a query list and converts it to a data.frame
#'
#' We are using the PXWEB package to stream BFS data: https://ropengov.github.io/pxweb/articles/pxweb.html
#'
#' !!! Important Limits: 10 calls per 10 sec., 5000  values per call
#'
#' the name of the data cube, e.g. "px-x-0103010000_102", is taken from ds$data_id
#' the download url is constructed with the "get_download_url.default" method
#' the query list, a list element containing all query parameters, gets constructed with "get_px_query_list()"
#'
#' To set up a PXWEB query list manually, start with a specific path and walk thorough each step
#' d <- pxweb::pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")
#'
#' @inheritParams download_data
#'
#' @export
download_data.px <- function(ds){

  # Create the download url
  # all required information, like the name of the data cube, are in the dataset (ds)
  # Example: name of the data cube ("px-x-0103010000_102") is taken from ds$data_id
  ds <- get_download_url(ds)

  # Create the query list using "get_px_query_list()"
  query_list <- get_px_query_list(ds)

  # Stream the BFS data for a specific data cube and with the defined parameters
  data <- pxweb::pxweb_get(url = ds$download_url,
                              query = query_list)

  # Convert to data.frame
  ds$px_data <- as.data.frame(data, column.name.type = "text", variable.value.type = "text")

  return(ds)
}

#' Function to download data_format csv
#'
#'
#' @param ds dataset object
#'
#' @export
download_data.csv <- function(ds) {

  ds <- download_data_csv(ds)

}

#' Method to download csv
#'
download_data_csv <- function(ds) UseMethod("download_data_csv")
#' Method specific to download csv form data_organization openzh
#' openzh refers to the Datenkatalog Kanton Zürich (https://www.zh.ch/daten)
#'
#' @param ds dataset object
#'
#' @export
download_data_csv.openzh <- function(ds) {

  # Create download_url
  ds <- get_download_url.default(ds)

  ds$csv_data <- data.table::fread(ds$download_url)

  return(ds)
}

#' Function to download zipped data files (csv)
#'
#'
#' @param ds dataset object
#'
#' @export
download_data.zip_csv <- function(ds) {

  ds <- download_data_zip_csv(ds)

}

  #' Method to download zipped csv
  #'
  download_data_zip_csv <- function(ds) UseMethod("download_data_zip_csv")
  #' Method specific to download zipped csv form data_organization swisstopo
  #' The target file is the file to get from the zip folder
  #'
  #' @param ds dataset object
  #'
  #' @export
  download_data_zip_csv.swisstopo <- function(ds) {

    # Create download_url
    ds <- get_download_url.zip_csv(ds)

    # Set target file
    target_file <- ds$data_file

    # Create a temp. file name
    temp <- tempfile()

    # Fetch the zip file into the temp. file
    utils::download.file(ds$download_url, temp)


    # Use unzip() to extract the target file from temp. file and convert to data.frame
    ds$zip_csv_data_frame <- data.table::fread(utils::unzip(temp, target_file), header= TRUE ) %>%
      as.data.frame(.)

    # Remove the temp file
    unlink(temp)

    return(ds)

  }

#' Function to download data_format xlsx
#'
#'
#' @param ds dataset object
#'
#' @export
download_data.xlsx <- function(ds) {

  ds <- download_data_xlsx(ds)

}

#' Method to download data_format xlsx
#'
download_data_xlsx <- function(ds) UseMethod("download_data_xlsx")
#' Method specific to download xlsx form data_organization BFS
#'
#' @param ds dataset object
#'
#' @export
download_data_xlsx.bfs <- function(ds) {

  # Create download_url
  ds <- get_download_url_xlsx(ds)

  ds$xlsx_data <- data.table::fread(ds$download_url)

  return(ds)
}
