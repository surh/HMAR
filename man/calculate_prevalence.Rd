% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_prevalence.r
\name{calculate_prevalence}
\alias{calculate_prevalence}
\title{Calculate taxon prevalence}
\usage{
calculate_prevalence(Dat, thres = 1, group = NULL)
}
\arguments{
\item{Dat}{a dataset object}

\item{thres}{Minimum number of reads for a taxon
in a sample to be counted as present.}

\item{group}{A grouping variable}
}
\description{
Calculates the prevalence of each
taxon overall or by some grouping factor.
}
\author{
Sur Herrera Paredes
}
