.agf_numeric_time <- function(z) {
  if (inherits(z, "Date")) return(as.numeric(z))
  if (inherits(z, c("POSIXct", "POSIXt"))) return(as.numeric(z) / 86400)
  if (!is.numeric(z)) stop("Parametric growth fitting requires a numeric, Date, or POSIX time variable.", call. = FALSE)
  as.numeric(z)
}

.agf_prepare_parametric <- function(x,
                                    time = NULL,
                                    response = NULL,
                                    group = NULL,
                                    aggregate = c("auto", "none", "mean"),
                                    warn_pooling = TRUE,
                                    warn_dependence = TRUE) {
  aggregate <- match.arg(aggregate)
  source_is_growth <- inherits(x, "agri_growth_data")
  sampling <- "unspecified"
  treatment_role <- NULL
  unit <- NULL
  aggregation_note <- "none"

  if (source_is_growth) {
    v <- growth_validate(x, strict = FALSE)
    if (identical(v$status, "error")) {
      stop("The declared growth-data structure contains error-level validation issues. Resolve them before parametric fitting.", call. = FALSE)
    }
    data <- x$data
    time <- time %||% .agf_role(x, "time")
    response <- response %||% .agf_role(x, "total_mass") %||% .agf_role(x, "leaf_area") %||% .agf_role(x, "leaf_mass")
    treatment_role <- .agf_role(x, "treatment")
    sampling <- x$sampling
    unit <- .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot") %||% .agf_role(x, "plant")
  } else {
    .agf_assert_data_frame(x)
    data <- x
    if (is.null(time) || is.null(response)) {
      stop("`time` and `response` are required when `x` is a data frame.", call. = FALSE)
    }
  }

  .agf_assert_column(data, time, "time", allow_null = FALSE)
  .agf_assert_column(data, response, "response", allow_null = FALSE)
  .agf_assert_column(data, group, "group", allow_null = TRUE)
  if (!is.null(unit)) .agf_assert_column(data, unit, "experimental_unit", allow_null = FALSE)
  if (!is.numeric(data[[response]])) stop("The growth response must be numeric.", call. = FALSE)
  if (any(data[[response]] < 0, na.rm = TRUE)) stop("Built-in parametric plant-growth models require non-negative response values.", call. = FALSE)

  keep_cols <- unique(c(time, response, unit, group, treatment_role))
  keep_cols <- keep_cols[!is.na(keep_cols) & nzchar(keep_cols)]
  d <- data[keep_cols]
  keep <- stats::complete.cases(d[c(time, response, unit, group)])
  d <- d[keep, , drop = FALSE]
  if (!nrow(d)) stop("No complete observations remain for parametric growth fitting.", call. = FALSE)

  d$.t <- .agf_numeric_time(d[[time]])
  d$.y <- as.numeric(d[[response]])
  d$.unit <- if (is.null(unit)) ".all" else as.character(d[[unit]])
  d$.group <- if (is.null(group)) ".all" else as.character(d[[group]])

  if (warn_pooling && source_is_growth && is.null(group) && !is.null(treatment_role)) {
    ntrt <- length(unique(d[[treatment_role]]))
    if (ntrt > 1L) {
      warning("Multiple treatment levels are present but `group` was not supplied. The parametric fit pools treatments and should not be interpreted as a treatment comparison.", call. = FALSE)
    }
  }

  do_aggregate <- identical(aggregate, "mean") || (identical(aggregate, "auto") && identical(sampling, "destructive") && !is.null(unit))
  if (do_aggregate) {
    before <- nrow(d)
    keys <- c(".unit", ".group", ".t")
    tmp <- stats::aggregate(d[".y"], by = d[keys], FUN = mean, na.rm = TRUE)
    tmp <- tmp[order(tmp$.group, tmp$.unit, tmp$.t), , drop = FALSE]
    d <- tmp
    aggregation_note <- paste0("mean within persistent unit x group x time: ", before, " -> ", nrow(d), " rows")
  } else {
    d <- d[order(d$.group, d$.unit, d$.t), , drop = FALSE]
  }

  if (nrow(d) < 4L || length(unique(d$.t)) < 4L) {
    stop("Parametric growth fitting requires at least four complete observations at four distinct times.", call. = FALSE)
  }

  if (warn_dependence && source_is_growth) {
    serial_units <- any(table(d$.unit) > 1L)
    if (serial_units && sampling %in% c("repeated", "destructive", "mixed")) {
      warning("Ordinary nonlinear least squares does not model within-unit temporal dependence. Use this fit for curve description or screening, not as a substitute for a hierarchical longitudinal model.", call. = FALSE)
    }
  }

  attr(d, "time_name") <- time
  attr(d, "response_name") <- response
  attr(d, "group_name") <- group
  attr(d, "unit_name") <- unit
  attr(d, "sampling") <- sampling
  attr(d, "aggregation") <- aggregation_note
  d
}

