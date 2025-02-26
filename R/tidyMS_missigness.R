# Functions - Missigness ----

#' compute missingness statistics per hierarchy and factor level
#' @param pdata data.frame
#' @param config AnalysisConfiguration
#' @param factors factor to include (default up to factor depth)
#' @param hierarchy hierarchy to include (default up to hierarchy depth)
#' @param workIntensity work intensity column
#' @export
#' @keywords internal
#' @examples
#'
#'
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config)
#' data <- bb$data
#'
#' configur$parameter$qVal_individual_threshold <- 0.01
#' xx <- prolfqua::remove_large_QValues(data,
#'    configur)
#' xx <- complete_cases(xx, configur)
#' x <- interaction_missing_stats(xx, configur)$data |> dplyr::arrange(desc(nrNAs))
#'
#' stopifnot(nrow(x) == 5540)
#' stopifnot(sum(is.na(x$meanArea)) == 206)
#' stopifnot(length(unique(x$protein_Id)) == 162)
#'
#' tmp <- interaction_missing_stats(xx, configur,
#'  factors= character(),
#'   hierarchy = configur$table$hierarchy_keys()[1])$data
#' stopifnot(nrow(tmp) == 162)
#'
#' tmp <- interaction_missing_stats(xx, configur,
#'   hierarchy = configur$table$hierarchy_keys()[1])$data
#' stopifnot(sum(is.na(tmp$nrMeasured))==0)
#' tmp
#'
#' interaction_missing_stats(xx, configur, factors = NULL)
#'
interaction_missing_stats <- function(pdata,
                                      config,
                                      factors = config$table$factor_keys_depth(),
                                      hierarchy = config$table$hierarchy_keys(),
                                      workIntensity = config$table$get_response())
{
  pdata <- complete_cases(pdata, config)
  table <- config$table
  missingPrec <- pdata |> group_by_at(c(factors,
                                        hierarchy,
                                        table$isotopeLabel
  ))
  missingPrec <- missingPrec |>
    dplyr::summarize(nrReplicates = n(),
                     nrNAs = sum(is.na(!!sym(workIntensity))),
                     meanArea = mean(!!sym(workIntensity), na.rm = TRUE),
                     medianArea = median(!!sym(workIntensity), na.rm = TRUE)) |>
    mutate(nrMeasured = .data$nrReplicates - .data$nrNAs) |> dplyr::ungroup()
  return(list(data = missingPrec,
              summaries = c("nrReplicates","nrNAs","nrMeasured","meanArea", "medianArea")))
}

