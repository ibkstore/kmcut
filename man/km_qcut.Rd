% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/kmqcut.R
\name{km_qcut}
\alias{km_qcut}
\title{Apply quantile-based stratification cutoffs}
\usage{
km_qcut(
  obj,
  bfname,
  wdir = getwd(),
  quant = 50,
  min_uval = 50,
  psort = FALSE,
  wlabels = TRUE,
  wpdf = TRUE
)
}
\arguments{
\item{obj}{SummarizedExperiment object with expression-like data}

\item{bfname}{a character string (character vector of length 1) that 
specifies the base name used to create output file names, which 
are created by adding\cr"_KM_quant_d" and corresponding extension
to 'bfname'.}

\item{wdir}{a character string (character vector of length 1) that
specifies the name of the working directory for the output files 
(defaults to the current R directory).}

\item{quant}{numeric value that specifies the cutoff quantile for
stratification. The default is 50th quantile (the median).}

\item{min_uval}{numeric value that specifies the minimal percentage of
unique values per feature (default is 50).
Features that have less than 'min_uval' percent unique values are
excluded from the analysis.}

\item{psort}{logical value whether to sort the output table by p-values
in increasing order (default is FALSE).}

\item{wlabels}{logical value whether to write a CSV file with low/high
(below/above the cutoff) group sample labels (default is TRUE).}

\item{wpdf}{logical value whether to write a PDF file with plots
(default is TRUE).}
}
\value{
no return value
}
\description{
For each feature uses the cutoff supplied as quantile (in 0 to 100 range)
to stratify samples into 2 groups, plots Kaplan-Meier survival curves, and
performs the log-rank test.
}
\examples{

# Example with data files included in the package:

# Load example gene expression data and survival data for 2 genes and
# 93 samples
fdat <- system.file("extdata", "example_genes.txt", package = "kmcut")
sdat <- system.file("extdata", "survival_data.txt", package = "kmcut")

# Create SummarizedExperiment object
se <- create_se_object(efile = fdat, sfile = sdat)

# Apply quantile-based stratification cutoffs
km_qcut(obj = se, bfname = "test", quant = 50, wpdf = FALSE)

# This will create two output files in the current working directory:
# 1) Tab-delimited text file with the results:
# "test_KM_quant_50.txt"
# 2) CSV file with low/high sample labels:
# "test_KM_quant_50_labels.csv"
}
