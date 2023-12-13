#' Function to retrieve the asset number and the last year of the time series
#' for a specific BFS number
#'
#' This function scrapes the asset page of a BFS-nr
#' !important: this bfs-nr here does not correspond to the bfs-nr of the municipality
#'
#' @param bfs_nr Number of a bfs publication e.g: "ind-d-21.02.30.1202.02.01"
get_bfs_asset_info <- function(ds) {
  bfs_home <- "https://www.bfs.admin.ch"

  asset_page <- httr::GET(paste0(bfs_home, "/asset/de/", ds$data_id), config = httr::use_proxy("")) %>%
    rvest::read_html()


  #asset_page <- xml2::read_html(paste0(bfs_home, "/asset/de/", ds$data_id))

  # Retrieve asset number
  # 'asset_number' is used to construct the current read_paths for BFS assets from the DAM API.
  ds$asset_number <- asset_page %>%
    rvest::html_text(ds$data_id) %>%
    stringr::str_extract("https://.*assets/.*/") %>%
    stringr::str_extract("[0-9]+")

  # Retrieve last year of the time series
  # 'year_end' is used in the px query list
  ds$year_end <- asset_page %>%
    rvest::html_element("table") %>%
    rvest::html_table() %>%
    dplyr::filter(X1 == "Dargestellter Zeitraum") %>%
    dplyr::pull(X2) %>%
    substr(., nchar(.) - 3, nchar(.))

  return(ds)
}

#' Function that generates the query list for PX data formats.
#'
#' This function reads the required parameters per dataset from the dataset list and compiles the query list.
#' The query list, is a list element containing all query parameters following
#' the general structure: list("Jahr"=c("2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"),
#'                         "Kanton"=c("8100","ZH"),
#'                          "Bevölkerungstyp"=c("1"))
#'
#' To set up a PXWEB query list manually, start with a specific path and walk thorough each step
#' d <- pxweb::pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")#'
#'
#' @param ds dataset object
get_px_query_list <- function(ds) {

  query_list <- list()

  # FIXME: At the next update check labels for the year!!
  # if it is still coded, we need to get the code for the max year
  # if the codes were changed to the actual year, we can get rid of the
  # if else clause
  # gma, 2023-12-13, changed "G1" to "G9", if it works: "if else" can be simplified to
  # query_list[[ds$year_col]] <- as.character(ds$year_start:ds$year_end)

  if(ds$dataset_id == "G9"){
    query_list[[ds$year_col]] <- as.character(ds$year_start)
  }else{
    query_list[[ds$year_col]] <- as.character(
      ds$year_start:ds$year_end
    )
  }

  # excel coerces comma to decimal point in gebiet_id
  if(stringr::str_detect(ds$gebiet_id, pattern = "\\.")){
    query_list[[ds$gebiet_col]] <- stringr::str_split(ds$gebiet_id, "\\.")[[1]]
  }else{
    query_list[[ds$gebiet_col]] <- stringr::str_split(ds$gebiet_id, ",")[[1]]
  }



  # check if two dimension cols are given in the parameter list
  if(!is.na(ds$dimension1_col)){
    query_list[[ds$dimension1_col]] <- stringr::str_split(ds$dimension1_id, ",")[[1]] %>%
      stringr::str_squish() # get rid of whitespace

  }
  if(!is.na(ds$dimension2_col)){
    query_list[[ds$dimension2_col]] <- stringr::str_split(ds$dimension2_id, ",")[[1]] %>%
      stringr::str_squish() # get rid of whitespace
  }


  return(query_list)
}

#' Function that creates the download url based on dataset_id and data_type
#'
#' Methods differ according to the data-holding organisation
#'
#' @param ds dataset object
get_read_path <- function(ds) UseMethod("get_read_path")

#' Standard method for creating the path of the download URL
#' for any data-holding organisation other than the FSO.
#'
#' General path format: paste of base url and id
#'
#' @param ds dataset object
#'
#' @export
get_read_path.default <- function(ds) {

  # creating the path of the download URL
  ds$read_path <- paste0(ds$data_url, ds$data_id)

  # set which data (xlsx sheet number) to 1 (first sheet) if not specified in excel list
  if(is.na(ds$which_data)){
    ds$which_data <- 1
  }

  return(ds)
}

#' Function for creating the FSP-specific read path
#'
#' Use cases currently are XLSX via DAM API and via PXWEB data cubes
#'
#' @param ds dataset object
#'
#' @export
get_read_path.bfs <- function(ds) {

  ds <- get_read_path_bfs(ds)

  return(ds)
}

get_read_path_bfs <- function(ds) UseMethod("get_read_path_bfs")

#' Default method for creating the read path for data via the DAM API
#'
#' the asset number (BFS Nr) is required
#'
get_read_path_bfs.default <- function(ds){
  # get asset number
  ds <- get_bfs_asset_info(ds)

  # set download path
  ds$read_path <- paste0(ds$data_url, ds$asset_number, "/master")

  return(ds)
}
#' Method for creating the read path for PXWEB data cubes
#'
#' the asset number (BFS Nr) is required
get_read_path_bfs.px <- function(ds){

  ds <- get_bfs_asset_info(ds)

  # Create the download url
  # all required information, like the name of the data cube, are in the dataset (ds)
  # Example: name of the data cube ("px-x-0103010000_102") is taken from ds$data_id
  ds$read_path <- paste0(ds$data_url, ds$data_id, "/", ds$data_id, ".px")

  return(ds)
}
