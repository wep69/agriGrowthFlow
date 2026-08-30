.agf_boot_validate_R <- function(R) {
  if (!is.numeric(R) || length(R) != 1L || is.na(R) || !is.finite(R) || R < 20) {
    stop("`R` must be a single finite number of at least 20 bootstrap replicates.", call. = FALSE)
  }
  as.integer(R)
}

.agf_boot_method <- function(method, d = NULL) {
  method <- match.arg(method, c("auto", "case", "cluster", "residual", "parametric", "wild", "cluster_wild"))
  if (!identical(method, "auto")) return(method)
  if (!is.null(d) && ".unit" %in% names(d)) {
    units <- unique(as.character(d$.unit))
    if (length(units) > 1L && any(table(d$.unit) > 1L)) return("cluster")
  }
  "case"
}

.agf_boot_attach_attrs <- function(d, source) {
  for (nm in c("time_name", "response_name", "group_name", "unit_name", "sampling", "aggregation")) {
    attr(d, nm) <- attr(source, nm)
  }
  d
}

.agf_boot_cluster_sample <- function(d) {
  units <- unique(as.character(d$.unit))
  units <- units[nzchar(units)]
  if (length(units) < 2L || identical(units, ".all")) {
    stop("Cluster bootstrap requires at least two persistent experimental units.", call. = FALSE)
  }
  draw <- sample(units, length(units), replace = TRUE)
  pieces <- lapply(seq_along(draw), function(i) {
    z <- d[as.character(d$.unit) == draw[[i]], , drop = FALSE]
    z$.unit <- paste0(".boot_unit_", i)
    z
  })
  out <- do.call(rbind, pieces)
  rownames(out) <- NULL
  .agf_boot_attach_attrs(out, d)
}

.agf_boot_resample_data <- function(fit, method, wild_weights = c("rademacher", "mammen")) {
  d <- fit$data
  method <- .agf_boot_method(method, d)
  wild_weights <- match.arg(wild_weights)
  n <- nrow(d)
  out <- d

  if (identical(method, "case")) {
    idx <- sample.int(n, n, replace = TRUE)
    out <- d[idx, , drop = FALSE]
    out$.unit <- paste0(out$.unit, "_row", seq_len(nrow(out)))
  } else if (identical(method, "cluster")) {
    out <- .agf_boot_cluster_sample(d)
  } else if (identical(method, "residual")) {
    e <- fit$residuals - mean(fit$residuals)
    out$.y <- fit$fitted + sample(e, n, replace = TRUE)
  } else if (identical(method, "parametric")) {
    out$.y <- fit$fitted + stats::rnorm(n, mean = 0, sd = fit$sigma)
  } else if (identical(method, "wild")) {
    e <- fit$residuals - mean(fit$residuals)
    if (identical(wild_weights, "mammen")) {
      a <- (1 - sqrt(5)) / 2
      b <- (1 + sqrt(5)) / 2
      pb <- (sqrt(5) - 1) / (2 * sqrt(5))
      w <- ifelse(stats::runif(n) < pb, a, b)
    } else {
      w <- sample(c(-1, 1), n, replace = TRUE)
    }
    out$.y <- fit$fitted + e * w
  } else if (identical(method, "cluster_wild")) {
    units <- unique(as.character(d$.unit))
    if (length(units) < 2L || identical(units, ".all")) {
      stop("Cluster wild bootstrap requires at least two persistent experimental units.", call. = FALSE)
    }
    e <- fit$residuals - mean(fit$residuals)
    if (identical(wild_weights, "mammen")) {
      a <- (1 - sqrt(5)) / 2
      b <- (1 + sqrt(5)) / 2
      pb <- (sqrt(5) - 1) / (2 * sqrt(5))
      wu <- ifelse(stats::runif(length(units)) < pb, a, b)
    } else {
      wu <- sample(c(-1, 1), length(units), replace = TRUE)
    }
    names(wu) <- units
    out$.y <- fit$fitted + e * unname(wu[as.character(d$.unit)])
  }

  out <- out[order(out$.group, out$.unit, out$.t), , drop = FALSE]
  .agf_boot_attach_attrs(out, d)
}

