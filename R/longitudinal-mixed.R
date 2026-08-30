.agf_nlme_correlation <- function(correlation, d) {
  correlation <- match.arg(correlation, c("none", "ar1", "car1"))
  if (identical(correlation, "none")) return(NULL)
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("`growth_mixed()` requires the recommended R package `nlme`.", call. = FALSE)
  }
  if (identical(correlation, "ar1")) {
    if (any(abs(d$.t - round(d$.t)) > 1e-8)) {
      stop("`correlation = \"ar1\"` requires integer-valued time. Use `\"car1\"` for irregular continuous time.", call. = FALSE)
    }
    return(nlme::corAR1(form = ~ .t | .unit))
  }
  nlme::corCAR1(form = ~ .t | .unit)
}

.agf_nlme_weights <- function(variance, d) {
  variance <- match.arg(variance, c("none", "power", "exponential", "group", "time"))
  if (identical(variance, "none")) return(NULL)
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("`growth_mixed()` requires the recommended R package `nlme`.", call. = FALSE)
  }
  if (identical(variance, "power")) return(nlme::varPower(form = ~ fitted(.)))
  if (identical(variance, "exponential")) return(nlme::varExp(form = ~ fitted(.)))
  if (identical(variance, "group")) {
    if (nlevels(d$.group) < 2L) stop("`variance = \"group\"` requires at least two group levels.", call. = FALSE)
    return(nlme::varIdent(form = ~ 1 | .group))
  }
  d$.time_factor <- factor(d$.t)
  nlme::varIdent(form = ~ 1 | .time_factor)
}

