% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/kmvalcut.R
\name{kmvalcut}
\alias{kmvalcut}
\title{Creates Kaplan-Meier survival curves for each feature from a validation
data set by using a file with previously determined
stratification threshold (one threshold per feature), and calculates the
log-rank test p-value.}
\usage{
kmvalcut(
  input1,
  input2,
  sfname,
  bfname = NULL,
  wdir = getwd(),
  min_uval = 50,
  psort = FALSE,
  wlabels = TRUE,
  wpdf = TRUE
)
}
\arguments{
\item{input1}{character vector that specifies the name of tab-delimited
file with the table that contains one or more feature
and a stratification threshold for each feature (this table is produced
by kmoptscut, kmoptpermcut, kmqcut or kmucut).
The file with previously determined stratification thresholds must have
first two columns named as 'tracking_id' and 'CUTOFF'.
The 'tracking_id' column contains feature names, the 'CUTOFF' column
contains stratification threshold for each feature.}

\item{input2}{character vector that specifies the name of the validation
file with feature(s) for each sample. The file must be tab-delimited,
where features are in rows and samples are in columns. First column must
contain feature names. Column names must contain sample ids.
Feature names must exactly match the ones in 'input1' file.}

\item{sfname}{character vector that specifies the name of the file with
right-censored survival time for the validation data. The file must be
tab-delimited,
where samples are in rows. First column must be named 'sample_id' and
contain sample ids that match those in 'fname'. The file must contain
columns called 'stime' and 'scens',
with survival time and censoring variable (0 or 1), respectively.}

\item{bfname}{character vector that specifies the base name used to
construct output files. If bfname = NULL (default), the 'input2' argument
is used to create a base name.}

\item{wdir}{character vector that specifies the name of the working
directory for the input/output files (defaults to the current R directory).
Output file names are automatically created by adding\cr'_KM_val'
and corresponding extension to 'input2'.}

\item{min_uval}{numeric value that specifies the minimal percentage of
unique values per feature.
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
Creates Kaplan-Meier survival curves for each feature from a validation
data set by using a file with previously determined
stratification threshold (one threshold per feature), and calculates the
log-rank test p-value.
}
\examples{

# Example with data files included in the package:

library(survival)
library(stringr)
library(data.table)
library(tools)
library(pracma)
library(kmcut)

# Load training (fdat1) and validation (fdat2) gene expression data
# files and survival data file (sdat).
fdat1 <- system.file("extdata", "expression_data_1.txt", package = "kmcut")
fdat2 <- system.file("extdata", "expression_data_2.txt", package = "kmcut")
sdat <- system.file("extdata", "survival_data_295.txt", package = "kmcut")

# Run 'kmqcut' on the training data "expression_data_1.txt" to create a file
# with thresholds "expression_data_1_KM_quant_50.txt".
kmqcut(fname = fdat1, sfname = sdat, quant = 50, min_uval = 40)

# Validate the thresholds in "expression_data_1_KM_quant_50.txt" on
# validation data "expression_data_2.txt".
kmvalcut(input1 = "expression_data_1_KM_quant_50.txt",input2 = fdat2,
sfname = sdat, wpdf = FALSE, min_uval = 40)

# This will create two output files in the current working directory:
# 1) Tab-delimited text file with the results:
# "expression_data_2_KM_val.txt"
# 2) CSV file with low/high sample labels:
# "expression_data_2_KM_val_labels.csv"
}