.agf_boot_numeric_traits <- function(fit) {
  z <- growth_traits(fit)
  z <- z[1L, , drop = FALSE]
  keep <- vapply(z, is.numeric, logical(1))
  z[keep]
}

.agf_boot_refit <- function(original, d, n_start = 1L, engine = NULL, control = list()) {
  if (is.null(engine)) engine <- original$engine
  start <- original$coefficients
  tryCatch(
    .agf_fit_one(
      d,
      model = original$model,
      start = start,
      n_start = n_start,
      seed = NULL,
      engine = engine,
      control = control
    ),
    error = function(e) structure(list(error = conditionMessage(e)), class = "agri_growth_boot_failure")
  )
}

#' Bootstrap uncertainty for a fitted parametric growth curve
#'
#' @param object A single `agri_growth_fit` object.
#' @param R Number of bootstrap replicates. At least 20; 1000 or more is commonly
#'   appropriate for final interval estimation.
#' @param method Resampling scheme. `"auto"` uses cluster resampling when a
#'   persistent unit with repeated observations is available and otherwise uses
#'   case resampling.
#' @param seed Optional reproducibility seed.
#' @param n_start Number of starts used when refitting each bootstrap sample.
#' @param engine Optional refitting engine. Defaults to the engine used in the
#'   original fit.
#' @param wild_weights Wild-bootstrap multiplier distribution.
#' @param control Optional nonlinear optimizer control list passed to refits.
#' @param keep_fits Logical. Store successful fitted objects. This can increase
#'   object size substantially.
#'
#' @description
#' Resampling is explicit about the experimental unit. Case, cluster, residual,
#' parametric, wild, and cluster-wild schemes are available. Cluster bootstrap
#' resamples complete persistent-unit trajectories and is the default selected by
#' `method = "auto"` when the fitted data retain repeated observations by unit.
#' Residual, parametric and row-wise wild bootstrap do not by themselves preserve
#' serial dependence and should not be presented as if they did.
#'
#' @return An object of class `agri_growth_boot` containing replicate-level
#' coefficients, derived growth traits, success records, and the original estimates.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' b <- growth_boot(f, R = 25, seed = 123)
#' growth_boot_ci(b, source = "coefficients")
#' growth_boot_traits(b)
growth_boot <- function(object,
                        R = 999L,
                        method = c("auto", "case", "cluster", "residual", "parametric", "wild", "cluster_wild"),
                        seed = NULL,
                        n_start = 1L,
                        engine = NULL,
                        wild_weights = c("rademacher", "mammen"),
                        control = list(),
                        keep_fits = FALSE) {
  if (!inherits(object, "agri_growth_fit")) {
    stop("`growth_boot()` currently requires one `agri_growth_fit`. Subset groups or candidate models explicitly before resampling.", call. = FALSE)
  }
  R <- .agf_boot_validate_R(R)
  method <- .agf_boot_method(match.arg(method), object$data)
  wild_weights <- match.arg(wild_weights)
  if (!is.null(seed)) set.seed(seed)

  coef_names <- names(object$coefficients)
  trait0 <- .agf_boot_numeric_traits(object)
  trait_names <- names(trait0)
  coef_mat <- matrix(NA_real_, nrow = R, ncol = length(coef_names), dimnames = list(NULL, coef_names))
  trait_mat <- matrix(NA_real_, nrow = R, ncol = length(trait_names), dimnames = list(NULL, trait_names))
  records <- vector("list", R)
  fits <- if (isTRUE(keep_fits)) vector("list", R) else NULL

  for (i in seq_len(R)) {
    d <- tryCatch(.agf_boot_resample_data(object, method = method, wild_weights = wild_weights), error = function(e) e)
    if (inherits(d, "error")) {
      records[[i]] <- data.frame(replicate = i, success = FALSE, error = conditionMessage(d), stringsAsFactors = FALSE)
      next
    }
    bf <- .agf_boot_refit(object, d, n_start = n_start, engine = engine, control = control)
    if (inherits(bf, "agri_growth_boot_failure")) {
      records[[i]] <- data.frame(replicate = i, success = FALSE, error = bf$error, stringsAsFactors = FALSE)
      next
    }
    cf <- bf$coefficients
    coef_mat[i, names(cf)] <- cf
    tr <- .agf_boot_numeric_traits(bf)
    trait_mat[i, names(tr)] <- as.numeric(unlist(tr[1L, , drop = FALSE], use.names = FALSE))
    records[[i]] <- data.frame(replicate = i, success = TRUE, error = "", stringsAsFactors = FALSE)
    if (isTRUE(keep_fits)) fits[[i]] <- bf
  }

  records <- do.call(rbind, records)
  success_rate <- mean(records$success)
  if (success_rate < 0.8) {
    warning("Bootstrap refitting succeeded for only ", round(100 * success_rate, 1), "% of replicates. Inspect `records` before interpreting intervals.", call. = FALSE)
  }

  out <- list(
    model = object$model,
    method = method,
    wild_weights = if (method %in% c("wild", "cluster_wild")) wild_weights else NA_character_,
    R = R,
    seed = seed,
    original_fit = object,
    original_coefficients = object$coefficients,
    original_traits = trait0,
    coefficients = as.data.frame(coef_mat),
    traits = as.data.frame(trait_mat),
    records = records,
    success_rate = success_rate,
    successful_fits = fits
  )
  class(out) <- "agri_growth_boot"
  out
}

