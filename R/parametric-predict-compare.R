.agf_gradient_internal <- function(fit, t) {
  p <- fit$coefficients_internal
  lower <- fit$lower_internal
  upper <- fit$upper_internal
  m <- length(t)
  q <- length(p)
  g <- matrix(NA_real_, nrow = m, ncol = q, dimnames = list(NULL, names(p)))
  for (j in seq_along(p)) {
    base_step <- sqrt(.Machine$double.eps) * (abs(p[[j]]) + 1)
    h_plus <- min(base_step, (upper[[j]] - p[[j]]) / 2)
    h_minus <- min(base_step, (p[[j]] - lower[[j]]) / 2)
    can_plus <- is.finite(h_plus) && h_plus > 0
    can_minus <- is.finite(h_minus) && h_minus > 0
    if (can_plus && can_minus) {
      pp <- p; pm <- p
      pp[[j]] <- p[[j]] + h_plus
      pm[[j]] <- p[[j]] - h_minus
      yp <- .agf_eval_internal(fit$model, t, pp)
      ym <- .agf_eval_internal(fit$model, t, pm)
      g[, j] <- (yp - ym) / (h_plus + h_minus)
    } else if (can_plus) {
      pp <- p; pp[[j]] <- p[[j]] + h_plus
      yp <- .agf_eval_internal(fit$model, t, pp)
      y0 <- .agf_eval_internal(fit$model, t, p)
      g[, j] <- (yp - y0) / h_plus
    } else if (can_minus) {
      pm <- p; pm[[j]] <- p[[j]] - h_minus
      y0 <- .agf_eval_internal(fit$model, t, p)
      ym <- .agf_eval_internal(fit$model, t, pm)
      g[, j] <- (y0 - ym) / h_minus
    }
  }
  g
}

.agf_predict_one <- function(object, time = NULL,
                             interval = c("none", "confidence", "prediction"),
                             level = 0.95) {
  interval <- match.arg(interval)
  if (!is.numeric(level) || length(level) != 1L || is.na(level) || level <= 0 || level >= 1) {
    stop("`level` must be a single number between 0 and 1.", call. = FALSE)
  }
  if (is.null(time)) time <- object$data$.t
  if (inherits(time, "Date")) time <- as.numeric(time)
  if (!is.numeric(time) || any(!is.finite(time))) stop("`time` must contain finite numeric values.", call. = FALSE)
  fitv <- .agf_eval_internal(object$model, as.numeric(time), object$coefficients_internal)
  out <- data.frame(time = as.numeric(time), fit = as.numeric(fitv), stringsAsFactors = FALSE)
  if (identical(interval, "none")) return(out)

  vc <- object$vcov_internal
  if (!all(dim(vc) == c(length(object$coefficients_internal), length(object$coefficients_internal))) || any(!is.finite(vc))) {
    warning("Coefficient covariance is unavailable or non-finite; interval columns are returned as NA.", call. = FALSE)
    out$se_fit <- NA_real_
    out$lower <- NA_real_
    out$upper <- NA_real_
    out$interval <- interval
    out$level <- level
    return(out)
  }
  g <- .agf_gradient_internal(object, as.numeric(time))
  vari <- rowSums((g %*% vc) * g)
  vari[vari < 0 & vari > -1e-10] <- 0
  if (identical(interval, "prediction")) vari <- vari + object$sigma^2
  se <- sqrt(pmax(vari, 0))
  crit <- stats::qt(1 - (1 - level) / 2, df = object$df_residual)
  out$se_fit <- se
  out$lower <- out$fit - crit * se
  out$upper <- out$fit + crit * se
  out$interval <- interval
  out$level <- level
  out
}

