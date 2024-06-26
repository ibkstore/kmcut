% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/kmoptscut.R
\name{km_opt_scut}
\alias{km_opt_scut}
\title{Find optimal stratification cutoffs}
\usage{
km_opt_scut(
  obj,
  bfname,
  wdir = getwd(),
  min_fraction = 0.1,
  min_up_down = 1,
  peak_tolerance = 0.1,
  min_uval = 50,
  psort = FALSE,
  wlabels = TRUE,
  wpdf = TRUE,
  verbose = TRUE
)
}
\arguments{
\item{obj}{SummarizedExperiment object with expression-like data}

\item{bfname}{a character string (character vector of length 1) that 
specifies the base name used to create output file names, which 
are created by adding "_KMopt_minf_.2f" and corresponding extension
to 'bfname'.}

\item{wdir}{a character string (character vector of length 1) that 
specifies the name of the working directory for the input/output files 
(defaults to the current R directory).}

\item{min_fraction}{numeric value that specifies the minimal
fraction of samples in the smaller group (default is 0.1).}

\item{min_up_down}{numeric value that specifies the minimal
number of up/down points on either side of the peak for
'pracma::findpeaks' function (default is 1).}

\item{peak_tolerance}{numeric value that specifies the maximal
difference between in heigth between top peaks.
The peak within 'peak_tolerance' closest to the median value is selected.}

\item{min_uval}{numeric value that specifies the minimal percentage of
unique values per feature (default is 50).
Features that have less than 'min_uval' percent unique values are
excluded from the analysis.}

\item{psort}{logical value whether to sort the output table by
p-values in increasing order (default is FALSE).}

\item{wlabels}{logical value whether to write a CSV file with
low/high (below/above the cutoff) group sample labels (default is TRUE).}

\item{wpdf}{logical value whether to write a PDF file with plots
(default is TRUE).}

\item{verbose}{logical value whether to print progress (default is TRUE).}
}
\value{
no return value
}
\description{
For each feature, finds a cutoff that optimally stratifies samples
into 2 groups, plots Kaplan-Meier survival curves and observed vs. expected
optimization plot. Does not perform the permutation test to estimate the
statistical significance of the cutoff.
}
\examples{

# Example with data files included in the package:

# Load example gene expression data and survival data for 2 genes
# and 93 samples
fdat <- system.file("extdata", "example_genes.txt", package = "kmcut")
sdat <- system.file("extdata", "survival_data.txt", package = "kmcut")

# Create SummarizedExperiment object
se <- create_se_object(efile = fdat, sfile = sdat)

# Search for optimal cutoffs
km_opt_scut(obj = se, bfname = "test", wpdf = FALSE)

# This will create two output files in the current working directory:
# 1) Tab-delimited text file with the results:
# "test_KMopt_minf_0.10.txt"
# 2) CSV file with low/high sample labels:
# "test_KMopt_minf_0.10_labels.csv"
}
