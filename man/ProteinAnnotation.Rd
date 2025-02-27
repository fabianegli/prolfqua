% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ProteinAnnotation.R
\name{ProteinAnnotation}
\alias{ProteinAnnotation}
\title{Decorates LFQData with a row annotation and some protein specific functions.}
\description{
Decorates LFQData with a row annotation and some protein specific functions.

Decorates LFQData with a row annotation and some protein specific functions.
}
\examples{

istar <- prolfqua_data('data_ionstar')$filtered()
istar$config <- old2new(istar$config)
data <- istar$data #|> dplyr::filter(protein_Id \%in\% sample(protein_Id, 100))
lfqdata <- LFQData$new(data, istar$config)
pannot <- ProteinAnnotation$new( lfqdata )

pannot$annotate_decoys()
pannot$annotate_contaminants()

stopifnot(pannot$nr_clean(contaminants = FALSE) == 163)
stopifnot(pannot$nr_clean(contaminants = TRUE) == 158)
stopifnot(nrow(pannot$clean(contaminants = FALSE)) == 163)
stopifnot(nrow(pannot$clean(contaminants = TRUE)) == 158)
dd <- pannot$clean()
tmp <- lfqdata$get_subset(dd)
stopifnot(tmp$hierarchy_counts()$protein_Id == 158)

}
\seealso{
Other LFQData: 
\code{\link{LFQDataAggregator}},
\code{\link{LFQDataPlotter}},
\code{\link{LFQDataStats}},
\code{\link{LFQDataSummariser}},
\code{\link{LFQDataToSummarizedExperiment}()},
\code{\link{LFQDataWriter}},
\code{\link{LFQData}}
}
\concept{LFQData}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{row_annot}}{data.frame containing further information}

\item{\code{pID}}{column with protein ids}

\item{\code{description}}{name of column containing descriptions}

\item{\code{ids}}{vector with columns containing addition IDs}

\item{\code{nr_peptides}}{name of columns with the number of peptides}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-ProteinAnnotation-new}{\code{ProteinAnnotation$new()}}
\item \href{#method-ProteinAnnotation-annotate_decoys}{\code{ProteinAnnotation$annotate_decoys()}}
\item \href{#method-ProteinAnnotation-annotate_contaminants}{\code{ProteinAnnotation$annotate_contaminants()}}
\item \href{#method-ProteinAnnotation-nr_clean}{\code{ProteinAnnotation$nr_clean()}}
\item \href{#method-ProteinAnnotation-clean}{\code{ProteinAnnotation$clean()}}
\item \href{#method-ProteinAnnotation-clone}{\code{ProteinAnnotation$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-new"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-new}{}}}
\subsection{Method \code{new()}}{
initialize
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$new(
  lfqdata,
  row_annot,
  description = NULL,
  ids = NULL,
  nr_peptides = "nr_peptides"
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{lfqdata}}{data frame from \code{\link{setup_analysis}}}

\item{\code{row_annot}}{data frame with row annotation. Must have columns matching \code{config$table$hierarchy_keys_depth()}}

\item{\code{description}}{name of column with description}

\item{\code{ids}}{names of columns with additional ID's}

\item{\code{nr_peptides}}{additional peptides}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-annotate_decoys"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-annotate_decoys}{}}}
\subsection{Method \code{annotate_decoys()}}{
annotate rev sequences
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$annotate_decoys(pattern = "REV_")}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{pattern}}{default "REV_"}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-annotate_contaminants"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-annotate_contaminants}{}}}
\subsection{Method \code{annotate_contaminants()}}{
annotate contaminants
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$annotate_contaminants(pattern = "^zz|^CON")}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{pattern}}{default "^zz|^CON"}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-nr_clean"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-nr_clean}{}}}
\subsection{Method \code{nr_clean()}}{
get number of neither contaminants nor decoys
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$nr_clean(contaminants = TRUE, decoys = TRUE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{contaminants}}{remove contaminants}

\item{\code{decoys}}{remove decoys
return number of cleans}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-clean"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-clean}{}}}
\subsection{Method \code{clean()}}{
remove REV and CON sequences
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$clean(contaminants = TRUE, decoys = TRUE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{contaminants}}{remove contaminants}

\item{\code{decoys}}{remove decoys}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ProteinAnnotation-clone"></a>}}
\if{latex}{\out{\hypertarget{method-ProteinAnnotation-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ProteinAnnotation$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
