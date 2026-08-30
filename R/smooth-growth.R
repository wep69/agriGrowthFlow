.agf_fit_smooth_one <- function(d, method, spar, cv, span, loess_degree,
                                k, bs, constraint, rho, gam_method) {
  method <- match.arg(method, c("smooth_spline", "loess", "gam", "scam"))
  if (identical(method, "smooth_spline")) {
    fit <- stats::smooth.spline(x = d$.t, y = d$.y, spar = spar, cv = cv)
  } else if (identical(method, "loess")) {
    fit <- stats::loess(.y ~ .t, data = d, span = span, degree = loess_degree,
                        family = "gaussian", control = stats::loess.control(surface = "direct"))
  } else if (identical(method, "gam")) {
    if (!requireNamespace("mgcv", quietly = TRUE)) stop("`method = \"gam\"` requires `mgcv`.", call. = FALSE)
    s <- mgcv::s
    ku <- min(as.integer(k), max(3L, length(unique(d$.t)) - 1L))
    form <- stats::as.formula(paste0(".y ~ s(.t, k = ", ku, ", bs = '", bs, "')"), env = environment())
    fit <- mgcv::gam(form, data = d, method = gam_method)
  } else {
    if (!requireNamespace("scam", quietly = TRUE)) stop("`method = \"scam\"` requires `scam`.", call. = FALSE)
    if (!requireNamespace("mgcv", quietly = TRUE)) stop("`method = \"scam\"` requires `mgcv` through scam.", call. = FALSE)
    constraint <- match.arg(constraint, c("increasing", "decreasing"))
    s <- mgcv::s
    bscode <- if (identical(constraint, "increasing")) "mpi" else "mpd"
    ku <- min(as.integer(k), max(4L, length(unique(d$.t)) - 1L))
    form <- stats::as.formula(paste0(".y ~ s(.t, k = ", ku, ", bs = '", bscode, "')"), env = environment())
    fit <- scam::scam(form, data = d, AR1.rho = rho)
  }
  list(fit = fit, method = method, data = d)
}

