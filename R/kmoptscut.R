#' Find optimal stratification cutoffs
#' 
#' For each feature, finds a cutoff that optimally stratifies samples
#' into 2 groups, plots Kaplan-Meier survival curves and observed vs. expected
#' optimization plot. Does not perform the permutation test to estimate the
#' statistical significance of the cutoff.
#'
#' @param obj SummarizedExperiment object with expression-like data
#  and survival data
#' @param bfname a character string (character vector of length 1) that 
#' specifies the base name used to create output file names, which 
#' are created by adding "_KMopt_minf_.2f" and corresponding extension
#' to 'bfname'.
#' @param wdir a character string (character vector of length 1) that 
#' specifies the name of the working directory for the input/output files 
#' (defaults to the current R directory).
#' @param min_fraction numeric value that specifies the minimal
#' fraction of samples in the smaller group (default is 0.1).
#' @param min_up_down numeric value that specifies the minimal
#' number of up/down points on either side of the peak for
#' 'pracma::findpeaks' function (default is 1).
#' @param peak_tolerance numeric value that specifies the maximal
#' difference between in heigth between top peaks.
#' The peak within 'peak_tolerance' closest to the median value is selected.
#' @param min_uval numeric value that specifies the minimal percentage of
#' unique values per feature (default is 50).
#' Features that have less than 'min_uval' percent unique values are
#' excluded from the analysis.
#' @param psort logical value whether to sort the output table by
#' p-values in increasing order (default is FALSE).
#' @param wlabels logical value whether to write a CSV file with
#' low/high (below/above the cutoff) group sample labels (default is TRUE).
#' @param wpdf logical value whether to write a PDF file with plots
#' (default is TRUE).
#' @param verbose logical value whether to print progress (default is TRUE).
#' @return no return value
#'
#' @export
#' @examples
#'
#' # Example with data files included in the package:
#'
#' # Load example gene expression data and survival data for 2 genes
#' # and 93 samples
#' fdat <- system.file("extdata", "example_genes.txt", package = "kmcut")
#' sdat <- system.file("extdata", "survival_data.txt", package = "kmcut")
#' 
#' # Create SummarizedExperiment object
#' se <- create_se_object(efile = fdat, sfile = sdat)
#' 
#' # Search for optimal cutoffs
#' km_opt_scut(obj = se, bfname = "test", wpdf = FALSE)
#'
#' # This will create two output files in the current working directory:
#' # 1) Tab-delimited text file with the results:
#' # "test_KMopt_minf_0.10.txt"
#' # 2) CSV file with low/high sample labels:
#' # "test_KMopt_minf_0.10_labels.csv"