.agf_diff_slope <- function(t, y) {
  ord <- order(t)
  t <- t[ord]
  y <- y[ord]
  ut <- sort(unique(t))
  ym <- vapply(ut, function(tt) mean(y[t == tt], na.rm = TRUE), numeric(1))
  if (length(ut) < 2L) return(numeric())
  dy <- diff(ym) / diff(ut)
  data.frame(tmid = (ut[-1L] + ut[-length(ut)]) / 2, slope = dy)
}

.agf_start_bounds <- function(d, model) {
  model <- .agf_model_alias(model)
  t <- d$.t
  y <- d$.y
  tr <- diff(range(t))
  if (!is.finite(tr) || tr <= 0) tr <- 1
  y_max <- max(y, na.rm = TRUE)
  y_pos <- y[y > 0 & is.finite(y)]
  y_floor <- if (length(y_pos)) min(y_pos) else max(y_max * 1e-4, 1e-8)
  asym0 <- max(y_max * 1.05, y_floor * 2)
  half <- y_max / 2
  mid0 <- t[which.min(abs(y - half))][1L]
  scale0 <- max(tr / 5, tr / 100, .Machine$double.eps)
  tmin <- min(t)
  tmax <- max(t)
  eps_y <- max(y_max, 1) * 1e-8
  eps_t <- max(tr, 1) * 1e-8
  slopes <- .agf_diff_slope(t, y)
  pos_slope <- slopes$slope[is.finite(slopes$slope) & slopes$slope > 0]
  late_slope <- if (length(pos_slope)) max(utils::tail(pos_slope, min(3L, length(pos_slope)))) else max(y_max / tr, eps_y)
  early_rgr <- if (length(y_pos) >= 2L) {
    z <- data.frame(t = t[y > 0], ly = log(y[y > 0]))
    z <- z[order(z$t), , drop = FALSE]
    n0 <- min(4L, nrow(z))
    if (n0 >= 2L) max(stats::coef(stats::lm(ly ~ t, data = z[seq_len(n0), ]))[[2L]], 1 / (100 * tr)) else 1 / tr
  } else 1 / tr
  if (!is.finite(early_rgr) || early_rgr <= 0) early_rgr <- 1 / tr

  out <- switch(model,
    logistic = list(
      start = c(asym = asym0, mid = mid0, scale = scale0),
      lower = c(asym = eps_y, mid = tmin - 3 * tr, scale = eps_t),
      upper = c(asym = max(asym0 * 100, y_max + 1), mid = tmax + 3 * tr, scale = 100 * tr)
    ),
    gompertz = list(
      start = c(asym = asym0, mid = mid0, scale = scale0),
      lower = c(asym = eps_y, mid = tmin - 3 * tr, scale = eps_t),
      upper = c(asym = max(asym0 * 100, y_max + 1), mid = tmax + 3 * tr, scale = 100 * tr)
    ),
    richards = list(
      start = c(asym = asym0, mid = mid0, scale = scale0, shape = 1),
      lower = c(asym = eps_y, mid = tmin - 3 * tr, scale = eps_t, shape = 0.03),
      upper = c(asym = max(asym0 * 100, y_max + 1), mid = tmax + 3 * tr, scale = 100 * tr, shape = 30)
    ),
    chapman_richards = list(
      start = c(asym = asym0, rate = 2 / tr, shape = 2, origin = tmin - 0.05 * tr),
      lower = c(asym = eps_y, rate = 1e-6 / tr, shape = 0.05, origin = tmin - 3 * tr),
      upper = c(asym = max(asym0 * 100, y_max + 1), rate = 100 / tr, shape = 30, origin = tmin + 0.95 * tr)
    ),
    weibull = list(
      start = c(asym = asym0, scale = max(tr / 2, eps_t), shape = 2, origin = tmin - 0.05 * tr),
      lower = c(asym = eps_y, scale = eps_t, shape = 0.05, origin = tmin - 3 * tr),
      upper = c(asym = max(asym0 * 100, y_max + 1), scale = 100 * tr, shape = 30, origin = tmin + 0.95 * tr)
    ),
    von_bertalanffy = list(
      start = c(asym = asym0, rate = 2 / tr, origin = tmin - 0.05 * tr),
      lower = c(asym = eps_y, rate = 1e-6 / tr, origin = tmin - 3 * tr),
      upper = c(asym = max(asym0 * 100, y_max + 1), rate = 100 / tr, origin = tmin + 0.95 * tr)
    ),
    beta_growth = {
      if (min(t) < 0) stop("Automatic beta-growth fitting requires non-negative elapsed time.", call. = FALSE)
      if (length(pos_slope)) {
        im <- which.max(slopes$slope)
        tm0 <- max(0, min(slopes$tmid[im], tmax - 0.05 * tr))
      } else tm0 <- max(0, tmin + 0.55 * tr)
      te0 <- max(tmax + 0.15 * tr, tm0 + 0.2 * tr)
      list(
        start = c(wmax = asym0, tm = tm0, gap = te0 - tm0),
        lower = c(wmax = eps_y, tm = 0, gap = eps_t),
        upper = c(wmax = max(asym0 * 100, y_max + 1), tm = tmax + tr, gap = 10 * tr)
      )
    },
    expolinear = list(
      start = c(cm = max(late_slope, eps_y), rm = max(early_rgr, 1 / (100 * tr)), tb = mid0),
      lower = c(cm = eps_y, rm = 1e-6 / tr, tb = tmin - 5 * tr),
      upper = c(cm = max(100 * max(late_slope, y_max / tr), 1), rm = 100 / tr, tb = tmax + 5 * tr)
    )
  )
  out$model <- model
  out
}

