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
download_data.default <- function(ds){

  # Create the download url
  # all required information, like the name of the data cube, are in the dataset (ds)
  # Example: name of the data cube ("px-x-0103010000_102") is taken from ds$data_id
  ds <- get_download_url(ds)

  # we do this to harmonize the read methods
  # since in the zip-method we do not stream the data but
  # use the download url for the zip download and then
  # the read_path is then the path to the unzipped file.
  # in order to use the same parameter name for all read methods
  # we assign here as well the read_path (which is here the exact same
  # as the download_url)
  ds$read_path <- ds$download_url

  ds <- read_data(ds)


  return(ds)
}




#' Function to download zipped data files (csv)
#'
#'
#' @param ds dataset object
#'
#' @export
download_data.zip <- function(ds) {

  # Create download_url
  ds <- get_download_url(ds)

  file_ext <- tools::file_ext(ds$data_file)

  class(ds) <- file_ext

  # Create a temp. file name
  temp_zip <- tempfile(fileext = ".zip")
 # temp_file <- tempfile(fileext = paste0(".", file_ext))

  # Fetch the zip file into the temp. file
  utils::download.file(ds$download_url, temp_zip)

  ds$read_path <- utils::unzip(temp_zip, ds$data_file)

  # Use unzip() to extract the target file from temp. file and convert to data.frame
  ds <- read_data(ds)

  # Remove the temp file
  unlink(temp_zip)
  unlink(ds$read_path)

  return(ds)

}

#' Method to download csv
#'
read_data <- function(ds) UseMethod("read_data")


read_data.csv <- function(ds){

  ds$data <-  data.table::fread(ds$read_path, header= TRUE ) %>%
    as.data.frame(.)

  return(ds)

}


read_data.px <- function(ds){
  # Create the query list using "get_px_query_list()"
  query_list <- get_px_query_list(ds)

  # Stream the BFS data for a specific data cube and with the defined parameters
  data <- pxweb::pxweb_get(url = ds$read_path,
                           query = query_list)

  # Convert to data.frame
  ds$data <- as.data.frame(
    data,
    column.name.type = "text",
    variable.value.type = "text"
  )

  return(ds)
}


read_data.xslx <- function(ds){

  ds$data <- readxl::read_excel(
    ds$read_path,
    sheet = ds$sheet_name
  )

  return(ds)
}

