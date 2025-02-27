% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AnalysisConfiguration.R
\name{hierarchy_counts}
\alias{hierarchy_counts}
\title{Count distinct elements for each level of hierarchy and istope}
\usage{
hierarchy_counts(pdata, config)
}
\arguments{
\item{pdata}{data.frame}

\item{config}{AnalysisConfiguration}
}
\description{
E.g. number of proteins, peptides, precursors in the dataset
}
\examples{

bb <- prolfqua_data('data_ionstar')$filtered()
bb$config <- old2new(bb$config)
stopifnot(nrow(bb$data) == 25780)
config <- bb$config$clone(deep=TRUE)
data <- bb$data

x <- hierarchy_counts(data, config)
x$protein_Id
stopifnot(ncol(x) == length(config$table$hierarchy_keys()) + 1)
# select non existing protein
data <- data |> dplyr::filter( protein_Id == "XYZ")
tmp <- hierarchy_counts(data, config)
stopifnot(nrow(tmp) == 0)
}
\seealso{
Other summary: 
\code{\link{INTERNAL_FUNCTIONS_BY_FAMILY}},
\code{\link{hierarchy_counts_sample}()},
\code{\link{nr_B_in_A_per_sample}()},
\code{\link{summarize_hierarchy}()}
}
\concept{summary}
\keyword{internal}
