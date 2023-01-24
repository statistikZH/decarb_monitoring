#' Download method for download_format px which is unique to the BFS
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
download_data <- function(ds){

  # Create the download url
  # all required information, like the name of the data cube, are in the dataset (ds)
  # Example: name of the data cube ("px-x-0103010000_102") is taken from ds$data_id
  ds <- get_read_path(ds)


  ds <- read_data(ds)


  return(ds)
}





#' Method to download csv
#'
read_data <- function(ds) UseMethod("read_data")


read_data.default<- function(ds){

  ds$data <-  rio::import(
    ds$read_path,
    which = ds$which_data,
    header = TRUE
  )

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




