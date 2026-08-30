.agf_public_coef <- function(object) {
  object$coefficients
}

.agf_upper_level <- function(object) {
  cf <- .agf_public_coef(object)
  switch(object$model,
    logistic = unname(cf[["asym"]]),
    gompertz = unname(cf[["asym"]]),
    richards = unname(cf[["asym"]]),
    chapman_richards = unname(cf[["asym"]]),
    weibull = unname(cf[["asym"]]),
    von_bertalanffy = unname(cf[["asym"]]),
    beta_growth = unname(cf[["wmax"]]),
    expolinear = NA_real_
  )
}

.agf_derivative_numeric <- function(object, t) {
  h <- sqrt(.Machine$double.eps) * (abs(t) + diff(object$time_support) + 1)
  h <- max(h, 1e-7)
  yp <- .agf_eval_internal(object$model, t + h, object$coefficients_internal)
  ym <- .agf_eval_internal(object$model, t - h, object$coefficients_internal)
  as.numeric((yp - ym) / (2 * h))
}

.agf_inflection_one <- function(object) {
  cf <- .agf_public_coef(object)
  model <- object$model
  ti <- yi <- NA_real_
  if (model == "logistic") {
    ti <- cf[["mid"]]; yi <- cf[["asym"]] / 2
  } else if (model == "gompertz") {
    ti <- cf[["mid"]]; yi <- cf[["asym"]] / exp(1)
  } else if (model == "richards") {
    ti <- cf[["mid"]]; yi <- cf[["asym"]] * (1 + cf[["shape"]])^(-1 / cf[["shape"]])
  } else if (model == "chapman_richards") {
    if (cf[["shape"]] > 1) {
      ti <- cf[["origin"]] + log(cf[["shape"]]) / cf[["rate"]]
      yi <- cf[["asym"]] * (1 - 1 / cf[["shape"]])^cf[["shape"]]
    }
  } else if (model == "weibull") {
    if (cf[["shape"]] > 1) {
      x <- ((cf[["shape"]] - 1) / cf[["shape"]])^(1 / cf[["shape"]])
      ti <- cf[["origin"]] + cf[["scale"]] * x
      yi <- cf[["asym"]] * (1 - exp(-(cf[["shape"]] - 1) / cf[["shape"]]))
    }
  } else if (model == "von_bertalanffy") {
    ti <- cf[["origin"]] + log(3) / cf[["rate"]]
    yi <- cf[["asym"]] * (2 / 3)^3
  } else if (model == "beta_growth") {
    ti <- cf[["tm"]]
    yi <- .agf_eval_internal(model, ti, object$coefficients_internal)
  }
  data.frame(model = model, inflection_time = as.numeric(ti), inflection_response = as.numeric(yi), stringsAsFactors = FALSE)
}