#' Predict fitted parametric growth trajectories
#'
#' @param object An `agri_growth_fit`, fit set, or grouped fit collection.
#' @param time Optional numeric prediction times. Defaults to prepared observed times.
#' @param interval One of `"none"`, `"confidence"`, or `"prediction"`.
#' @param level Interval confidence level.
#'
#' @description
#' Confidence and prediction intervals use a local numerical delta method based on
#' the coefficient covariance matrix. They are not bootstrap intervals and they do
#' not incorporate hierarchical experimental-unit variation.
#'
#' @return A data frame.
#' @export
#'
#' @examples
#' # 1) Prediction on the observed grid
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' head(growth_predict(f))
#'
#' # 2) Confidence interval
#' growth_predict(f, time = c(20, 40, 60), interval = "confidence", level = 0.90)
#'
#' # 3) Prediction interval
#' growth_predict(f, time = c(20, 40, 60), interval = "prediction")
growth_predict <- function(object, time = NULL,
                           interval = c("none", "confidence", "prediction"),
                           level = 0.95) {
  interval <- match.arg(interval)
  if (inherits(object, "agri_growth_fit")) return(.agf_predict_one(object, time, interval, level))
  if (inherits(object, "agri_growth_fit_set")) {
    out <- lapply(names(object$fits), function(nm) {
      z <- .agf_predict_one(object$fits[[nm]], time, interval, level)
      z$model <- nm
      z
    })
    ans <- do.call(rbind, out); rownames(ans) <- NULL
    return(ans)
  }
  if (inherits(object, "agri_growth_fit_collection")) {
    out <- lapply(names(object$fits), function(nm) {
      fit <- object$fits[[nm]]
      z <- growth_predict(fit, time = time, interval = interval, level = level)
      z$group <- nm
      z
    })
    ans <- do.call(rbind, out); rownames(ans) <- NULL
    return(ans)
  }
  stop("`object` must be a parametric fit created by growth_fit().", call. = FALSE)
}

.agf_collect_compare_fits <- function(...) {
  args <- list(...)
  if (!length(args)) stop("Supply at least one fitted model.", call. = FALSE)
  if (length(args) == 1L && inherits(args[[1L]], "agri_growth_fit_set")) return(args[[1L]]$fits)
  # unwrap a single list of fits as used in some vignettes: growth_compare(list(f1, f2, f3))
  if (length(args) == 1L && is.list(args[[1L]]) && !inherits(args[[1L]], "agri_growth_fit") && !inherits(args[[1L]], "agri_growth_fit_set")) {
    maybe <- args[[1L]]
    if (length(maybe) && all(vapply(maybe, function(z) inherits(z, "agri_growth_fit"), logical(1)))) {
      fits <- maybe
      if (is.null(names(fits)) || any(!nzchar(names(fits)))) names(fits) <- vapply(fits, `[[`, character(1), "model")
      return(fits)
    }
  }
  fits <- list()
  for (a in args) {
    if (inherits(a, "agri_growth_fit")) fits[[length(fits) + 1L]] <- a
    else if (inherits(a, "agri_growth_fit_set")) fits <- c(fits, a$fits)
    else stop("growth_compare() accepts `agri_growth_fit` objects or a fit set.", call. = FALSE)
  }
  if (is.null(names(fits)) || any(!nzchar(names(fits)))) names(fits) <- vapply(fits, `[[`, character(1), "model")
  fits
}