km_opt_scut<-function(
    # SummarizedExperiment object with expression data
    # and survival data
    obj,
    # Base name for the output files
    bfname,
    # Working directory with the input/output files
    wdir = getwd(),
    # If the fraction of samples in the smaller group is below this value,
    # skip this partitioning
    min_fraction = 0.1,
    # Min number of up/down points on either side of the peak
    min_up_down = 1,
    # Peak tolerance
    peak_tolerance = 0.1,
    # Min percentage of unique values in ]0, 100] for each feature
    min_uval = 50,
    # Option to sort the output table by p-values in increasing order
    #(TRUE by default)
    psort = FALSE,
    # Write a CSV file with low/high sample labels (TRUE by default)
    wlabels = TRUE,
    # Write a PDF file with survival curves (TRUE by default)
    wpdf = TRUE,
    # Print progress (TRUE by default)
    verbose = TRUE
)
# begin function
{
setwd(wdir)
  
error <- character(0)

if(is(obj, "SummarizedExperiment") == FALSE)
{
  error<-c(error, "Argument 'obj' is not a SummarizedExperiment object\n")
}
if(min_fraction < 0 || min_fraction >= 0.5)
{
    error<-c(error, "min_fraction must be in [0, 0.5[\n")
}
if(min_up_down <= 0)
{
    error<-c(error, "min_up_down must be greater than 0\n")
}
if(peak_tolerance <= 0)
{
    error<-c(error, "peak_tolerance must be greater than 0\n")
}
if(min_uval <= 0 || min_uval > 100)
{
    error<-c(error, "min_uval must be in ]0, 100]\n")
}

if(length(error) > 0) stop(error)

bfname <- file_path_sans_ext(bfname)
if(length(bfname) == 0)
  stop("The base file name must be 1 or more characters long\n")

# Name of the output PDF file
pdf_file <- sprintf("%s_KMopt_minf_%.2f.pdf",
                    bfname, min_fraction)
# Name of the output TXT file
txt_file <- sprintf("%s_KMopt_minf_%.2f.txt",
                    bfname, min_fraction)
# Name of the output CSV file with low/high sample labels
csv_file <- sprintf("%s_KMopt_minf_%.2f_labels.csv",
                    bfname,min_fraction)

# The survival time data
sdat <- get_sdat(obj)

# The input expression data table
edat <- as.data.frame(assay(obj))
edat <- filter_unique(edat, min_uval)

ids <- intersect(sdat$sample_id,colnames(edat))
sdat <- sdat[sdat$sample_id %in% ids,]
edat <- edat[, colnames(edat) %in% ids]
sdat <- sdat[order(sdat$sample_id), ]
edat <- edat[,order(colnames(edat))]

# Convert expression data table into a matrix
edat <- as.matrix(edat)

# The number of features in the table
n_genes <- length(rownames(edat))

# The number of samples in the table
n_samples <- length(colnames(edat))

sample_labels <- matrix(data = NA, nrow = n_samples, ncol = n_genes)
colnames(sample_labels) <- rownames(edat)
rownames(sample_labels) <- colnames(edat)

results <- matrix(data = NA, nrow = n_genes, ncol = 6)

colnames(results) <- c("CUTOFF","CHI_SQ","LOW_N","HIGH_N","R","P")
rownames(results) <- rownames(edat)

# Go over each feature and find the partitioning with the largest Chi-square
if(wpdf == TRUE)
{
    pdf(pdf_file)
}

for(i in seq_len(n_genes))
{
    if(verbose == TRUE)
    {
        message("Processing ",i," of ",n_genes)
    }

    cutoffs <- numeric()
    chi_values <- numeric()
    ucutoffs <- as.numeric(unique(edat[i,]))
    ucutoffs <- sort(ucutoffs, decreasing = FALSE)

    n_points <- length(ucutoffs)

    if(n_points <= 1)
    {
        next
    }

    for(j in seq_len(n_points))
    {
    cutoff <- ucutoffs[j]
    labels <- as.numeric(as.vector(unlist(edat[i,])) > cutoff) + 1
    fact <- factor(labels)
    low <- sum(fact == 1)
    high <- sum(fact == 2)

    if(low < min_fraction*n_samples || high < min_fraction*n_samples) next

    sur <- survdiff(Surv(time = sdat$stime, event = sdat$scens, type = 'right')
            ~ fact, rho = 0)

    chi_values <- c(chi_values,sur$chisq)
    cutoffs <- c(cutoffs,cutoff)
    }

    # Peak finder
    x <- cutoffs
    y <- chi_values
    peaks <- findpeaks(y, nups = min_up_down, ndowns = min_up_down, npeaks=5,
                sortstr=TRUE,
                minpeakdistance = 1, zero = "+")

    if(is.null(peaks)) next

    # If there are peaks with nearly equal height, select the one that
    #results in the most balanced (closest to the median) split
    tolerance <- peak_tolerance
    best_peaks_i <- peaks[abs(peaks[,1] - peaks[1,1]) < tolerance, 2]
    mid_i <- ceil(length(y)/2)
    if(length(best_peaks_i) > 1)
    {
    vd <- abs(best_peaks_i - mid_i)
    best_i <- best_peaks_i[vd == min(vd)][1]
    }else
    {
    best_i <- best_peaks_i[1]
    }

    # Correlation between the observed and the ideal plots
    # The ideal plot is defined by two lines with intercepts ans
    # Slopes alpha1,alpha2 and beta1,beta2
    max_chi <- y[best_i]
    max_i <- length(y)
    pks <- c( ceil(max_i / 4), ceil(max_i / 2), ceil(3 * max_i / 4) )
    vd <- abs(pks - best_i)
    pksi <- pks[vd == min(vd)]
    if(length(pksi) == 1)
    {
    id_peak <- pksi
    }else
    {
    id_peak <- ceil(max_i / 2)
    }
    beta1 <- max_chi / (id_peak - 1)
    alpha1 <- -beta1
    beta2 <- max_chi / (id_peak - max_i)
    alpha2 <- -beta2 * max_i
    ideal_y <- fit_ideal_linear_plot(alpha1,beta1,alpha2,beta2,id_peak,max_i)

    r <- cor(y, ideal_y, method = "spearman", use ="na.or.complete")
    best_p <- pchisq(max_chi, 1, lower.tail=FALSE)

    # Create the Kaplan-Meier curvs for two groups using the best cutoff
    best_cutoff <- x[best_i]
    labels <- as.numeric(edat[i,] > best_cutoff) + 1
    fact <- factor(labels)
    best_low <- sum(fact == 1)
    best_high <- sum(fact == 2)
    if(wlabels == TRUE)
    {
        sample_labels[,i] <- labels
    }
    results[i,"CUTOFF"] <- best_cutoff
    results[i,"CHI_SQ"] <- max_chi
    results[i,"LOW_N"] <- best_low
    results[i,"HIGH_N"] <- best_high
    results[i,"R"] <- r
    results[i,"P"] <- best_p

    plot(x, y, type="b", col="navy", xlab="Cutoff", ylab="Chi-sq",
        ylim=c(0, max_chi+1), lwd = 2)
    grid()
    title(main = paste(rownames(edat)[i],"; R=", round(r, digits = 3),
            sep = ""), cex.main = 0.8)
    points(x[best_i], y[best_i], pch=20, col="red", cex = 2)
    points(x, ideal_y, pch = 24, col = "green",type="b")

    title <- rownames(edat)[i]
    title <- paste(title,"; Cutoff=", sep = "")
    title <- paste(title, sprintf("%G",best_cutoff), sep = "")
    title <- paste(title,"; P=", sprintf("%G",best_p), sep = "")

    sfit <- survfit(Surv(time=sdat$stime, event = sdat$scens, type = 'right')
                ~ strata(fact))
    plot(sfit, lty=c(1, 2), col = c("royalblue", "magenta"), lwd = 2,
        xlab="Time", ylab="Survival Probability", mark.time=TRUE)
    grid()
    title(main = title, cex.main = 0.8)
    ll <- paste("Low, n=", best_low, sep = "")
    lh <- paste("High, n=", best_high, sep = "")
    legend(x = "topright", y = NULL, c(ll, lh), lty=c(1, 2),
        lwd = 2, col=c("royalblue", "magenta"))
}

if(wpdf == TRUE)
{
    dev.off()
}

if(length(rownames(results)) > 1 && psort == TRUE)
{
    results <- results[order(results[,"P"]),]
}

# Convert row names into a column
df <- as.data.frame(results)
df <- cbind(rownames(df), df)
colnames(df)[1] <- "tracking_id"

write.table(df, file = txt_file, quote = FALSE, row.names = FALSE,
    col.names = TRUE, sep = "\t")

if(wlabels == TRUE)
{
    df <- as.data.frame(sample_labels)
    df <- cbind(rownames(df), df)
    colnames(df)[1] <- "sample_id"
    write.table(df, file = csv_file, quote = FALSE, row.names = FALSE,
        col.names = TRUE, sep = ",")
}

}
# end function