#' Compute interaction averages and
#' impute data using mean of lowest 0.1 (default)
#'
#' used in Acetylation project p2916
#'
#' @param pdata data.frame
#' @param config AnalysisConfiguration
#' @param factors factor to include (default up to factor depth)
#' @param probs quantile to take average from (default 0.1)
#' @param global global min value
#' @return function with parameter `value`
#' `c("long", "nrReplicates", "nrMeasured", "meanArea", "imputed", "allWide", "all")`
#' @export
#' @keywords internal
#' @return function
#' @examples
#'
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config)
#' data <- bb$data
#' configur$parameter$qVal_individual_threshold <- 0.01
#'
#' xx <- prolfqua::remove_large_QValues(data, configur)
#' xx <- complete_cases(xx, configur)
#' nrPepTimesDilution <- length(unique(paste0(xx$protein_Id, xx$peptide_Id))) *
#'     length(unique(xx$dilution.))
#' tmp <- interaction_missing_stats(xx, configur)
#' stopifnot(nrow(tmp$data) == nrPepTimesDilution)
#' fun <- .missigness_impute_interactions(xx, configur)
#'
#' long <- fun("long")
#' nrow(long) == nrPepTimesDilution
#' alldata <- fun("all")
#' stopifnot(length(names(alldata)) == 5)
#'
#' imputed <- fun("imputed")
#' stopifnot(nrow(imputed) == length(unique(paste0(xx$protein_Id, xx$peptide_Id))))
#' missing <- fun("nrMeasured")
#' stopifnot(nrow(missing) == length(unique(paste0(xx$protein_Id, xx$peptide_Id))))
#'
#'  meanArea <- fun("mean")
#' stopifnot(nrow(meanArea) == length(unique(paste0(xx$protein_Id, xx$peptide_Id))))
#'  print(sum(is.na(meanArea$mean.dilution.a)))
#'  stopifnot(sum(is.na(imputed$mean.imp.dilution.a))==0)
#'
.missigness_impute_interactions <- function(pdata,
                                            config,
                                            factors = config$table$factor_keys_depth(),
                                            probs = 0.1,
                                            global = TRUE){
  mstats <- interaction_missing_stats(pdata, config, factors = factors)
  x_summaries <- mstats$summaries
  mstats <- mstats$data
  mstats <- make_interaction_column(mstats, factors, sep = ":")


  lowerMean <- function(meanArea, probs = probs){
    meanAreaNotNA <- na.omit(meanArea)
    small10 <- meanAreaNotNA[meanAreaNotNA < quantile(meanAreaNotNA, probs = probs)]
    meanArea[is.na(meanArea)] <- mean(small10)
    return(meanArea)
  }

  if (!global) {
    mstats <- mstats |>
      group_by(interaction) |>
      mutate(imputed = lowerMean(.data$meanArea,probs = probs))
  }else{
    mstats <- mstats |>
      mutate(imputed = lowerMean(.data$meanArea,probs = probs))

  }

  res_fun <- function(value = c("long",
                                "nrReplicates",
                                "nrMeasured",
                                "meanArea",
                                "imputed",
                                "allWide",
                                "all" ),
                      add.prefix = TRUE,
                      DEBUG = FALSE){
    value <- match.arg(value)
    if (DEBUG) {
      return(list(value = value, long = mstats , config = config ))
    }

    if (value == "long") {
      return(mstats)
    }else{
      mstats <- mstats |> dplyr::select(-one_of(factors))

      pid <- config$table$hierarchy_keys_depth()
      nrReplicates <- mstats |>
        dplyr::select( -one_of(c(setdiff(x_summaries,"nrReplicates"),"imputed") )) |>
        tidyr::spread(interaction, nrReplicates, sep = ".nrReplicates.") |>
        arrange(!!!syms(pid)) |>
        dplyr::ungroup()
      nrMeasured <- mstats |> dplyr::select(-one_of(c(setdiff(x_summaries,"nrMeasured"),"imputed" ) )) |>
        tidyr::spread(interaction, nrMeasured, sep = ".nrMeasured.") |>
        arrange(!!!syms(pid)) |> dplyr::ungroup()

      meanArea <- mstats |> dplyr::select(-one_of(c(setdiff(x_summaries,"meanArea"),"imputed" ) )) |>
        tidyr::spread(interaction, meanArea, sep = ".meanArea.") |>
        arrange(!!!syms(pid)) |> dplyr::ungroup()

      meanAreaImputed <- mstats |> dplyr::select(-one_of(setdiff(x_summaries,"imputed" ) )) |>
        tidyr::spread(interaction, .data$imputed, sep = ".imputed.") |>
        arrange(!!!syms(pid)) |> dplyr::ungroup()

      allTables <- list(meanArea = meanArea,
                        nrMeasured = nrMeasured,
                        nrReplicates = nrReplicates,
                        meanAreaImputed = meanAreaImputed)

      if (value == "all") {
        allTables[["long"]] <- mstats
        return(allTables)
      }else if (value == "allWide") {
        return(purrr::reduce(allTables, inner_join))
      }else if (value == "nrReplicates") {
        srepl <- if (add.prefix) {"nrRep."}else{""}
        colnames(nrReplicates) <- gsub("interaction.nrReplicates.", srepl ,colnames(nrReplicates))
        nrReplicates <- tibble::add_column( nrReplicates, "value" = value, .before = 1)
        return(nrReplicates)
      }else if (value == "nrMeasured") {
        srepl <- if (add.prefix) {"nrMeas."}else{""}
        colnames(nrMeasured) <- gsub("interaction.nrMeasured.", srepl ,colnames(nrMeasured))
        nrMeasured <- tibble::add_column( nrMeasured, "value" = value, .before = 1)
        return(nrMeasured)
      }else if (value == "meanArea") {
        srepl <- if (add.prefix) {"mean."}else{""}
        colnames(meanArea) <- gsub("interaction.meanArea.", srepl ,colnames(meanArea))
        meanArea <- tibble::add_column( meanArea, "value" = value, .before = 1)
        return(meanArea)
      }else if (value == "imputed") {
        srepl <- if (add.prefix) {"mean.imp."}else{""}
        colnames(meanAreaImputed) <- gsub("interaction.imputed.", srepl ,colnames(meanAreaImputed))
        meanAreaImputed <- tibble::add_column( meanAreaImputed, "value" = value, .before = 1)
        return(meanAreaImputed)
      }
    }
  }

  #  nrMeasured |> dplyr::select(starts_with("interaction")) -> nrMeasuredM
  #  nrReplicates |> dplyr::select(starts_with("interaction")) -> nrReplicatesM
  return(res_fun)
}


