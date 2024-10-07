#' Function to retrieve the asset number and the last year of the time series
#' for a specific BFS number
#'
#' This function scrapes the asset page of a BFS-nr
#' !important: this bfs-nr here does not correspond to the bfs-nr of the municipality
#'
#' @param bfs_nr Number of a bfs publication e.g: "ind-d-21.02.30.1202.02.01"
get_bfs_asset_info <- function(ds) {



  # Define the base URL for the DAM API
  base_url <- "https://dam-api.bfs.admin.ch/hub/api/dam/assets"

  # Use withr::with_envvar to set no_proxy environment variable
  withr::with_envvar(
    new = c("no_proxy" = "dam-api.bfs.admin.ch"),
    code = {
      # Build the request URL with the order number as a query parameter
      response <- httr2::request(base_url) %>%
        httr2::req_url_query(orderNr = ds$data_id) %>%
        httr2::req_headers(
          "accept" = "application/json",      # Ensure we accept JSON
          "Content-Type" = "application/json" # Request content type is JSON
        ) %>%
        httr2::req_perform()



        # Parse the JSON response body into a list
        data <- httr2::resp_body_json(response)

    }
  )

  # save the resulting link list
  links <- data[["data"]][[1]][["links"]]

  # Define URL extraction based on the format using regex
  if (ds$download_format == "px") {
    # Regex to match URLs for .px files
    px_regex <- "https://www\\.pxweb\\.bfs\\.admin\\.ch/api/v1/.+\\.px"
    for (link in links) {
      if (grepl(px_regex, link$href)) {
        ds$read_path <- link$href
        found <- TRUE
        break
      }

      }
    if(found != TRUE){
      stop("Error: No matching .px URL found.")
    }



  } else if (ds$download_format == "xlsx") {
    # Look for the master link with format xlsx
    for (link in links) {
      if (link$rel == "master" && link$format == "xlsx") {
        ds$read_path <- link$href
        found <- TRUE
        break
      }

    }

    if(found != TRUE){
      stop("Error: No matching .xlsx URL found.")
    }
  }

  # extract the last year of the data from the API meta data
  year_end <- data[["data"]][[1]][["description"]][["bibliography"]][["period"]] %>%
    stringr::str_extract(pattern = "(?<=-)[[:digit:]]{4}")

  ds$year_end <- as.numeric(year_end)



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

  # extract the labels & codes for the years in the px data
  lookup_list_year <- get_px_year_info(ds)

  # get the index of the supplied start year
  start_year_index <- which(lookup_list_year$valueTexts == ds$year_start)

  start_year_value_text <- as.integer(lookup_list_year$valueTexts[[start_year_index]])


  start_year_code <- as.integer(lookup_list_year$values[[start_year_index]])


  #check if supplied year start can be found in the codes from the bfs px
  if(ds$year_start %in% lookup_list_year$values && start_year_code == ds$year_start){
    query_list[[ds$year_col]] <- as.character(ds$year_start:ds$year_end)
  } else {
    # check if Values are counted upwards or downwards
    if(as.integer(lookup_list_year$valueTexts[[1]]) < as.integer(lookup_list_year$valueTexts[[2]])){
      # values are counted upwards
      query_list[[ds$year_col]] <- as.character(lookup_list_year$values[[start_year_index]]:lookup_list_year$values[[length(lookup_list_year$values)]])
    } else {
      # values are counted downwards
      query_list[[ds$year_col]] <- as.character(lookup_list_year$values[[start_year_index]]:0)
    }
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
  # get asset number, year_end & download_path
  ds <- get_bfs_asset_info(ds)

  return(ds)
}



#' Extract the labels & codes for the years in the px data
#'
#' @param ds
#'
#' @return list object which includes labels and codes
#'
#'
#'
get_px_year_info <- function(ds){
  #get the json file with meta-data
  withr::with_envvar(
    new = c("no_proxy" = "pxweb.bfs.admin.ch"),
    code = {
      # Make the GET request and retrieve the JSON response
      response <- httr2::request(ds$read_path) |>
        httr2::req_perform()
    }
  )

  # parse it to a list
  parsed_data <- httr2::resp_body_json(response)

  # find the right list element which includes the years
  for (variable in parsed_data$variables) {
    if (variable$code == ds$year_col) {
      jahr_variable <- variable
      break  # Exit the loop once found
    }
  }

  # fill the information in a list
  if (!is.null(jahr_variable)) {
    jahr_code <- jahr_variable$code
    jahr_text <- jahr_variable$text
    jahr_values <- jahr_variable$values
    jahr_valueTexts <- jahr_variable$valueTexts

    # Return as a list including values and valueTexts
    lookup_list_year <- list(
      code = jahr_code,
      text = jahr_text,
      values = jahr_values,
      valueTexts = jahr_valueTexts
    )

  } else {
    stop("Error: 'Jahr' variable not found")
  }

  return(lookup_list_year)

}



