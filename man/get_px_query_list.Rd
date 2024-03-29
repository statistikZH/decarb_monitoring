% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download_helpers.R
\name{get_px_query_list}
\alias{get_px_query_list}
\title{Function that generates the query list for PX data formats.}
\usage{
get_px_query_list(ds)
}
\arguments{
\item{ds}{dataset object}
}
\description{
This function reads the required parameters per dataset from the dataset list and compiles the query list.
The query list, is a list element containing all query parameters following
the general structure: list("Jahr"=c("2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021"),
"Kanton"=c("8100","ZH"),
"Bevölkerungstyp"=c("1"))
}
\details{
To set up a PXWEB query list manually, start with a specific path and walk thorough each step
d <- pxweb::pxweb_interactive("https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0103010000_102")#'
}