#' compute per group averages and impute values
#' should generalize at some stage
#'
#' @param pdata data.frame
#' @param config AnalysisConfiguration
#' @param probs quantile to take average from (default 0.1)
#' @param value use default
#' @param add.prefix use default
#'
#' @export
#' @keywords internal
#' @family imputation
#' @examples
#'
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config)
#' data <- bb$data
#' xx <- complete_cases(data, configur)
#'
#' res <- missigness_impute_factors_interactions(xx, configur)
#' res <- missigness_impute_factors_interactions(xx, configur, value = "imputed")
#' res <- missigness_impute_factors_interactions(xx, configur, value = "nrMeasured")
#' long <- missigness_impute_factors_interactions(xx, configur, value = "long")
#' dim(long)
#'
missigness_impute_factors_interactions <-
  function(pdata,
           config,
           probs = 0.03,
           value = c("long", "nrReplicates", "nrMeasured", "meanArea", "imputed"),
           add.prefix = FALSE,
           global = TRUE)
  {
    value <- match.arg(value)
    fac_fun <- list()
    fac_fun[["interaction"]] <- .missigness_impute_interactions(
      pdata,
      config,
      probs = probs,
      global = global)
    if (config$table$factorDepth > 1 ) { # if 1 only then done
      for (factor in config$table$factor_keys_depth()) {
        fac_fun[[factor]] <- .missigness_impute_interactions(
          pdata,
          config,
          factors = factor,
          probs = probs,
          global = global)
      }
    }

    fac_res <- vector(mode = "list", length = length(fac_fun))
    names(fac_res) <- names(fac_fun)
    for (fun_name in names(fac_fun)) {
      fac_res[[fun_name]] <- fac_fun[[fun_name]](value, add.prefix = add.prefix)
    }
    if(value == "long"){
      intfact <- dplyr::bind_rows(fac_res)
    } else {
      intfact <- purrr::reduce(fac_res,
                               dplyr::inner_join,
                               by = c(config$table$hierarchy_keys(),
                                      config$table$isotopeLabel, "value"))

    }
    return(dplyr::ungroup(intfact))
  }



