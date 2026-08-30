.agf_lag_diagnostics <- function(residuals, time, unit) {
  units <- unique(unit)
  x1 <- numeric(); x2 <- numeric(); diffs <- numeric()
  for (u in units) {
    idx <- which(unit == u)
    idx <- idx[order(time[idx])]
    if (length(idx) < 2L) next
    r <- residuals[idx]
    good <- is.finite(r[-length(r)]) & is.finite(r[-1L])
    if (any(good)) {
      x1 <- c(x1, r[-length(r)][good])
      x2 <- c(x2, r[-1L][good])
      diffs <- c(diffs, diff(r)[good])
    }
  }
  corr <- if (length(x1) >= 3L && stats::sd(x1) > 0 && stats::sd(x2) > 0) stats::cor(x1, x2) else NA_real_
  denom <- sum(residuals^2, na.rm = TRUE)
  dw <- if (length(diffs) && denom > 0) sum(diffs^2) / denom else NA_real_
  list(correlation = corr, dw = dw, pairs = length(x1))
}

#' Diagnose a fitted parametric growth model
#'
#' @param object An `agri_growth_fit` object.
#' @param boundary_fraction Fraction of a hard-bound span used to flag near-bound parameters.
#'
#' @return An `agri_growth_diagnostics` object with summary, residual records,
#' issues, boundary table and fitting attempts.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' growth_diagnose(f)
#' growth_diagnose(f)$issues
#' growth_diagnose(f)$attempts
growth_diagnose <- function(object, boundary_fraction = 0.01) {
  if (!inherits(object, "agri_growth_fit")) stop("`object` must be an `agri_growth_fit`.", call. = FALSE)
  if (!is.numeric(boundary_fraction) || length(boundary_fraction) != 1L || boundary_fraction <= 0 || boundary_fraction >= 0.5) {
    stop("`boundary_fraction` must be between 0 and 0.5.", call. = FALSE)
  }
  d <- object$data
  resid <- object$residuals
  lag <- .agf_lag_diagnostics(resid, d$.t, d$.unit)
  vc <- object$vcov_internal
  cond <- if (all(is.finite(vc))) tryCatch(kappa(vc), error = function(e) NA_real_) else NA_real_
  yvar <- sum((d$.y - mean(d$.y))^2)
  r2 <- if (yvar > 0) 1 - object$rss / yvar else NA_real_

  p <- object$coefficients_internal
  lo <- object$lower_internal[names(p)]
  hi <- object$upper_internal[names(p)]
  span <- hi - lo
  rel_lower <- (p - lo) / span
  rel_upper <- (hi - p) / span
  near <- pmin(rel_lower, rel_upper) <= boundary_fraction
  boundary <- data.frame(
    parameter = names(p), estimate = as.numeric(p), lower = as.numeric(lo), upper = as.numeric(hi),
    relative_distance_to_nearest_bound = as.numeric(pmin(rel_lower, rel_upper)),
    near_bound = as.logical(near), stringsAsFactors = FALSE
  )

  issues <- list()
  if (any(near, na.rm = TRUE)) issues[[length(issues) + 1L]] <- .agf_issue("warning", "parameter_near_bound", "At least one coefficient is close to a hard fitting bound; inspect identifiability and biological support.")
  if (is.finite(cond) && cond > 1e8) issues[[length(issues) + 1L]] <- .agf_issue("warning", "ill_conditioned_covariance", "The coefficient covariance matrix is poorly conditioned, suggesting parameter trade-offs or weak identifiability.")
  if (sum(object$attempts$converged) < max(1L, nrow(object$attempts) / 2)) issues[[length(issues) + 1L]] <- .agf_issue("warning", "multistart_instability", "Fewer than half of fitting starts converged; inspect the attempts table and model support.")
  if (object$sampling %in% c("repeated", "destructive", "mixed") && lag$pairs > 0) issues[[length(issues) + 1L]] <- .agf_issue("info", "serial_dependence_not_modeled", "Lag diagnostics are descriptive because ordinary NLS does not include a within-unit covariance model.")

  summary <- data.frame(
    model = object$model,
    n = object$n,
    rmse = sqrt(mean(resid^2)),
    mae = mean(abs(resid)),
    mean_residual = mean(resid),
    descriptive_r_squared = r2,
    lag1_residual_correlation = lag$correlation,
    durbin_watson_descriptive = lag$dw,
    lag_pairs = lag$pairs,
    lag_diagnostics_scope = if (length(unique(d$.unit)) > 1L || any(table(d$.unit) > 1L)) "within prepared experimental unit" else "single prepared series",
    covariance_condition_number = cond,
    converged_starts = sum(object$attempts$converged),
    attempted_starts = nrow(object$attempts),
    stringsAsFactors = FALSE
  )
  residual_df <- data.frame(time = d$.t, observed = d$.y, fitted = object$fitted, residual = resid, unit = d$.unit, group = d$.group, stringsAsFactors = FALSE)
  out <- list(summary = summary, residuals = residual_df, issues = .agf_rbind_issues(issues), boundaries = boundary, attempts = object$attempts)
  class(out) <- "agri_growth_diagnostics"
  out
}

#' @export
print.agri_growth_diagnostics <- function(x, ...) {
  cat("<agri_growth_diagnostics>\n")
  print(x$summary, row.names = FALSE)
  if (nrow(x$issues)) {
    cat("Issues:\n")
    print(x$issues, row.names = FALSE)
  } else cat("Issues: none detected by the current descriptive checks\n")
  invisible(x)
}
