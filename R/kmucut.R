#' For each feature uses the user-supplied cutoff to stratify samples
#' into 2 groups,
#' plots Kaplan-Meier survival curves, and calculates the log-rank test p-value
#'
#' @param fname character vector that specifies the name of the file
#' with feature(s) for each sample. The file must be tab-delimited,
#' where features are in rows and samples are in columns. First column
#' must contain feature names. Column names must contain sample ids.
#' @param sfname character vector that specifies the name of the file
#' with right-censored survival time data. The file must be tab-delimited,
#' where samples are in rows. First column must be named 'sample_id' and
#' contain sample ids that match those in 'fname'. The file must contain
#' columns called 'stime' and 'scens',
#' with survival time and censoring variable (0 or 1), respectively.
#' @param bfname character vector that specifies the base name used to
#' construct output files. If bfname = NULL (default), the 'fname' argument is
#' used to create a base name. 
#' @param wdir character vector that specifies the name of the working
#' directory for the input/output files (defaults to the current R directory).
#' Output file names are automatically created by adding\cr"_KM_ucut_.2f"
#' and corresponding extension to 'fname'.
#' @param cutoff numeric value that specifies the cutoff value for
#' stratification.The same cutoff is applied to every feature in the dataset.
#' @param min_uval numeric value that specifies the minimal percentage of
#' unique values per feature (default is 50).
#' Features that have less than 'min_uval' percent unique values are
#' excluded from the analysis.
#' @param psort logical value whether to sort the output table by p-values
#' in increasing order (default is FALSE).
#' @param wlabels logical value whether to write a CSV file with low/high
#' (below/above the cutoff) group sample labels (default is TRUE).
#' @param wpdf logical value whether to write a PDF file with plots
#' (default is TRUE).
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
#' kmucut(fname = fdat, sfname = sdat, cutoff = 5, min_uval = 90, wpdf = FALSE)
#'
#' # This will create two output files in the current working directory:
#' # 1) Tab-delimited text file with the results:
#' # "example_genes_295_KM_ucut_5.txt"
#' # 2) CSV file with low/high sample labels:
#' # "example_genes_295_KM_ucut_5_labels.csv"

kmucut<-function(
                    # The file with feature(s) for each sample
                    # (samples are in columns, features are in rows)
                    fname,
                    # The file with survival time data
                    sfname,
                    # Base name for the output files
                    bfname = NULL,
                    # Working directory with the input/output files
                    wdir = getwd(),
                    # The user-supplied cutoff value. Samples with
                    #values of the feature <= cutoff are labeled as "low",
                    # samples with values of the feature > cutoff are
                    # labeled as "high"
                    cutoff,
                    # Min percentage of unique values in ]0, 100%] for
                    # each feature
                    min_uval = 50,
                    # Option to sort the output table by p-values in
                    # increasing order (TRUE by default)
                    psort = FALSE,
                    # Write a CSV file with low/high sample labels
                    # (TRUE by default)
                    wlabels = TRUE,
                    # Write a PDF file with survival curves (TRUE by default)
                    wpdf = TRUE
)
# begin function
{

if(min_uval <= 0 || min_uval > 100)
{
    stop("min_uval must be in ]0, 100]")
}

setwd(wdir)

if(is.null(bfname)) bfname <- basename(file_path_sans_ext(fname))
# Name of the output PDF file
pdf_file <- sprintf("%s_KM_ucut_%.2f.pdf", bfname, cutoff)
# Name of the output TXT file
txt_file <- sprintf("%s_KM_ucut_%.2f.txt", bfname, cutoff)
# Name of the output CSV file with low/high sample labels
csv_file <- sprintf("%s_KM_ucut_%.2f_labels.csv", bfname, cutoff)

sdat <- read.delim(sfname, header = TRUE, stringsAsFactors = FALSE)

# The input data table
edat <- read.delim(fname, header = TRUE, row.names = 1)
edat <- filter_unique(edat, min_uval)

ids <- intersect(sdat$sample_id,colnames(edat))
sdat <- sdat[sdat$sample_id %in% ids, ]
edat <- edat[, colnames(edat) %in% ids]
sdat <- sdat[order(sdat$sample_id), ]
edat <- edat[, order(colnames(edat))]

# Check for missing and non-numeric elements
row.has.na <- apply( edat, 1, function(x){any(is.na(x) | is.nan(x) |
                                    is.infinite(x))} )
s <- sum(row.has.na)
if(s > 0)
{
    stop("The input data table has missing or non-numeric elements")
}

# Convert expression data table into a matrix
edat <- as.matrix(edat)

# Recalculate the number of features in the table
n_genes <- length(rownames(edat))
n_genes

# The number of samples in the table
n_samples <- length(colnames(edat))
n_samples

sample_labels <- matrix(data = NA, nrow = n_samples, ncol = n_genes)
colnames(sample_labels) <- rownames(edat)
rownames(sample_labels) <- colnames(edat)

results <- matrix(data = NA, nrow = n_genes, ncol = 6)

colnames(results) <- c("CUTOFF","CHI_SQ","LOW_N","HIGH_N","P","FDR_P")
rownames(results) <- rownames(edat)

if(wpdf == TRUE)
{
    pdf(pdf_file)
}

for(i in seq_len(n_genes))
{
    # Create the Kaplan-Meier curves for two groups using the supplied
    # percentile as a cutoff
    labels <- as.numeric(edat[i,] > cutoff) + 1
    fact <- factor(labels)
    low <- sum(fact == 1)
    high <- sum(fact == 2)

    sur <- survdiff(Surv(time = sdat$stime, event = sdat$scens, type = 'right')
                ~ fact, rho = 0)
    p <- pchisq(sur$chisq, 1, lower.tail=FALSE)

    results[i,"CUTOFF"] <- cutoff
    results[i,"CHI_SQ"] <- sur$chisq
    results[i,"LOW_N"] <- low
    results[i,"HIGH_N"] <- high
    results[i,"P"] <- p

    sample_labels[,i] <- labels

    title <- rownames(edat)[i]
    title <- paste(title,"; Cutoff=", sep = "")
    title <- paste(title,sprintf("%G",cutoff), sep = "")
    title <- paste(title,"; P-value=", sep = "")
    title <- paste(title,sprintf("%G",p), sep = "")

    sfit <- survfit(Surv(time=sdat$stime, event = sdat$scens, type = 'right')
            ~ strata(fact))
    plot(sfit, lty=c(1, 2), col = c("royalblue", "magenta"), lwd = 2,
        xlab="Time", ylab="Survival Probability", mark.time=TRUE)
    title(main = title, cex.main = 0.8)
    grid()
    ll <- paste("Low, n=", low, sep = "")
    lh <- paste("High, n=", high, sep = "")
    legend(x = "topright", y = NULL, c(ll, lh), lty=c(1, 2),
        lwd = 2, col=c("royalblue", "magenta"))
}

if(wpdf == TRUE)
{
    dev.off()
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

if(wlabels == TRUE)
{
    df <- as.data.frame(sample_labels)
    setDT(df, keep.rownames=TRUE)
    colnames(df)[1] <- "sample_id"
    write.table(df, file = csv_file, quote = FALSE, row.names = FALSE,
                col.names = TRUE, sep = ",")
}

}
# end function