#' Compute fold changes given Contrasts
#'
#' @keywords internal
#' @family imputation
#' @export
#'
#' @examples
#'
#'
#' bb <- prolfqua_data('data_ionstar')$normalized()
#'
#' configur <- old2new(bb$config)
#' data <- bb$data
#'
#' Contrasts <- c("dilution.b-a" = "dilution.b - dilution.a", "dilution.c-e" = "dilution.c - dilution.e")
#' mean <- missigness_impute_factors_interactions(data, configur, value = "meanArea" )
#' mean <- get_contrast(mean, configur$table$hierarchy_keys(), Contrasts)
#' meanProt <- aggregate_contrast(mean,  subject_Id =  configur$table$hierarchy_keys_depth())
#'
#' imputed <- missigness_impute_factors_interactions(data, configur, value = "imputed" )
#' imputed <- get_contrast(imputed, configur$table$hierarchy_keys(), Contrasts)
#'
#' imputedProt <- aggregate_contrast(imputed,  subject_Id =  configur$table$hierarchy_keys_depth())
#' plot(imputedProt$group_1 - imputedProt$group_2, imputedProt$estimate_median)
#' abline(c(0,1), col=2, pch = "*")
#' dim(meanProt)
#' sum(is.na(meanProt$estimate_median)) == 0
#' sum(is.na(imputedProt$estimate_median)) == 0
#' plot(meanProt$estimate_median - imputedProt$estimate_median )
#'
aggregate_contrast <- function(
    data,
    subject_Id ,
    agg_func = list(median = function(x){ stats::median(x, na.rm = TRUE) },
                    mad = function(x){ stats::mad(x, na.rm = TRUE)} ),
    contrast = "contrast")
{
  grouping_columns <- c(contrast, subject_Id, "group_1_name","group_2_name")
  dataG <- data |>
    group_by(!!!syms(grouping_columns))

  resN <- dataG |> dplyr::summarise(n = n(), .groups = "drop")
  resE <- dataG |> dplyr::summarise(across(.data$estimate,
                                           agg_func
  ), .groups = "drop")
  agg_func_c <- agg_func[1]
  resC <- dataG |> dplyr::summarise(across(all_of(c("group_1", "group_2")),
                                           agg_func_c,
                                           .names = "{col}"
  ),
  .groups = "drop")
  res <- Reduce(function(x,y){ dplyr::full_join(x , y , by = grouping_columns)},
                list(resN,resE,resC) )
  return(res)

}

.get_sides <- function(contrast) {
  getAST <- function(ee) purrr::map_if(as.list(ee), is.call, getAST)

  ast_list <- getAST(rlang::parse_expr(contrast))
  ast_array <- array(as.character(unlist(ast_list)))
  ast_array <- gsub("`","",ast_array)
  return(ast_array)
}

#' Compute fold changes given Contrasts
#' @keywords internal
#' @family imputation
#' @param data data.frame
#' @param data hierarchy_keys of Analysis Configuration
#' @param contrasts list of contrasts to compute
#' @export
#' @examples
#'
#'
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config)
#' data <- bb$data
#' data <- complete_cases(data, configur)
#'
#' Contrasts <- c("aVSe" = "dilution.a - dilution.e","aVSb" = "dilution.a - dilution.b" )
#' message("missigness_impute_factors_interactions : imputed")
#' xx <- missigness_impute_factors_interactions(data, configur, value = "nrMeasured" )
#' imputed <- get_contrast(xx, configur$table$hierarchy_keys(), Contrasts)
#'
#' xx <- missigness_impute_factors_interactions(data, configur, value = "imputed" )
#'
#' imputed <- get_contrast(xx, configur$table$hierarchy_keys(), Contrasts)
#' head(imputed)
#'
get_contrast <- function(data,
                         hierarchy_keys,
                         contrasts)
{


  for (i in seq_along(contrasts)) {
    message(names(contrasts)[i], "=", contrasts[i],"\n")
    data <- dplyr::mutate(data, !!names(contrasts)[i] := !!rlang::parse_expr(contrasts[i]))
  }
  res <- vector(mode = "list", length(contrasts))
  names(res) <- names(contrasts)
  for (i in seq_along(contrasts)) {
    sides <- .get_sides(contrasts[i] )
    sides <- intersect(sides,colnames(data))

    df  <- dplyr::select(data ,
                         c( hierarchy_keys, group_1 = sides[1], group_2 = sides[2], estimate = names(contrasts)[i]))

    df$group_1_name <- sides[1]
    df$group_2_name <- sides[2]
    df$contrast <-  names(contrasts)[i]

    res[[names(contrasts)[i]]] <- df
  }
  res <- dplyr::bind_rows(res)

  return(dplyr::ungroup(res))
}