#' Fit a design-aware longitudinal mixed growth model
#'
#' @description
#' Fits a polynomial growth trajectory with persistent-unit random effects using
#' `nlme::lme()`. Declared treatment and block roles are used automatically when
#' `x` is an `agri_growth_data` object unless explicit columns are supplied.
#' Correlation and variance structures are optional and are never selected only
#' from a p-value.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,response,unit,group,block Column names when needed.
#' @param degree Fixed-effect orthogonal polynomial degree for time.
#' @param random_degree Random polynomial degree within persistent unit. Zero is
#'   a random intercept only.
#' @param correlation One of `"none"`, `"ar1"`, or `"car1"`.
#' @param variance One of `"none"`, `"power"`, `"exponential"`, `"group"`, or `"time"`.
#' @param method `"REML"` or `"ML"`.
#' @param aggregate Destructive-sampling aggregation rule.
#' @param control Optional list passed to `nlme::lmeControl()`.
#' @return An object of class `agri_growth_mixed`.
#' @export
#'
#' @examples
#' d <- growth_example_data("bean_repeated")
#' growth_mixed(d, time = "day", response = "height_cm", unit = "plant_id",
#'              group = "water_regime", block = "block", degree = 2)
#' growth_mixed(d, time = "day", response = "projected_leaf_area_m2", unit = "plant_id",
#'              group = "water_regime", correlation = "car1")
#' growth_mixed(d, time = "day", response = "spad", unit = "plant_id",
#'              group = "water_regime", variance = "group", degree = 1)
growth_mixed <- function(x,
                         time = NULL,
                         response = NULL,
                         unit = NULL,
                         group = NULL,
                         block = NULL,
                         degree = 2L,
                         random_degree = 1L,
                         correlation = c("none", "ar1", "car1"),
                         variance = c("none", "power", "exponential", "group", "time"),
                         method = c("REML", "ML"),
                         aggregate = c("auto", "none", "mean"),
                         control = list()) {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("`growth_mixed()` requires the recommended R package `nlme`.", call. = FALSE)
  }
  correlation <- match.arg(correlation)
  variance <- match.arg(variance)
  method <- match.arg(method)
  aggregate <- match.arg(aggregate)
  degree <- as.integer(degree)
  random_degree <- as.integer(random_degree)
  if (!is.finite(degree) || degree < 1L || degree > 6L) stop("`degree` must be an integer from 1 to 6.", call. = FALSE)
  if (!is.finite(random_degree) || random_degree < 0L || random_degree > degree) {
    stop("`random_degree` must be between 0 and `degree`.", call. = FALSE)
  }

  d <- .agf_prepare_longitudinal(
    x, time = time, response = response, unit = unit, group = group, block = block,
    aggregate = aggregate, require_unit = TRUE, min_times = degree + 1L,
    auto_group = TRUE, auto_block = TRUE
  )
  if (any(table(d$.unit) < 2L)) {
    stop("Every persistent unit must contribute at least two observations to `growth_mixed()`.", call. = FALSE)
  }

  has_group <- nlevels(d$.group) > 1L
  has_block <- nlevels(d$.block) > 1L
  time_term <- paste0("poly(.t, ", degree, ", raw = FALSE)")
  rhs <- if (has_group) paste0(time_term, " * .group") else time_term
  if (has_block) rhs <- paste(".block +", rhs)
  fixed <- stats::as.formula(paste(".y ~", rhs), env = environment())
  random <- if (random_degree == 0L) {
    stats::as.formula("~ 1 | .unit")
  } else {
    stats::as.formula(paste0("~ poly(.t, ", random_degree, ", raw = FALSE) | .unit"), env = environment())
  }

  cor_obj <- .agf_nlme_correlation(correlation, d)
  if (identical(variance, "time")) d$.time_factor <- factor(d$.t)
  weight_obj <- .agf_nlme_weights(variance, d)
  ctrl <- do.call(nlme::lmeControl, control)

  warnings <- character()
  fit <- withCallingHandlers(
    nlme::lme(
      fixed = fixed,
      random = random,
      data = d,
      correlation = cor_obj,
      weights = weight_obj,
      method = method,
      na.action = stats::na.omit,
      control = ctrl
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  out <- list(
    fit = fit,
    data = d,
    degree = degree,
    random_degree = random_degree,
    correlation = correlation,
    variance = variance,
    method = method,
    fixed_formula = fixed,
    random_formula = random,
    group_name = attr(d, "group_name"),
    block_name = attr(d, "block_name"),
    unit_name = attr(d, "unit_name"),
    time_name = attr(d, "time_name"),
    response_name = attr(d, "response_name"),
    sampling = attr(d, "sampling"),
    aggregation = attr(d, "aggregation"),
    warnings = unique(warnings)
  )
  class(out) <- "agri_growth_mixed"
  out
}

#' Diagnose a longitudinal mixed growth model
#'
#' @param object An `agri_growth_mixed` object.
#' @return An `agri_growth_mixed_diagnostics` object.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' if (requireNamespace("nlme", quietly = TRUE)) {
#'   m <- growth_mixed(d, time="day", response="height_cm", unit="plant_id", group="water_regime")
#'   growth_mixed_diagnose(m)
#'   growth_mixed_diagnose(growth_mixed(d, time="day", response="spad", unit="plant_id", degree=1))
#'   growth_mixed_diagnose(growth_mixed(d, time="day", response="projected_leaf_area_m2", unit="plant_id", correlation="car1"))
#' }
growth_mixed_diagnose <- function(object) {
  if (!inherits(object, "agri_growth_mixed")) stop("`object` must be an `agri_growth_mixed` object.", call. = FALSE)
  fit <- object$fit
  d <- object$data
  r <- as.numeric(stats::residuals(fit, type = "normalized"))
  f <- as.numeric(stats::fitted(fit, level = 0))
  d$.resid <- r
  lagcors <- vapply(split(d, d$.unit), function(z) {
    z <- z[order(z$.t), , drop = FALSE]
    if (nrow(z) < 3L) return(NA_real_)
    suppressWarnings(stats::cor(z$.resid[-1L], z$.resid[-nrow(z)], use = "complete.obs"))
  }, numeric(1))
  shp <- if (length(r) >= 3L && length(r) <= 5000L && stats::sd(r) > 0) stats::shapiro.test(r)$p.value else NA_real_
  out <- list(
    n = nrow(d),
    n_units = nlevels(d$.unit),
    residual_sd = stats::sd(r),
    residual_mean = mean(r),
    shapiro_p = shp,
    median_within_unit_lag1 = stats::median(lagcors, na.rm = TRUE),
    max_abs_within_unit_lag1 = if (all(is.na(lagcors))) NA_real_ else max(abs(lagcors), na.rm = TRUE),
    fixed_effects = nlme::fixef(fit),
    aic = stats::AIC(fit),
    bic = stats::BIC(fit),
    logLik = as.numeric(stats::logLik(fit)),
    fitted = f,
    residuals = r,
    lag1_by_unit = lagcors,
    correlation = object$correlation,
    variance = object$variance,
    warnings = object$warnings
  )
  class(out) <- "agri_growth_mixed_diagnostics"
  out
}

#' @export
print.agri_growth_mixed <- function(x, ...) {
  cat("<agri_growth_mixed> nlme::lme longitudinal growth model\n")
  cat("Response:", x$response_name, " Time:", x$time_name, " Unit:", x$unit_name, "\n")
  cat("Fixed degree:", x$degree, " Random degree:", x$random_degree, "\n")
  cat("Correlation:", x$correlation, " Variance:", x$variance, " Method:", x$method, "\n")
  cat("Aggregation:", x$aggregation, "\n")
  print(nlme::fixef(x$fit))
  invisible(x)
}

#' @export
print.agri_growth_mixed_diagnostics <- function(x, ...) {
  cat("<agri_growth_mixed_diagnostics>\n")
  cat("Observations:", x$n, " Units:", x$n_units, "\n")
  cat("Residual SD:", .agf_fmt(x$residual_sd), " Median within-unit lag-1:", .agf_fmt(x$median_within_unit_lag1), "\n")
  cat("AIC:", .agf_fmt(x$aic), " BIC:", .agf_fmt(x$bic), "\n")
  if (length(x$warnings)) cat("Captured warnings:", paste(x$warnings, collapse = " | "), "\n")
  invisible(x)
}