#' @export
print.agri_growth_boot <- function(x, ...) {
  cat("<agri_growth_boot> model:", x$model, "\n")
  cat("Method:", x$method, " Replicates:", x$R, " Success:", sprintf("%.1f%%", 100 * x$success_rate), "\n")
  invisible(x)
}

.agf_boot_ci_one <- function(draws, theta0, conf, type) {
  draws <- draws[is.finite(draws)]
  if (length(draws) < 20L) return(c(estimate = theta0, lower = NA_real_, upper = NA_real_, se = NA_real_, n_success = length(draws)))
  alpha <- (1 - conf) / 2
  q <- stats::quantile(draws, probs = c(alpha, 1 - alpha), na.rm = TRUE, names = FALSE, type = 7)
  se <- stats::sd(draws)
  if (identical(type, "percentile")) {
    lo <- q[[1L]]; hi <- q[[2L]]
  } else if (identical(type, "basic")) {
    lo <- 2 * theta0 - q[[2L]]; hi <- 2 * theta0 - q[[1L]]
  } else {
    z <- stats::qnorm(1 - alpha)
    lo <- theta0 - z * se; hi <- theta0 + z * se
  }
  c(estimate = theta0, lower = lo, upper = hi, se = se, n_success = length(draws))
}

#' Confidence intervals from a growth bootstrap
#'
#' @param object An `agri_growth_boot` object.
#' @param source Bootstrap quantity family: coefficients or derived traits.
#' @param parm Optional names to summarize. Defaults to all available quantities.
#' @param conf Confidence level.
#' @param type Interval construction: percentile, basic, or normal approximation.
#'
#' @return A data frame with original estimate, interval limits, bootstrap standard
#' error and successful replicate count.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' b <- growth_boot(f, R = 25, seed = 10)
#' growth_boot_ci(b, "coefficients")
#' growth_boot_ci(b, "traits", parm = c("t50", "maximum_absolute_rate"))
#' growth_boot_ci(b, "coefficients", type = "basic")
growth_boot_ci <- function(object,
                           source = c("coefficients", "traits"),
                           parm = NULL,
                           conf = 0.95,
                           type = c("percentile", "basic", "normal")) {
  if (!inherits(object, "agri_growth_boot")) stop("`object` must be created by growth_boot().", call. = FALSE)
  source <- match.arg(source)
  type <- match.arg(type)
  if (!is.numeric(conf) || length(conf) != 1L || is.na(conf) || conf <= 0 || conf >= 1) {
    stop("`conf` must be a single number between 0 and 1.", call. = FALSE)
  }
  draws <- object[[source]]
  theta <- if (identical(source, "coefficients")) object$original_coefficients else unlist(object$original_traits[1L, ], use.names = TRUE)
  available <- intersect(names(draws), names(theta))
  if (is.null(parm)) parm <- available
  if (!is.character(parm) || !length(parm) || any(!parm %in% available)) {
    stop("Unknown `parm`. Available values are: ", paste(available, collapse = ", "), ".", call. = FALSE)
  }
  rows <- lapply(parm, function(nm) {
    z <- .agf_boot_ci_one(draws[[nm]], theta[[nm]], conf = conf, type = type)
    data.frame(
      source = source,
      parameter = nm,
      estimate = unname(z[["estimate"]]),
      lower = unname(z[["lower"]]),
      upper = unname(z[["upper"]]),
      bootstrap_se = unname(z[["se"]]),
      n_success = as.integer(z[["n_success"]]),
      conf = conf,
      type = type,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Bootstrap intervals for biologically interpretable growth traits
#'
#' @inheritParams growth_boot_ci
#' @param traits Optional trait names. Defaults to all finite-valued original traits.
#'
#' @return A data frame returned by `growth_boot_ci(source = "traits")`.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' b <- growth_boot(f, R = 25, seed = 11)
#' growth_boot_traits(b, traits = c("t50", "t90"))
#' growth_boot_traits(b, type = "normal")
#' growth_boot_traits(b, conf = 0.90)
growth_boot_traits <- function(object,
                               traits = NULL,
                               conf = 0.95,
                               type = c("percentile", "basic", "normal")) {
  if (!inherits(object, "agri_growth_boot")) stop("`object` must be created by growth_boot().", call. = FALSE)
  if (is.null(traits)) {
    theta <- unlist(object$original_traits[1L, ], use.names = TRUE)
    traits <- names(theta)[is.finite(theta)]
  }
  growth_boot_ci(object, source = "traits", parm = traits, conf = conf, type = match.arg(type))
}

.agf_selection_metric <- function(fit) {
  n <- fit$n
  k <- fit$k + 1L
  aic <- tryCatch(as.numeric(stats::AIC(fit$fit)), error = function(e) n * log(fit$rss / n) + 2 * k)
  aicc <- if (n > k + 1L) aic + (2 * k * (k + 1)) / (n - k - 1) else NA_real_
  c(aic = aic, aicc = aicc)
}

#' Bootstrap stability of parametric growth-model selection
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param models Candidate model names.
#' @param time,response Column names when `x` is a data frame.
#' @param R Number of bootstrap samples.
#' @param method `"auto"`, `"case"`, or `"cluster"`. Model-selection stability
#'   intentionally resamples observed units/cases rather than residuals from one
#'   privileged candidate model.
#' @param seed Optional reproducibility seed.
#' @param n_start Number of starts for every candidate in every replicate.
#' @param engine Nonlinear fitting engine.
#' @param aggregate Destructive-data aggregation rule.
#'
#' @return An object of class `agri_growth_selection_stability` with replicate
#' metrics and winner frequencies.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' s <- growth_selection_stability(d, c("logistic", "gompertz"), time = "day",
#'                                 response = "biomass_g", R = 20, seed = 1)
#' s$frequencies
#' print(s)
#' subset(s$replicates, success)
growth_selection_stability <- function(x,
                                       models,
                                       time = NULL,
                                       response = NULL,
                                       R = 199L,
                                       method = c("auto", "case", "cluster"),
                                       seed = NULL,
                                       n_start = 1L,
                                       engine = c("auto", "nls", "minpack.lm"),
                                       aggregate = c("auto", "none", "mean")) {
  R <- .agf_boot_validate_R(R)
  engine <- match.arg(engine)
  aggregate <- match.arg(aggregate)
  models <- unique(vapply(models, .agf_model_alias, character(1)))
  if (length(models) < 2L) stop("Supply at least two candidate models.", call. = FALSE)
  d <- .agf_prepare_parametric(x, time = time, response = response, group = NULL,
                               aggregate = aggregate, warn_pooling = FALSE, warn_dependence = FALSE)
  method <- match.arg(method)
  method <- if (identical(method, "auto")) .agf_boot_method("auto", d) else method
  if (!method %in% c("case", "cluster")) stop("Model-selection stability uses case or cluster resampling.", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)

  rows <- vector("list", R)
  metric_rows <- list()
  m_index <- 0L
  for (i in seq_len(R)) {
    db <- if (identical(method, "cluster")) .agf_boot_cluster_sample(d) else {
      idx <- sample.int(nrow(d), nrow(d), replace = TRUE)
      z <- d[idx, , drop = FALSE]
      z$.unit <- paste0(z$.unit, "_row", seq_len(nrow(z)))
      .agf_boot_attach_attrs(z, d)
    }
    fits <- vector("list", length(models)); names(fits) <- models
    for (j in seq_along(models)) {
      fits[[j]] <- tryCatch(.agf_fit_one(db, models[[j]], n_start = n_start,
                                        seed = NULL, engine = engine), error = function(e) NULL)
    }
    ok <- !vapply(fits, is.null, logical(1))
    if (sum(ok) < 2L) {
      rows[[i]] <- data.frame(replicate = i, success = FALSE, winner = NA_character_, n_models_fit = sum(ok), stringsAsFactors = FALSE)
      next
    }
    metrics <- lapply(fits[ok], .agf_selection_metric)
    mt <- do.call(rbind, metrics)
    criterion <- if (all(is.finite(mt[, "aicc"]))) mt[, "aicc"] else mt[, "aic"]
    winner <- names(which.min(criterion))
    rows[[i]] <- data.frame(replicate = i, success = TRUE, winner = winner, n_models_fit = sum(ok), stringsAsFactors = FALSE)
    for (nm in names(fits)[ok]) {
      m_index <- m_index + 1L
      metric_rows[[m_index]] <- data.frame(replicate = i, model = nm,
                                            aic = mt[nm, "aic"], aicc = mt[nm, "aicc"],
                                            stringsAsFactors = FALSE)
    }
  }
  reps <- do.call(rbind, rows)
  met <- if (length(metric_rows)) do.call(rbind, metric_rows) else data.frame()
  wins <- table(factor(reps$winner[reps$success], levels = models))
  denom <- sum(reps$success)
  freq <- data.frame(model = models, wins = as.integer(wins),
                     selection_frequency = if (denom) as.integer(wins) / denom else NA_real_,
                     stringsAsFactors = FALSE)
  freq <- freq[order(-freq$selection_frequency, freq$model), , drop = FALSE]
  out <- list(models = models, method = method, R = R, success_rate = mean(reps$success),
              replicates = reps, metrics = met, frequencies = freq)
  class(out) <- "agri_growth_selection_stability"
  out
}

#' @export
print.agri_growth_selection_stability <- function(x, ...) {
  cat("<agri_growth_selection_stability>\n")
  cat("Method:", x$method, " Replicates:", x$R, " Success:", sprintf("%.1f%%", 100 * x$success_rate), "\n")
  print(x$frequencies, row.names = FALSE)
  invisible(x)
}