#' compute contrasts based on peptide fold changes
#'
#' Computes median of fold peptide fold change to obtain protein fold change.
#' peptide fold change is computed based on the average of intensities in the conditions.
#'
#'
#' @param data data.frame
#' @param config AnalysisConfiguration
#' @param contrast list of contrasts
#' @param present estimate lod from group with default 1 present values.
#' @keywords internal
#' @family missingness
#' @family modelling
#' @return data.frame with name of contrast, ID, number of observations (if with aggregation), median, mad, and avgAbd
#' @export
#' @examples
#'
#'
#' library(prolfqua)
#' bb <- prolfqua_data('data_ionstar')$normalized()
#' configur <- old2new(bb$config)
#' data <- bb$data
#' configur$parameter$qVal_individual_threshold <- 0.01
#' data <- prolfqua::remove_large_QValues(data, configur)
#' data <- complete_cases(data, configur)
#'
#' Contrasts <- c("dilution.b-a" = "dilution.b - dilution.a", "dilution.c-e" = "dilution.c - dilution.e")
#' #debug(get_imputed_contrasts)
#' res <- get_imputed_contrasts(data, configur, Contrasts)
#'
#' config <- configur
#' contrasts <- Contrasts
#' imputed <- missigness_impute_factors_interactions(data, config, value = "imputed" )
#' imputed <- get_contrast(imputed, config$table$hierarchy_keys(), contrasts)
#' imputedProt <- aggregate_contrast(imputed,  subject_Id =  config$table$hierarchy_keys_depth())
#'
get_imputed_contrasts <- function(pepIntensity,
                                  config,
                                  Contr,
                                  present = 1,
                                  global = TRUE){
  if (!present > 0) {
    stop("At least 1 observation in interaction to infer LOD.")
  }
  long <- missigness_impute_factors_interactions(pepIntensity, config, value = "long" )
  LOD <- long |> filter(nrNAs == nrReplicates - present) |> pull(meanArea) |> median(na.rm=TRUE)

  long <- tidyr::complete(long, tidyr::nesting(!!!syms(config$table$hierarchy_keys())), interaction)
  long <- long |> mutate(imputed_b = ifelse(is.na(meanArea), LOD, meanArea))

  lt <- long
  imp <- lt |> pivot_wider(id_cols = config$table$hierarchy_keys(), names_from = interaction, values_from = imputed_b)
  lt <- lt |> mutate(is_missing = ifelse( nrNAs == nrReplicates , 1 , 0) )
  nr <- lt |> pivot_wider(id_cols = config$table$hierarchy_keys(), names_from = interaction, values_from = is_missing)

  imputed <- get_contrast(ungroup(imp), config$table$hierarchy_keys(), Contr)
  nrs <- get_contrast(ungroup(nr),  config$table$hierarchy_keys(), Contr)

  nrs <- nrs |> select(all_of(c(config$table$hierarchy_keys(),"contrast", "estimate" )))
  nrs <- nrs |> rename(indic = estimate)
  imputed <- inner_join(imputed, nrs)
  imputed2 <- imputed |> mutate(estimate = ifelse(indic < 0 & estimate < 0, 0, estimate))
  imputed2 <- imputed2 |> mutate(estimate = ifelse(indic > 0 & estimate > 0, 0, estimate))

  imputedProt <- aggregate_contrast(ungroup(imputed2),  subject_Id =  config$table$hierarchy_keys_depth())
  imputedProt$avgAbd <- (imputedProt$group_1 + imputedProt$group_2)/2
  imputedProt$group_1_name <- NULL
  imputedProt$group_2_name <- NULL
  imputedProt$group_1 <- NULL
  imputedProt$group_2 <- NULL
  return(imputedProt)
}