#' Fit a flexible plant-growth trajectory
#'
#' @description
#' Fits a descriptive mean growth trajectory without requiring a predefined
#' parametric growth equation. Base-R smoothing splines and LOESS are available
#' without additional packages. GAM and monotone SCAM engines are optional.
#' Population curves are formed after persistent-unit by time aggregation so that
#' destructive subsamples are not treated as independent longitudinal plants.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,response Column names when needed.
#' @param unit Optional persistent-unit column. Supplying it for raw data frames ensures equal unit weighting before population smoothing.
#' @param group Optional column defining separate descriptive trajectories.
#' @param method One of `"smooth_spline"`, `"loess"`, `"gam"`, or `"scam"`.
#' @param aggregate Destructive-sampling aggregation rule before population averaging.
#' @param population If `TRUE`, fit the time-specific persistent-unit mean trajectory.
#' @param spar Optional smoothing parameter for `smooth.spline()`.
#' @param cv Use leave-one-out cross-validation for the smoothing spline.
#' @param span LOESS span.
#' @param loess_degree LOESS local-polynomial degree.
#' @param k Basis dimension for GAM/SCAM.
#' @param bs Basis code for `mgcv::gam()`.
#' @param constraint SCAM monotonicity constraint.
#' @param rho Optional AR1 coefficient for Gaussian SCAM fits.
#' @param gam_method Smoothing-parameter method for `mgcv::gam()`.
#' @return An `agri_growth_smooth` or `agri_growth_smooth_collection`.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' growth_smooth(d, time="day", response="height_cm", group="water_regime", method="smooth_spline")
#' growth_smooth(d, time="day", response="projected_leaf_area_m2", group="water_regime", method="loess")
#' growth_smooth(d, time="day", response="spad", method="smooth_spline", cv=TRUE)
growth_smooth <- function(x,
                          time = NULL,
                          response = NULL,
                          unit = NULL,
                          group = NULL,
                          method = c("smooth_spline", "loess", "gam", "scam"),
                          aggregate = c("auto", "none", "mean"),
                          population = TRUE,
                          spar = NULL,
                          cv = FALSE,
                          span = 0.75,
                          loess_degree = 2L,
                          k = 10L,
                          bs = "tp",
                          constraint = c("increasing", "decreasing"),
                          rho = 0,
                          gam_method = "REML") {
  method <- match.arg(method)
  aggregate <- match.arg(aggregate)
  if (identical(method, "scam")) constraint <- match.arg(constraint)
  if (!is.numeric(span) || length(span) != 1L || span <= 0 || span > 1) stop("`span` must be in (0, 1].", call. = FALSE)
  if (!is.numeric(rho) || length(rho) != 1L || !is.finite(rho) || abs(rho) >= 1) stop("`rho` must be finite with absolute value < 1.", call. = FALSE)
  if (!isTRUE(population)) warning("`population = FALSE` fits pooled observations and does not model within-unit dependence; use `growth_mixed()` for longitudinal inference.", call. = FALSE)

  d <- .agf_prepare_longitudinal(
    x, time = time, response = response, unit = unit, group = group, aggregate = aggregate,
    require_unit = FALSE, min_times = 4L, auto_group = FALSE, auto_block = FALSE
  )
  if (inherits(x, "agri_growth_data") && is.null(group)) {
    trt <- .agf_role(x, "treatment")
    if (!is.null(trt) && length(unique(x$data[[trt]])) > 1L) {
      warning("Multiple treatment levels are present but `group` was not supplied. The smooth pools treatments.", call. = FALSE)
    }
  }
  fd <- if (isTRUE(population)) .agf_population_curve_data(d) else d
  lev <- unique(as.character(fd$.group))
  fits <- lapply(lev, function(g) {
    z <- fd[as.character(fd$.group) == g, , drop = FALSE]
    if (length(unique(z$.t)) < 4L) stop("Each smooth trajectory requires at least four distinct times.", call. = FALSE)
    a <- .agf_fit_smooth_one(z, method, spar, cv, span, loess_degree, k, bs, constraint, rho, gam_method)
    out <- list(
      fit = a$fit,
      method = method,
      data = z,
      group = g,
      time_support = range(z$.t),
      response_support = range(z$.y),
      population = isTRUE(population),
      aggregation = attr(d, "aggregation"),
      time_name = attr(d, "time_name"),
      response_name = attr(d, "response_name"),
      group_name = attr(d, "group_name"),
       constraint = if (identical(method, "scam")) constraint else NULL,
       rho = if (identical(method, "scam")) rho else NULL
    )
    class(out) <- "agri_growth_smooth"
    out
  })
  names(fits) <- lev
  if (length(fits) == 1L) return(fits[[1L]])
  out <- list(fits = fits, groups = lev, group_name = attr(d, "group_name"), method = method, data = fd)
  class(out) <- "agri_growth_smooth_collection"
  out
}

.agf_smooth_predict_one <- function(object, time) {
  if (!inherits(object, "agri_growth_smooth")) stop("Expected an `agri_growth_smooth` object.", call. = FALSE)
  time <- as.numeric(time)
  fit <- object$fit
  if (identical(object$method, "smooth_spline")) {
    return(as.numeric(stats::predict(fit, x = time)$y))
  }
  nd <- data.frame(.t = time)
  if (identical(object$method, "loess")) return(as.numeric(stats::predict(fit, newdata = nd)))
  as.numeric(stats::predict(fit, newdata = nd, type = "response"))
}

