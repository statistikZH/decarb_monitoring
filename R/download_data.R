#' Function for streaming the data.
#'
#' We are only streaming the data, meaning we do not store local files of the
#' data. Data streamed is held temporarily and deleted afterwards.
#'
#' The function first runs the get_read_path() method corresponding to the dataset ID,
#' with which the read path for the download URL is created.
#' Next the function uses the appropriate read_data() method to stream and append
#' the data to the dataset (ds) in the $data object.
#'
#' @inheritParams download_data
#'
#' @export
download_data <- function(ds){

  # creates the path for the download URL
  ds <- get_read_path(ds)
  # streams the data and appends it to the ds in $data
  ds <- read_data(ds)

  # if the dataset requires a dependency (another dataset) the read function is called again and downloads the dependency
  # second part of if statement is need to ensure there is no infinite recursion (same dataset dowloaded over & over)
  if(!is.na(ds$dependency) && ds$dataset_id != ds$dependency){

    ds$dep <- list()

    # Splitting the dependencies into a vector
    deps <- strsplit(ds$dependency, ", ")[[1]]

    # Iterating over each dependency in the list
    for (dep in deps) {

      # Temporarily create a dependent ds and download the data
      ds_dep <- create_dataset(dep)
      ds_dep <- download_data(ds_dep)

      # Add the downloaded data to the original ds object
      ds$dep[[dep]] <- ds_dep$data
    }
  }
  # Only return the initial ds object
  return(ds)
}

#' Function to stream data
#'
#' For PXWEB data we need to define its own method, because we are working with
#' the PXWEB package for streaming data. Every other use case can be handled by
#' the default method.
#'
read_data <- function(ds) UseMethod("read_data")
#' Default method
#'
#' The method is used in all cases where the input data is a csv, xlsx or
#' one of both packaged in a zipped folder
#'
#' Working with import() from the rio package: https://cran.r-project.org/web/packages/rio/vignettes/rio.html
#' rio uses the file extension of a file name to determine what kind of file it is
#' and thus rio allows almost all common data formats to be read with the same function
#' !Attention: package seems to be stable. Nevertheless, keep an eye out for potential issues.
#'
read_data.default <- function(ds) {

  # Get the file extension from the URL or the given info from the excel sheet
  if(!is.na(ds$download_format)){
    file_ext <- ds$download_format
  }else{
    file_ext <- tools::file_ext(ds$read_path)
  }

  temp_file <- paste0("temp.", file_ext)

  # Download the file

  if (Sys.info()["sysname"] == "Windows"){

    download_method <- "wininet"


  }else{

    download_method <- "auto"

  }


  withr::with_envvar(new = c("no_proxy" = "dam-api.bfs.admin.ch"),
                     code = download.file(url = ds$read_path, destfile = temp_file, mode = "wb", method = download_method))
  # Import the data
  ds$data <-  rio::import(temp_file, which = ds$which_data, header = TRUE)

  # Remove the temporary file
  file.remove(temp_file)

  return(ds)
}



#' Method to stream data from pxweb data cubes which is unique to the BFS
#' Downloads the data from a data cube based on a query list and converts it to a data.frame
#'
#' We are using the PXWEB package to stream BFS data:
#' https://ropengov.github.io/pxweb/articles/pxweb.html
#'
#' !!! Important Limits: 10 calls per 10 sec., 5000  values per call
#'
#' the name of the data cube, e.g. "px-x-0103010000_102", is taken from ds$data_id
#' the download url is constructed with the "get_read_path.bfs" method and added dto the ds as 'read_path'
#' the query list, a list element containing all query parameters, gets constructed with "get_px_query_list()"
#'
#' To set up a PXWEB query list manually, start with a specific path and walk thorough each step
#' d <- pxweb::pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")
#'
read_data.px <- function(ds){

  # Create the query list using get_px_query_list() function
  query_list <- get_px_query_list(ds)

  # Stream the BFS data for a specific data cube and with the defined parameters
  # set the env variable to no_proxy temporarily (otherwise no connection possible)
  withr::with_envvar(new = c("no_proxy" = "www.pxweb.bfs.admin.ch"),
                     code =  data <- pxweb::pxweb_advanced_get(url = ds$read_path,
                                                               query = query_list,
                                                               config = httr::use_proxy(NULL))
  )

  # Convert to data.frame and append to the dataset as 'data'
  ds$data <- as.data.frame(
    data,
    column.name.type = "text",
    variable.value.type = "text"
  )

  return(ds)
}
