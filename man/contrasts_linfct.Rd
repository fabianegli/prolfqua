% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tidyMS_R6_Modelling.R
\name{contrasts_linfct}
\alias{contrasts_linfct}
\title{compute group averages}
\usage{
contrasts_linfct(
  models,
  linfct,
  subject_Id = "protein_Id",
  contrastfun = prolfqua::my_contest
)
}
\description{
used in p2621, p2109
}
\examples{
data("data_modellingResult_A")
modelSummary_A <- data_modellingResult_A
m <- get_complete_model_fit(modelSummary_A$modelProtein)

factor_contrasts <- linfct_factors_contrasts( m$linear_model[[1]])
factor_contrasts
class(factor_contrasts)
factor_levelContrasts <- contrasts_linfct( m,
        factor_contrasts,
        subject_Id = "Compound",
        contrastfun = prolfqua::my_contrast_V2)

#usethis::use_data(factor_levelContrasts, overwrite = TRUE)
data_models_interaction <- prolfqua_data('data_models_interaction')
m <- get_complete_model_fit(data_models_interaction$modelProtein)
data_interact_model <- m$linear_model[[1]]
factor_contrasts <- linfct_factors_contrasts( m$linear_model[[1]] )

factor_levelContrasts <- contrasts_linfct( m,
                           factor_contrasts,
                       subject_Id = "protein_Id")
m$linear_model[[1]]
my_contest(m$linear_model[[1]],factor_contrasts )

plot(factor_levelContrasts$df, factor_levelContrasts$df.residual.model )
abline(c(0,1))
plot(factor_levelContrasts$df.residual.model , factor_levelContrasts$df - factor_levelContrasts$df.residual.model )

}
\keyword{internal}
