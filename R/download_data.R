#' Function for streaming the data.
#'
#' First runs the get_read_path() function, which creates the path for the download URL.
#' Then uses the read_data() function to stream the data and
#' append it to the dataset (ds) in the $data object.
#'
#' @inheritParams download_data
#'
#' @export
download_data <- function(ds){

  # creates the path for the download URL
  ds <- get_read_path(ds)

  # streams the data and appends it to the ds in $data
  ds <- read_data(ds)

  return(ds)
}

#' Default method to stream data
#'
#' The method is used for all cases where the input data comes as csv, xlsx or
#' in combination with a zipped folder
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

#' Method to stream data from pxweb data cubes which is unique to the BFS
#' Downloads the data from a data cube based on a query list and converts it to a data.frame
#'
#' We are using the PXWEB package to stream BFS data: https://ropengov.github.io/pxweb/articles/pxweb.html
#'
#' !!! Important Limits: 10 calls per 10 sec., 5000  values per call
#'
#' the name of the data cube, e.g. "px-x-0103010000_102", is taken from ds$data_id
#' the download url is constructed with the "get_read_path.bfs" method and added dto the ds as 'read_path'
#' the query list, a list element containing all query parameters, gets constructed with "get_px_query_list()"
#'
#' To set up a PXWEB query list manually, start with a specific path and walk thorough each step
#' d <- pxweb::pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")
read_data.px <- function(ds){
  # Create the query list using "get_px_query_list()"
  query_list <- get_px_query_list(ds)

  # Stream the BFS data for a specific data cube and with the defined parameters
  data <- pxweb::pxweb_get(url = ds$read_path,
                           query = query_list)

  # Convert to data.frame and append to the dataset as 'data'
  ds$data <- as.data.frame(
    data,
    column.name.type = "text",
    variable.value.type = "text"
  )

  return(ds)
}