#' Predict a flexible growth trajectory
#' @param object A smooth fit or collection from `growth_smooth()`.
#' @param time Optional numeric prediction times.
#' @param n Number of equally spaced prediction points when `time` is omitted.
#' @return A data frame.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' s <- growth_smooth(d, time="day", response="height_cm", group="water_regime")
#' growth_smooth_predict(s, n=50)
#' growth_smooth_predict(s, time=seq(0,60,by=5))
#' growth_smooth_predict(growth_smooth(d, time="day", response="spad"), n=25)
growth_smooth_predict <- function(object, time = NULL, n = 100L) {
  if (inherits(object, "agri_growth_smooth_collection")) {
    ans <- lapply(object$fits, growth_smooth_predict, time = time, n = n)
    out <- do.call(rbind, ans)
    rownames(out) <- NULL
    return(out)
  }
  if (!inherits(object, "agri_growth_smooth")) stop("`object` must come from `growth_smooth()`.", call. = FALSE)
  if (is.null(time)) time <- seq(object$time_support[[1L]], object$time_support[[2L]], length.out = as.integer(n))
  fitv <- .agf_smooth_predict_one(object, time)
  data.frame(
    time = as.numeric(time),
    fit = fitv,
    group = object$group,
    inside_support = as.numeric(time) >= object$time_support[[1L]] & as.numeric(time) <= object$time_support[[2L]],
    stringsAsFactors = FALSE
  )
}

.agf_fd_numeric <- function(fun, x, support, h, order) {
  lo <- support[[1L]]; hi <- support[[2L]]
  f0 <- fun(x)
  if (order == 1L) {
    if (x - h >= lo && x + h <= hi) return((fun(x + h) - fun(x - h)) / (2 * h))
    if (x + 2 * h <= hi) return((-3 * f0 + 4 * fun(x + h) - fun(x + 2 * h)) / (2 * h))
    if (x - 2 * h >= lo) return((3 * f0 - 4 * fun(x - h) + fun(x - 2 * h)) / (2 * h))
    return(NA_real_)
  }
  if (x - h >= lo && x + h <= hi) return((fun(x + h) - 2 * f0 + fun(x - h)) / h^2)
  if (x + 3 * h <= hi) return((2 * f0 - 5 * fun(x + h) + 4 * fun(x + 2 * h) - fun(x + 3 * h)) / h^2)
  if (x - 3 * h >= lo) return((2 * f0 - 5 * fun(x - h) + 4 * fun(x - 2 * h) - fun(x - 3 * h)) / h^2)
  NA_real_
}

#' Differentiate a flexible growth trajectory
#'
#' @param object A smooth fit or collection.
#' @param order Derivative order, 1 or 2.
#' @param time Optional evaluation times.
#' @param n Evaluation-grid size when `time` is omitted.
#' @param eps Relative finite-difference step for LOESS/GAM/SCAM.
#' @return A data frame with time, fitted response and derivative.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' s <- growth_smooth(d, time="day", response="height_cm", group="water_regime")
#' growth_derivative(s, order=1, n=40)
#' growth_derivative(s, order=2, n=40)
#' growth_derivative(growth_smooth(d, time="day", response="spad"), time=seq(0,60,by=5))
growth_derivative <- function(object, order = 1L, time = NULL, n = 100L, eps = 1e-4) {
  order <- as.integer(order)
  if (!order %in% c(1L, 2L)) stop("`order` must be 1 or 2.", call. = FALSE)
  if (inherits(object, "agri_growth_smooth_collection")) {
    out <- do.call(rbind, lapply(object$fits, growth_derivative, order = order, time = time, n = n, eps = eps))
    rownames(out) <- NULL
    return(out)
  }
  if (!inherits(object, "agri_growth_smooth")) stop("`object` must come from `growth_smooth()`.", call. = FALSE)
  if (is.null(time)) time <- seq(object$time_support[[1L]], object$time_support[[2L]], length.out = as.integer(n))
  time <- as.numeric(time)
  pred <- .agf_smooth_predict_one(object, time)
  if (identical(object$method, "smooth_spline")) {
    der <- as.numeric(stats::predict(object$fit, x = time, deriv = order)$y)
  } else {
    span <- diff(object$time_support)
    h <- max(span * eps, sqrt(.Machine$double.eps) * max(abs(object$time_support), 1))
    fun <- function(z) .agf_smooth_predict_one(object, z)
    der <- vapply(time, function(tt) .agf_fd_numeric(fun, tt, object$time_support, h, order), numeric(1))
  }
  data.frame(time = time, fit = pred, derivative = der, order = order, group = object$group, stringsAsFactors = FALSE)
}