.agf_public_start_object <- function(sb) {
  model <- sb$model
  start <- .agf_internal_to_public(model, sb$start)
  lower <- sb$lower
  upper <- sb$upper
  if (identical(model, "beta_growth")) {
    lower <- c(wmax = lower[["wmax"]], tm = lower[["tm"]], te = lower[["tm"]] + lower[["gap"]])
    upper <- c(wmax = upper[["wmax"]], tm = upper[["tm"]], te = upper[["tm"]] + upper[["gap"]])
  }
  list(start = start, lower = lower, upper = upper)
}

#' Inspect automatic starting values and hard bounds
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param model Built-in model name.
#' @param time,response Column names when `x` is a data frame.
#' @param group Optional grouping column. Starting values are returned for the first
#'   group when supplied; use grouped `growth_fit()` for actual grouped fitting.
#' @param aggregate Destructive-data aggregation rule.
#'
#' @return An object of class `agri_growth_start`.
#' @export
#'
#' @examples
#' d <- growth_example_data("sunflower_sigmoid")
#' growth_start(d, "logistic", time = "day", response = "biomass_g")
#' growth_start(d, "gompertz", time = "day", response = "biomass_g")
#' growth_start(d, "richards", time = "day", response = "biomass_g")
growth_start <- function(x, model, time = NULL, response = NULL, group = NULL,
                         aggregate = c("auto", "none", "mean")) {
  model <- .agf_model_alias(model)
  d <- .agf_prepare_parametric(x, time = time, response = response, group = group,
                               aggregate = aggregate, warn_pooling = FALSE,
                               warn_dependence = FALSE)
  if (!is.null(group) && length(unique(d$.group)) > 1L) {
    d <- d[d$.group == unique(d$.group)[1L], , drop = FALSE]
    warning("`growth_start()` inspected the first group only. Grouped `growth_fit()` estimates each group separately.", call. = FALSE)
  }
  sb <- .agf_start_bounds(d, model)
  pub <- .agf_public_start_object(sb)
  out <- list(
    model = model,
    start = pub$start,
    lower = pub$lower,
    upper = pub$upper,
    internal_start = sb$start,
    internal_lower = sb$lower,
    internal_upper = sb$upper,
    n = nrow(d),
    time_range = range(d$.t),
    response_range = range(d$.y),
    aggregation = attr(d, "aggregation")
  )
  class(out) <- "agri_growth_start"
  out
}

#' @export
print.agri_growth_start <- function(x, ...) {
  cat("<agri_growth_start> model:", x$model, "\n")
  cat("Observations:", x$n, " time support:", paste(.agf_fmt(x$time_range), collapse = " to "), "\n")
  cat("Automatic start:\n")
  print(x$start)
  cat("Public hard bounds:\n")
  print(rbind(lower = x$lower, upper = x$upper))
  invisible(x)
}