#' Histogram summarizing missigness
#' @export
#' @keywords internal
#' @family plotting
#' @family imputation
#' @examples
#'
#' bb <- prolfqua_data('data_ionstar')
#' configur <- old2new(bb$config)
#' data <- bb$data
#' xx <- complete_cases(data, configur)
#' missigness_histogram(xx, configur)
#'
#' missingPrec <- interaction_missing_stats(xx, configur)
#'
#' bx <- prolfqua_data('data_ionstar')$normalized()
#' configur <- old2new(bx$config)
#' data <- bx$data
#' data <- complete_cases(data, configur)
#' missingPrecNorm <- interaction_missing_stats(data, configur)
#'
#' missigness_histogram(data, configur, showempty=FALSE)
#' missigness_histogram(data, configur, showempty=TRUE)
#'
missigness_histogram <- function(x,
                                 config,
                                 showempty = FALSE,
                                 factors = config$table$factor_keys_depth(),
                                 alpha = 0.1){
  table <- config$table
  missingPrec <- interaction_missing_stats(x, config , factors)$data
  missingPrec <- missingPrec |>
    dplyr::ungroup() |> dplyr::mutate(nrNAs = as.factor(.data$nrNAs))

  if (showempty) {
    if (config$table$is_response_transformed) {
      missingPrec <- missingPrec |>
        dplyr::mutate(meanArea = ifelse(is.na(.data$meanArea), min(.data$meanArea, na.rm = TRUE) - 1,
                                        .data$meanArea))
    }else{
      missingPrec <- missingPrec |>
        dplyr::mutate(meanArea = ifelse(is.na(.data$meanArea),min(.data$meanArea, na.rm = TRUE) - 20,.data$meanArea))
    }

  }

  factors <- table$factor_keys_depth()
  formula <- paste(table$isotopeLabel, "~", paste(factors, collapse = "+"))
  message(formula)
  meanarea <- paste0("mean_", config$table$get_response())
  missingPrec <- dplyr::rename(missingPrec, !!sym(meanarea) := .data$meanArea )

  p <- ggplot2::ggplot(missingPrec, ggplot2::aes(x = !!sym(meanarea), fill = .data$nrNAs, colour = .data$nrNAs)) +
    ggplot2::geom_density(alpha = alpha, position = "identity") +
    ggplot2::facet_grid(as.formula(formula)) +
    ggplot2::theme(axis.text.x = element_text(angle = 90, hjust = 1))

  if (!config$table$is_response_transformed) {
    p <- p + ggplot2::scale_x_log10()
  }
  p
}

#' cumulative sums of missing
#' @export
#' @keywords internal
#' @family plotting
#' @family imputation
#' @examples
#'
#'
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config$clone(deep=TRUE))
#' data <- bb$data
#'
#' res <- missingness_per_condition_cumsum(data,configur)
#' stopifnot("ggplot" %in% class(res$figure))
#' print(res$figure)
#' res$data
missingness_per_condition_cumsum <- function(x,
                                             config,
                                             factors = config$table$factor_keys_depth()){
  table <- config$table
  missingPrec <- interaction_missing_stats(x, config,factors)$data

  xx <- missingPrec |> group_by_at(c(table$isotopeLabel, factors,"nrNAs","nrReplicates")) |>
    dplyr::summarize(nrTransitions = n())

  xxcs <- xx |> group_by_at( c(table$isotopeLabel,factors)) |> arrange(.data$nrNAs) |>
    dplyr::mutate(cumulative_sum = cumsum(.data$nrTransitions))
  res <- xxcs  |> dplyr::select(-.data$nrTransitions)

  formula <- paste(table$isotopeLabel, "~", paste(factors, collapse = "+"))
  message(formula)

  nudgeval = mean(res$cumulative_sum) * 0.05
  p <- ggplot(res, aes(x = .data$nrNAs, y = .data$cumulative_sum)) +
    geom_bar(stat = "identity", color = "black", fill = "white") +
    geom_text(aes(label = .data$cumulative_sum), nudge_y = nudgeval, angle = -45) +
    facet_grid(as.formula(formula))

  res <- res |> tidyr::pivot_wider(names_from = "nrNAs", values_from = "cumulative_sum")
  return(list(data = res, figure = p))
}

