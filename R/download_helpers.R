#' Function to scrape the asset number of a specific BFS number
#'
#' This function scrapes the asset page of a BFS-nr for the asset number
#' !important: this bfs-nr is not the municipality bfs-nr
#'
#' @param bfs_nr Number of a bfs publication e.g: "ind-d-21.02.30.1202.02.01"
get_bfs_asset_nr <- function(bfs_nr) {
  bfs_home <- "https://www.bfs.admin.ch"

  asset_page <- xml2::read_html(paste0(bfs_home, "/asset/de/", bfs_nr))

  asset_number <- asset_page %>%
    rvest::html_text(bfs_nr) %>%
    stringr::str_extract("https://.*assets/.*/") %>%
    stringr::str_extract("[0-9]+")

  return(asset_number)
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

  # Year does not work for G1 yet
  query_list[[ds$year_col]] <- as.character(ds$year_start:lubridate::year(Sys.Date()- lubridate::years(2)))
  query_list[[ds$gebiet_col]] <- stringr::str_split(ds$gebiet_id, ",")[[1]]
  query_list[[ds$dimension_col]] <- stringr::str_split(ds$dimension_id, ",")[[1]]

  return(query_list)
}

#' Function that creates the download url based on dataset_id and data_type
#'
#' @param ds dataset object
get_download_url <- function(ds) UseMethod("get_download_url")

#' Default method used to create the download url for PX and CSV data_type
#' where the download url is a paste of url and id
#'
#' @param ds dataset object
#'
#' @export
get_download_url.default <- function(ds) {

  # set download path
  ds$download_url <- paste0(ds$data_url, ds$data_id)

  return(ds)
}

#' Method to create the download url for the XLSX data from the BFS
#' requires the asset number (BFS Nr) for the BFS DAM API
#'
#' @param ds dataset object
#'
#' @export
get_download_url.bfs <- function(ds) {

  # get asset number
  asset_number <- get_bfs_asset_nr(ds$data_id)

  # set download path
  ds$download_url <- paste0(ds$data_url, asset_number, "/master")

  return(ds)
}



