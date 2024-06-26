% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/extractcolumns.R
\name{extract_columns}
\alias{extract_columns}
\title{Extract a sub-set of columns}
\usage{
extract_columns(fnamein, fids, fnameout, wdir = getwd())
}
\arguments{
\item{fnamein}{a character string (character vector of length 1) that
specifies the name of tab-delimited text file with the input data table.}

\item{fids}{a character string (character vector of length 1) that
specifies the name of text file with column ids (such as sample ids).
The file must contain one column id per line, without
any trailing spaces or any other additional symbols.}

\item{fnameout}{a character string (character vector of length 1) that
specifies the name of output file where the new data table will be saved.}

\item{wdir}{a character string (character vector of length 1) that
specifies the name of the working directory for the input/output files 
(defaults to the current R directory).}
}
\value{
no return value
}
\description{
Extract a sub-set of columns (such as a sub-set of samples)
from a data table. All rows will be preserved.
}
\examples{

# Example with built-in data files:

# Load example gene expression data table for 2 genes
fdat <- system.file("extdata", "example_genes.txt", package = "kmcut")
# Load a list that contains column (sample) ids
idlist <- system.file("extdata", "columnids.txt", package = "kmcut")
# Run the function
extract_columns(fnamein = fdat, fids = idlist, 
                fnameout = "example_samples_subset.txt")

# This will create in the current working directory a tab-delimited text file
# "example_samples_subset.txt"
}