#' Estimate growth acceleration from a flexible trajectory
#' @inheritParams growth_derivative
#' @return A second-derivative data frame.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' s <- growth_smooth(d, time="day", response="height_cm")
#' growth_acceleration(s, n=40)
#' growth_acceleration(s, time=seq(0,60,by=5))
#' growth_acceleration(growth_smooth(d, time="day", response="projected_leaf_area_m2"), n=30)
growth_acceleration <- function(object, time = NULL, n = 100L, eps = 1e-4) {
  growth_derivative(object, order = 2L, time = time, n = n, eps = eps)
}

#' Extract descriptive landmarks from a smooth growth curve
#' @param object A smooth fit or collection.
#' @param n Dense grid size used for numerical landmarks.
#' @return A data frame with maximum rate, peak response, and approximate inflection times.
#' @export
#' @examples
#' d <- growth_example_data("bean_repeated")
#' s <- growth_smooth(d, time="day", response="height_cm", group="water_regime")
#' growth_smooth_traits(s)
#' growth_smooth_traits(growth_smooth(d, time="day", response="projected_leaf_area_m2"), n=200)
#' growth_smooth_traits(growth_smooth(d, time="day", response="spad", method="loess"), n=150)
growth_smooth_traits <- function(object, n = 400L) {
  if (inherits(object, "agri_growth_smooth_collection")) {
    out <- do.call(rbind, lapply(object$fits, growth_smooth_traits, n = n))
    rownames(out) <- NULL
    return(out)
  }
  p <- growth_smooth_predict(object, n = n)
  d1 <- growth_derivative(object, order = 1L, time = p$time)
  d2 <- growth_derivative(object, order = 2L, time = p$time)
  im <- if (all(!is.finite(d1$derivative))) NA_integer_ else which.max(replace(d1$derivative, !is.finite(d1$derivative), -Inf))
  ip <- if (all(!is.finite(p$fit))) NA_integer_ else which.max(replace(p$fit, !is.finite(p$fit), -Inf))
  sgn <- sign(d2$derivative)
  idx <- which(is.finite(sgn[-1L]) & is.finite(sgn[-length(sgn)]) & sgn[-1L] * sgn[-length(sgn)] < 0)
  infl <- if (length(idx)) (d2$time[idx] + d2$time[idx + 1L]) / 2 else numeric()
  data.frame(
    group = object$group,
    maximum_growth_rate = if (is.na(im)) NA_real_ else d1$derivative[[im]],
    time_maximum_growth_rate = if (is.na(im)) NA_real_ else d1$time[[im]],
    peak_response = if (is.na(ip)) NA_real_ else p$fit[[ip]],
    time_peak_response = if (is.na(ip)) NA_real_ else p$time[[ip]],
    n_inflections = length(infl),
    inflection_times = paste(.agf_fmt(infl, digits = 6L), collapse = ";"),
    stringsAsFactors = FALSE
  )
}

#' @export
print.agri_growth_smooth <- function(x, ...) {
  cat("<agri_growth_smooth> method:", x$method, " group:", x$group, "\n")
  cat("Time support:", paste(.agf_fmt(x$time_support), collapse = " to "), " Population mean:", x$population, "\n")
  if (!is.null(x$constraint)) cat("Constraint:", x$constraint, "\n")
  invisible(x)
}

#' @export
print.agri_growth_smooth_collection <- function(x, ...) {
  cat("<agri_growth_smooth_collection> method:", x$method, " groups:", paste(x$groups, collapse = ", "), "\n")
  invisible(x)
}
