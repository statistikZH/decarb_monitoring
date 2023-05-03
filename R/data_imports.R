# Currently keeping these functions so the single scripts per Dataset ID can still be executed.
#' Get data from PXWEB
#'
#' @param px_cube Path name of the data cube, e.g. "px-x-0103010000_102"
#' @param query_list Pre-constructed list element containing all query parameters
#'
#' @return Download data based on query list and convert to data.frame
# Example query for Ständige Wohnbevölkerung, Schweiz und Kanton Zürich
# px_cube <- "px-x-0103010000_102"
# query_list <- list("Jahr"=c("2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"),
#                    "Kanton"=c("8100","ZH"),
#                    "Bevölkerungstyp"=c("1"))

get_pxdata <- function(px_cube, query_list){

  # Using pxweb package to stream BFS data
  # https://ropengov.github.io/pxweb/articles/pxweb.html
  # renv::install("pxweb")
  # library(pxweb)

  # $www.pxweb.bfs.admin.ch
  # Api: www.pxweb.bfs.admin.ch
  # Statistics Switzerland
  # ('switzerland')
  # Version(s)   : v1
  # Language(s)  : en, de, fr
  # Limit(s)     : 10 calls per 10 sec.
  # 5000  values per call.
  # Url template :
  #   https://www.pxweb.bfs.admin.ch/api/[version]/[lang]
  # Start with a specific path --> set up a PXWEB query list
  # d <- pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")

  # Download data "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102/px-x-0103010000_102.px"
  px_data <-
    pxweb::pxweb_get(url = paste0("https://www.pxweb.bfs.admin.ch/api/v1/de/", px_cube, "/", px_cube, ".px"),
              query = query_list)

  # Convert to data.frame
  px_data_frame <- as.data.frame(px_data, column.name.type = "text", variable.value.type = "text")

  return(px_data_frame)
}


#' Get data resource (csv) from open data ZH
#'
#' @param file_name File name as provided at the resource on zh.ch/daten, e.g. KTZH_00001661_00003118.csv
#'
#' @return data.frame

get_openzh_data <- function(file_name){

  base_url <- "https://www.web.statistik.zh.ch/ogd/daten/ressourcen/"

  openzh_data <- data.table::fread(paste0(base_url, file_name))

  return(openzh_data)
}

#' Get zipped data files (csv) from opendata.swiss via api calls
#'
#' @param data_url Access url for the api
#' @param data_file_name File name including file format, e.g. RecycledWaste.csv
#'
#' @return data.frame

get_zip_data <- function(data_url, data_file_name){

  # data_url <- "https://data.geo.admin.ch/ch.bfe.kehrichtverbrennungsanlagen/kehrichtverbrennungsanlagen/kehrichtverbrennungsanlagen_2056.csv.zip"
  # data_file_name <- "RecycledWaste.csv"

  # Create a temp. file name
  temp <- tempfile()

  # Fetch the zip file into the temp. file
  utils::download.file(data_url, temp)

  # Unzip the file
  utils::unzip(temp, data_file_name)

  # Use unz() to extract the target file from temp. file and convert to data.frame
  data <- data.table::fread(utils::unzip(temp, data_file_name), header= TRUE ) %>%
    as.data.frame(.)

  # Remove the temp file
  unlink(temp)

  return(data)
}