#' Compare parametric growth models fitted to identical prepared observations
#'
#' @param ... `agri_growth_fit` objects or one `agri_growth_fit_set`.
#'
#' @return An object of class `agri_growth_comparison` containing RSS, RMSE, MAE,
#' AIC, AICc, BIC, delta AICc, and Akaike weights.
#' @export
#'
#' @examples
#' # 1) Two models on the same prepared observations
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f1 <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' f2 <- growth_fit(d1, "gompertz", time = "day", response = "biomass_g")
#' growth_compare(f1, f2)[, c("model", "aicc", "delta_aicc", "akaike_weight")]
#'
#' # 2) Three models
#' f3 <- growth_fit(d1, "richards", time = "day", response = "biomass_g")
#' growth_compare(f1, f2, f3)$model
#'
#' # 3) Comparison inside a collection by group
#' fc <- growth_fit(d, c("logistic", "gompertz"), time = "day",
#'                  response = "biomass_g", group = "cultivar")
#' growth_compare(fc$fits[[1]]$fits[[1]], fc$fits[[1]]$fits[[2]])
growth_compare <- function(...) {
  fits <- .agf_collect_compare_fits(...)
  if (length(fits) < 2L) warning("Model comparison is most informative with at least two candidate fits.", call. = FALSE)
  keys <- vapply(fits, `[[`, character(1), "observation_key")
  if (length(unique(keys)) != 1L) {
    stop("Models were not fitted to identical prepared observations. AIC/AICc/BIC comparisons are refused.", call. = FALSE)
  }
  rows <- lapply(fits, function(f) {
    n <- f$n
    k <- f$k + 1L
    aic <- tryCatch(as.numeric(stats::AIC(f$fit)), error = function(e) n * log(f$rss / n) + 2 * k)
    bic <- tryCatch(as.numeric(stats::BIC(f$fit)), error = function(e) n * log(f$rss / n) + log(n) * k)
    aicc <- if (n > k + 1L) aic + (2 * k * (k + 1)) / (n - k - 1) else NA_real_
    data.frame(
      model = f$model,
      n = n,
      parameters_likelihood = k,
      rss = f$rss,
      rmse = sqrt(mean(f$residuals^2)),
      mae = mean(abs(f$residuals)),
      aic = aic,
      aicc = aicc,
      bic = bic,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  finite <- is.finite(out$aicc)
  out$delta_aicc <- NA_real_
  out$akaike_weight <- NA_real_
  if (any(finite)) {
    best <- min(out$aicc[finite])
    out$delta_aicc[finite] <- out$aicc[finite] - best
    rel <- exp(-0.5 * out$delta_aicc[finite])
    out$akaike_weight[finite] <- rel / sum(rel)
    out <- out[order(out$aicc, out$aic, na.last = TRUE), , drop = FALSE]
  } else {
    warning("No candidate has finite AICc because sample size is too small relative to model complexity.", call. = FALSE)
    out <- out[order(out$aic), , drop = FALSE]
  }
  rownames(out) <- NULL
  class(out) <- c("agri_growth_comparison", "data.frame")
  out
}

#' @export
#' @examples
#' # 1) Comparison table
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f1 <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' f2 <- growth_fit(d1, "gompertz", time = "day", response = "biomass_g")
#' cmp <- growth_compare(f1, f2)
#' print(cmp)
#'
#' # 2) Best model by AICc
#' cmp$model[which.min(cmp$aicc)]
#'
#' # 3) Invisible return
#' identical(print(cmp), cmp)
print.agri_growth_comparison <- function(x, ...) {
  cat("<agri_growth_comparison> same prepared observations\n")
  print.data.frame(x, row.names = FALSE)
  invisible(x)
}

#' @export
#' @examples
#' # 1) Fitted curve over the data
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' p <- plot(f)
#' class(p)[1]
#'
#' # 2) With a confidence band
#' class(plot(f, interval = "confidence", level = 0.90, n = 50))[1]
#'
#' # 3) The returned object is an editable ggplot
#' p + ggplot2::labs(title = "Fitted curve")
plot.agri_growth_fit <- function(x, ..., interval = c("confidence", "prediction", "none"),
                                 level = 0.95, n = 200L) {
  .agf_require_ggplot2()
  interval <- match.arg(interval)
  grid <- seq(x$time_support[1L], x$time_support[2L], length.out = n)
  pred <- growth_predict(x, time = grid, interval = interval, level = level)
  p <- ggplot2::ggplot(x$data, ggplot2::aes(x = .t, y = .y)) +
    ggplot2::geom_point(alpha = 0.65) +
    ggplot2::geom_line(data = pred, ggplot2::aes(x = time, y = fit), inherit.aes = FALSE, linewidth = 0.9)
  if (!identical(interval, "none") && all(c("lower", "upper") %in% names(pred))) {
    p <- p + ggplot2::geom_ribbon(data = pred, ggplot2::aes(x = time, ymin = lower, ymax = upper), inherit.aes = FALSE, alpha = 0.18)
  }
  p + ggplot2::labs(x = "Time", y = "Growth response", title = paste("Parametric growth:", x$model)) + ggplot2::theme_bw()
}