#' Extract model inflection points
#'
#' @param object Parametric growth fit, fit set, or grouped collection.
#' @return A data frame. Models without a finite interior inflection return `NA`.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' growth_inflection(f)
#' growth_inflection(growth_fit(d, "gompertz", time = "day", response = "biomass_g"))
#' growth_inflection(growth_fit(d, c("logistic", "gompertz"), time = "day", response = "biomass_g"))
growth_inflection <- function(object) {
  if (inherits(object, "agri_growth_fit")) return(.agf_inflection_one(object))
  if (inherits(object, "agri_growth_fit_set")) {
    out <- do.call(rbind, lapply(object$fits, .agf_inflection_one)); rownames(out) <- NULL; return(out)
  }
  if (inherits(object, "agri_growth_fit_collection")) {
    out <- lapply(names(object$fits), function(g) {
      z <- growth_inflection(object$fits[[g]]); z$group <- g; z
    })
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  stop("`object` must be a parametric fit created by growth_fit().", call. = FALSE)
}

.agf_maxrate_one <- function(object) {
  cf <- .agf_public_coef(object)
  model <- object$model
  tm <- rate <- NA_real_
  if (model == "logistic") {
    tm <- cf[["mid"]]; rate <- cf[["asym"]] / (4 * cf[["scale"]])
  } else if (model == "gompertz") {
    tm <- cf[["mid"]]; rate <- cf[["asym"]] / (exp(1) * cf[["scale"]])
  } else if (model == "richards") {
    tm <- cf[["mid"]]
    s <- cf[["shape"]]
    rate <- cf[["asym"]] / cf[["scale"]] * (1 + s)^(-1 / s - 1)
  } else if (model == "chapman_richards") {
    if (cf[["shape"]] > 1) {
      tm <- cf[["origin"]] + log(cf[["shape"]]) / cf[["rate"]]
      rate <- cf[["asym"]] * cf[["rate"]] * (1 - 1 / cf[["shape"]])^(cf[["shape"]] - 1)
    }
  } else if (model == "weibull") {
    if (cf[["shape"]] > 1) {
      k <- cf[["shape"]]
      x <- ((k - 1) / k)^(1 / k)
      tm <- cf[["origin"]] + cf[["scale"]] * x
      rate <- cf[["asym"]] * k / cf[["scale"]] * x^(k - 1) * exp(-x^k)
    }
  } else if (model == "von_bertalanffy") {
    tm <- cf[["origin"]] + log(3) / cf[["rate"]]
    rate <- cf[["asym"]] * cf[["rate"]] * (2 / 3)^2
  } else if (model == "beta_growth") {
    tm <- cf[["tm"]]; rate <- .agf_derivative_numeric(object, tm)
  } else if (model == "expolinear") {
    tm <- Inf; rate <- cf[["cm"]]
  }
  data.frame(model = model, time_maximum_rate = as.numeric(tm), maximum_absolute_rate = as.numeric(rate), stringsAsFactors = FALSE)
}

#' Extract the maximum absolute growth rate implied by a model
#'
#' @inheritParams growth_inflection
#' @return A data frame with maximum absolute rate and its time.
#' @export
#'
#' @examples
#' d <- growth_example_data("wheat_expolinear")
#' d <- subset(d, nitrogen == unique(d$nitrogen)[1])
#' f <- growth_fit(d, "expolinear", time = "day", response = "biomass_g_m2")
#' growth_maxrate(f)
#' growth_maxrate(growth_fit(subset(growth_example_data("sunflower_sigmoid"), cultivar == "C1"), "logistic", time = "day", response = "biomass_g"))
#' growth_maxrate(f)$maximum_absolute_rate
growth_maxrate <- function(object) {
  if (inherits(object, "agri_growth_fit")) return(.agf_maxrate_one(object))
  if (inherits(object, "agri_growth_fit_set")) {
    out <- do.call(rbind, lapply(object$fits, .agf_maxrate_one)); rownames(out) <- NULL; return(out)
  }
  if (inherits(object, "agri_growth_fit_collection")) {
    out <- lapply(names(object$fits), function(g) { z <- growth_maxrate(object$fits[[g]]); z$group <- g; z })
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  stop("`object` must be a parametric fit created by growth_fit().", call. = FALSE)
}

.agf_inverse_target <- function(object, target) {
  cf <- .agf_public_coef(object)
  model <- object$model
  upper <- .agf_upper_level(object)
  target <- as.numeric(target)
  out <- rep(NA_real_, length(target))
  for (i in seq_along(target)) {
    y <- target[[i]]
    if (!is.finite(y) || y < 0) next
    if (is.finite(upper) && y > upper) next
    if (model %in% c("logistic", "gompertz", "richards") && y == 0) {
      out[[i]] <- -Inf; next
    }
    if (model %in% c("chapman_richards", "weibull", "von_bertalanffy") && y == 0) {
      out[[i]] <- cf[["origin"]]; next
    }
    if (model == "beta_growth" && y == 0) {
      out[[i]] <- 0; next
    }
    if (model == "expolinear" && y == 0) {
      out[[i]] <- -Inf; next
    }
    if (is.finite(upper) && y == upper) {
      out[[i]] <- if (model == "beta_growth") cf[["te"]] else Inf
      next
    }
    if (model == "logistic") {
      out[[i]] <- cf[["mid"]] - cf[["scale"]] * log(cf[["asym"]] / y - 1)
    } else if (model == "gompertz") {
      out[[i]] <- cf[["mid"]] - cf[["scale"]] * log(-log(y / cf[["asym"]]))
    } else if (model == "richards") {
      z <- ((cf[["asym"]] / y)^cf[["shape"]] - 1) / cf[["shape"]]
      out[[i]] <- cf[["mid"]] - cf[["scale"]] * log(z)
    } else if (model == "chapman_richards") {
      out[[i]] <- cf[["origin"]] - log(1 - (y / cf[["asym"]])^(1 / cf[["shape"]])) / cf[["rate"]]
    } else if (model == "weibull") {
      out[[i]] <- cf[["origin"]] + cf[["scale"]] * (-log(1 - y / cf[["asym"]]))^(1 / cf[["shape"]])
    } else if (model == "von_bertalanffy") {
      out[[i]] <- cf[["origin"]] - log(1 - (y / cf[["asym"]])^(1 / 3)) / cf[["rate"]]
    } else if (model == "beta_growth") {
      f <- function(tt) .agf_eval_internal(model, tt, object$coefficients_internal) - y
      out[[i]] <- tryCatch(stats::uniroot(f, interval = c(0, cf[["te"]]), tol = 1e-10)$root, error = function(e) NA_real_)
    } else if (model == "expolinear") {
      z <- y * cf[["rm"]] / cf[["cm"]]
      out[[i]] <- cf[["tb"]] + .agf_log_expm1(z) / cf[["rm"]]
    }
  }
  out
}

#' Time required to reach fractional or absolute growth targets
#'
#' @param object Parametric growth fit, fit set, or grouped collection.
#' @param fraction Optional fractions of a finite upper level, between 0 and 1.
#' @param target Optional absolute response targets. Supply exactly one of `fraction` or `target`.
#'
#' @return A data frame with target values and corresponding times.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' growth_time_to(f, fraction = c(0.1, 0.5, 0.9))
#' growth_time_to(f, target = c(50, 100))
#' growth_time_to(f, target = 0)
growth_time_to <- function(object, fraction = NULL, target = NULL) {
  if (!xor(is.null(fraction), is.null(target))) stop("Supply exactly one of `fraction` or `target`.", call. = FALSE)
  if (inherits(object, "agri_growth_fit_set")) {
    out <- lapply(object$fits, function(f) growth_time_to(f, fraction = fraction, target = target))
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  if (inherits(object, "agri_growth_fit_collection")) {
    out <- lapply(names(object$fits), function(g) { z <- growth_time_to(object$fits[[g]], fraction = fraction, target = target); z$group <- g; z })
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  if (!inherits(object, "agri_growth_fit")) stop("`object` must be a parametric fit created by growth_fit().", call. = FALSE)
  if (!is.null(fraction)) {
    if (!is.numeric(fraction) || any(!is.finite(fraction)) || any(fraction < 0 | fraction > 1)) stop("`fraction` must contain values between 0 and 1.", call. = FALSE)
    upper <- .agf_upper_level(object)
    if (!is.finite(upper)) stop("Fractional upper-level targets are undefined for this model. Use absolute `target` values instead.", call. = FALSE)
    target <- fraction * upper
    out <- data.frame(model = object$model, target_type = "fraction", fraction = fraction, target = target, time = .agf_inverse_target(object, target), stringsAsFactors = FALSE)
  } else {
    if (!is.numeric(target) || any(!is.finite(target)) || any(target < 0)) stop("`target` must contain finite non-negative values.", call. = FALSE)
    out <- data.frame(model = object$model, target_type = "absolute", fraction = NA_real_, target = target, time = .agf_inverse_target(object, target), stringsAsFactors = FALSE)
  }
  out
}

.agf_auc_observed <- function(object) {
  lo <- object$time_support[[1L]]; hi <- object$time_support[[2L]]
  f <- function(tt) .agf_eval_internal(object$model, tt, object$coefficients_internal)
  tryCatch(stats::integrate(f, lower = lo, upper = hi, subdivisions = 200L, stop.on.error = FALSE)$value, error = function(e) NA_real_)
}

.agf_traits_one <- function(object) {
  infl <- .agf_inflection_one(object)
  rate <- .agf_maxrate_one(object)
  upper <- .agf_upper_level(object)
  tt <- if (is.finite(upper)) growth_time_to(object, fraction = c(0.1, 0.5, 0.9))$time else rep(NA_real_, 3L)
  data.frame(
    model = object$model,
    asymptote = upper,
    inflection_time = infl$inflection_time,
    inflection_response = infl$inflection_response,
    maximum_absolute_rate = rate$maximum_absolute_rate,
    time_maximum_rate = rate$time_maximum_rate,
    t10 = tt[[1L]],
    t50 = tt[[2L]],
    t90 = tt[[3L]],
    auc_observed_support = .agf_auc_observed(object),
    support_min = object$time_support[[1L]],
    support_max = object$time_support[[2L]],
    stringsAsFactors = FALSE
  )
}

#' Extract common biologically interpretable growth traits
#'
#' @inheritParams growth_inflection
#'
#' @description
#' The trait table standardizes model-specific coefficients into common landmarks.
#' Area under the curve is integrated only across the observed time support. The
#' function does not fabricate finite-asymptote targets for expolinear growth.
#'
#' @return A data frame.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' d <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
#' growth_traits(f)
#' growth_traits(growth_fit(d, c("logistic", "gompertz"), time = "day", response = "biomass_g"))
#' growth_traits(f)[, c("t10", "t50", "t90")]
growth_traits <- function(object) {
  if (inherits(object, "agri_growth_fit")) return(.agf_traits_one(object))
  if (inherits(object, "agri_growth_fit_set")) {
    out <- do.call(rbind, lapply(object$fits, .agf_traits_one)); rownames(out) <- NULL; return(out)
  }
  if (inherits(object, "agri_growth_fit_collection")) {
    out <- lapply(names(object$fits), function(g) {
      fit <- object$fits[[g]]
      z <- if (inherits(fit, "agri_growth_fit_set")) growth_traits(fit) else .agf_traits_one(fit)
      z$group <- g
      z
    })
    ans <- do.call(rbind, out); rownames(ans) <- NULL; return(ans)
  }
  stop("`object` must be a parametric fit created by growth_fit().", call. = FALSE)
}
