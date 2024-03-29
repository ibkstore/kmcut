#' For each feature in the input file, this function performs a univariate
#' Cox regression with the likelihood ratio test.
#'
#' @param fname character vector that specifies the name of the file with
#' feature(s) for each sample. The file must be tab-delimited,
#' where features are in rows and samples are in columns. First column must
#' contain feature names. Column names must contain sample ids.
#' @param sfname character vector that specifies the name of the file with
#' right-censored survival time data. The file must be tab-delimited,
#' where samples are in rows. First column must be named sample_id and contain
#' sample ids that match those in 'fname'. The file must
#' contain columns called 'stime' and 'scens', with survival time and censoring
#' variable (0 or 1), respectively.
#' @param bfname character vector that specifies the base name used to
#' construct output files. If bfname = NULL (default), the 'fname' argument is
#' used to create a base name. 
#' @param wdir character vector that specifies the name of the working
#' directory for the input/output files (defaults to the current R directory).
#' Output file names are automatically created by
#' adding "_ucoxbatch.txt" to 'fname'.
#' @param min_uval numeric value that specifies the minimal percentage
#' of unique values per feature (default is 50)
#' Features that have less than 'min_uval' percent unique values are
#' excluded from the analysis.
#' @param psort logical value whether to sort the output table by p-values
#' in increasing order (default is FALSE).
#' @param verbose logical value whether to print progress (default is TRUE).
#' @return no return value
#'
#' @export
#' @examples
#'
#' # Example with data files included in the package:
#'
#' library(survival)
#' library(stringr)
#' library(data.table)
#' library(tools)
#' library(pracma)
#' library(kmcut)
#'
#' # Load example gene expression data and survival data for 2 genes
#' # and 295 samples
#' fdat <- system.file("extdata", "example_genes_295.txt", package = "kmcut")
#' sdat <- system.file("extdata", "survival_data_295.txt", package = "kmcut")
#'
#' ucoxbatch(fname = fdat, sfname = sdat)
#'
#' # This will create in the current working directory a tab-delimited text
#' # file with the results: "example_genes_295_ucoxbatch.txt"

ucoxbatch<-function(
    # The file with feature(s) for each sample (samples are in columns,
    # features are in rows)
    fname,
    # The file with survival time data
    sfname,
    # Base name for the output files
    bfname = NULL,
    # Working directory for the input/output files
    wdir = getwd(),
    # Min percentage of unique values in ]0, 100] for each feature
    min_uval = 50,
    # Option to sort the output table by p-values in increasing order
    # (FALSE by default)
    psort = FALSE,
    # Print progress (TRUE by default)
    verbose = TRUE
)
# begin function
{

if(min_uval <= 0 || min_uval > 100)
{
    stop("min_uval must be in ]0, 100]")
}

setwd(wdir)

if(is.null(bfname)) bfname <- basename(file_path_sans_ext(fname))
# Name of the output TXT file
txt_file <- sprintf("%s_ucoxpbatch.txt", bfname)

# The survival time data
sdat_init <- read.delim(sfname, header = TRUE, stringsAsFactors = FALSE,
                    sep = "\t")

# Must have "status" and "time" variables
sdat <- data.frame(sdat_init$sample_id, sdat_init$scens, sdat_init$stime)
colnames(sdat) <- c("sample_id", "status", "time")

# The input data table
edat <- read.delim(fname, header = TRUE, stringsAsFactors = FALSE, sep = "\t",
                row.names = 1, check.names = TRUE)
edat <- filter_unique(edat, min_uval)
edat <- as.data.frame(t(edat))

# Convert row names into first column
rnames <- rownames(edat)
edat <- cbind(rnames, edat)
colnames(edat)[1] <- "sample_id"

edat <- merge(edat, sdat, by.x = 1, by.y = 1, all = FALSE)
rownames(edat) <- unlist(edat["sample_id"])
edat["sample_id"] <- NULL
colnames(edat) <- make.names(colnames(edat), unique = TRUE)

# Check for missing and non-numeric elements
row.has.na <- apply( edat, 1, function(x){any(is.na(x) | is.nan(x) |
                                            is.infinite(x))} )
s <- sum(row.has.na)
if(s > 0)
{
    stop("The input data table has missing or non-numeric elements")
}

# Recalculate the number of features in the table
n_genes <- length(colnames(edat)) - 2

# Results table
results <- matrix(data = NA, nrow = n_genes, ncol = 4)
colnames(results) <- c("CC","HR","P","FDR_P")
rownames(results) <- colnames(edat)[seq_len(n_genes)]

# Go over each feature and calculate C-index
for(i in seq_len(n_genes))
{
    if(verbose == TRUE)
    {
        message("Processing ",i," of ",n_genes)
    }

    res <- coxph(Surv(time, status) ~ edat[,i], data=edat, model = FALSE)
    r <- summary(res)
    results[i,"HR"] <- r$coef[2]
    results[i,"CC"] <- unlist(r$concordance["C"])
    df <- as.data.frame(r["logtest"])
    results[i,"P"] <- df["pvalue",1]
}
results[,"FDR_P"]  <- p.adjust(results[,"P"], method = "fdr")

if(length(rownames(results)) > 1 && psort == TRUE)
{
    results <- results[order(results[,"P"]),]
}

# Convert to table and convert row names into a column
df <- as.data.frame(results)
setDT(df, keep.rownames=TRUE)
colnames(df)[1] <- "tracking_id"
write.table(df, file = txt_file, quote = FALSE, row.names = FALSE,
            col.names = TRUE, sep = "\t")

}
# end function