#' Summarize missing in condtion as barplot
#' @export
#' @keywords internal
#' @family plotting
#' @family imputation
#' @examples
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config$clone(deep=TRUE))
#' data <- bb$data
#'
#' res <- missingness_per_condition(data, configur)
#' stopifnot(c(5,8) == dim(res$data))
#' stopifnot("ggplot" %in% class(res$figure))
#' print(res$figure)
#'
missingness_per_condition <- function(x, config, factors = config$table$factor_keys_depth()){
  table <- config$table
  missingPrec <- interaction_missing_stats(x, config, factors)$data
  hierarchyKey <- tail(config$table$hierarchy_keys(),1)
  hierarchyKey <- paste0("nr_",hierarchyKey)
  xx <- missingPrec |> group_by_at(c(table$isotopeLabel,
                                     factors,"nrNAs","nrReplicates")) |>
    dplyr::summarize( !!sym(hierarchyKey) := n())

  formula <- paste(table$isotopeLabel, "~", paste(factors, collapse = "+"))
  #message(formula)

  nudgeval = max(xx[[hierarchyKey]]) * 0.05

  p <- ggplot(xx, aes_string(x = "nrNAs", y = hierarchyKey)) +
    geom_bar(stat = "identity", color = "black", fill = "white") +
    geom_text(aes(label = !!sym(hierarchyKey)), nudge_y = nudgeval, angle = 45) +
    facet_grid(as.formula(formula))
  xx <- tidyr::spread(xx, "nrNAs",hierarchyKey)

  return(list(data = xx ,figure = p))
}


#' UpSetR plot from interaction_missing_stats
#'
#' @export
#' @keywords internal
#' @family plotting
#' @family imputation
#' @param tr if less than tr observations in condition then missing
#' @examples
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config$clone(deep=TRUE))
#' data <- bb$data
#' #debug(UpSet_interaction_missing_stats)
#' pups <- UpSet_interaction_missing_stats(data, configur)
#' #UpSetR::upset(pups$data, order.by = "freq", nsets = pups$nsets)
UpSet_interaction_missing_stats <- function(data, cf, tr = 2) {
  tmp <- prolfqua::interaction_missing_stats(data, cf)
  nrMiss <- tmp$data |> tidyr::pivot_wider(id_cols = cf$table$hierarchy_keys(),
                                           names_from = cf$table$factor_keys_depth(),
                                           values_from = !!rlang::sym("nrMeasured"))

  hl <- length(cf$table$hierarchy_keys())
  nrMiss[,-(1:hl)][nrMiss[,-(1:hl)] < tr] <- 0
  nrMiss[,-(1:hl)][nrMiss[,-(1:hl)] >= tr] <- 1
  return(list(data = as.data.frame(nrMiss), nsets = ncol(nrMiss) - length(cf$table$hierarchy_keys())))
}

#' prepare dataframe for UpSetR plot for all samples
#'
#' @export
#' @keywords internal
#' @family plotting
#' @family imputation
#' @examples
#' bb <- prolfqua_data('data_ionstar')$filtered()
#' stopifnot(nrow(bb$data) == 25780)
#' configur <- old2new(bb$config$clone(deep=TRUE))
#' data <- bb$data
#' pups <- UpSet_missing_stats(data, configur)
#' #UpSetR::upset(pups$data , order.by = "freq", nsets = pups$nsets)
UpSet_missing_stats <- function(data, config){
  data <- prolfqua::complete_cases(data, config)
  responseName <- config$table$get_response()
  data <- data |> dplyr::mutate(isThere =
                                  dplyr::case_when(
                                    !is.na(!!rlang::sym(responseName)) ~ 1,
                                    TRUE ~ 0
                                  )
  )
  pups2 <- data |> tidyr::pivot_wider(id_cols = config$table$hierarchy_keys(),
                                      names_from = config$table$sampleName,
                                      values_from = !!rlang::sym("isThere"))
  #colnames(pups2) <- make.names(colnames(pups2))
  res <- list(data = as.data.frame(pups2), nsets = ncol(pups2) - length(config$table$hierarchy_keys()) )
  return(res)
}

