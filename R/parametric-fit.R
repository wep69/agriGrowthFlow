.agf_nls_formula <- function(model) {
  model <- .agf_model_alias(model)
  txt <- switch(model,
    logistic = ".y ~ .agf_logistic(.t, asym, mid, scale)",
    gompertz = ".y ~ .agf_gompertz(.t, asym, mid, scale)",
    richards = ".y ~ .agf_richards(.t, asym, mid, scale, shape)",
    chapman_richards = ".y ~ .agf_chapman_richards(.t, asym, rate, shape, origin)",
    weibull = ".y ~ .agf_weibull(.t, asym, scale, shape, origin)",
    von_bertalanffy = ".y ~ .agf_von_bertalanffy(.t, asym, rate, origin)",
    beta_growth = ".y ~ .agf_beta_internal(.t, wmax, tm, gap)",
    expolinear = ".y ~ .agf_expolinear(.t, cm, rm, tb)"
  )
  stats::as.formula(txt, env = environment())
}

.agf_clip_inside <- function(x, lower, upper) {
  span <- upper - lower
  eps <- pmax(abs(span) * 1e-8, 1e-10)
  pmin(pmax(x, lower + eps), upper - eps)
}

.agf_check_start <- function(start, lower, upper, model) {
  needed <- names(lower)
  if (is.null(names(start)) || !all(needed %in% names(start))) {
    stop("Starting values for `", model, "` must contain: ", paste(needed, collapse = ", "), ".", call. = FALSE)
  }
  start <- start[needed]
  if (any(!is.finite(start))) stop("Starting values must be finite.", call. = FALSE)
  if (any(start <= lower | start >= upper)) {
    stop("Starting values must lie strictly inside the hard parameter bounds.", call. = FALSE)
  }
  start
}

.agf_random_starts <- function(base, lower, upper, n_start, seed = NULL) {
  if (!is.null(seed)) {
    .agf_restore_rng <- .agf_seed_snapshot(); on.exit(.agf_restore_rng(), add = TRUE)
    set.seed(seed)
  }
  n_start <- as.integer(n_start)
  if (!is.finite(n_start) || n_start < 1L) stop("`n_start` must be a positive integer.", call. = FALSE)
  starts <- vector("list", n_start)
  starts[[1L]] <- base
  if (n_start == 1L) return(starts)
  for (i in 2:n_start) {
    z <- base
    for (j in seq_along(z)) {
      lo <- lower[[j]]
      hi <- upper[[j]]
      b <- base[[j]]
      if (lo > 0 && b > 0 && is.finite(hi) && hi / lo > 100) {
        sdlog <- 0.7
        cand <- exp(stats::rnorm(1L, log(b), sdlog))
      } else {
        width <- min((hi - lo) / 4, max(abs(b), 1) * 0.8)
        if (!is.finite(width) || width <= 0) width <- (hi - lo) / 6
        cand <- stats::rnorm(1L, b, width)
      }
      z[[j]] <- .agf_clip_inside(cand, lo, hi)
    }
    starts[[i]] <- z
  }
  starts
}

.agf_fit_attempt <- function(d, model, start, lower, upper, engine, control = list()) {
  f <- .agf_nls_formula(model)
  warnings <- character()
  err <- NULL
  fit <- withCallingHandlers(
    tryCatch({
      if (identical(engine, "minpack.lm")) {
        if (!requireNamespace("minpack.lm", quietly = TRUE)) {
          stop("Engine `minpack.lm` was requested but package minpack.lm is not installed.")
        }
        lm_control <- if (length(control)) do.call(minpack.lm::nls.lm.control, control) else minpack.lm::nls.lm.control()
        minpack.lm::nlsLM(formula = f, data = d, start = as.list(start), lower = lower, upper = upper, control = lm_control)
      } else {
        nls_control <- do.call(stats::nls.control, modifyList(list(maxiter = 500, warnOnly = TRUE), control))
        stats::nls(f, data = d, start = as.list(start), algorithm = "port", lower = lower, upper = upper, control = nls_control)
      }
    }, error = function(e) {
      err <<- conditionMessage(e)
      NULL
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  converged <- FALSE
  rss <- Inf
  if (!is.null(fit)) {
    pred <- tryCatch(stats::predict(fit), error = function(e) rep(NA_real_, nrow(d)))
    rss <- if (all(is.finite(pred))) sum((d$.y - pred)^2) else Inf
    conv <- tryCatch(fit$convInfo$isConv, error = function(e) TRUE)
    converged <- isTRUE(conv) && is.finite(rss)
  }
  list(fit = fit, converged = converged, rss = rss, warnings = warnings, error = err)
}

.agf_build_fit <- function(d, model, best, attempts, lower, upper, engine, aggregation, sampling, unit_name) {
  fit <- best$fit
  pars_int <- stats::coef(fit)
  vc <- tryCatch(stats::vcov(fit), error = function(e) matrix(NA_real_, length(pars_int), length(pars_int), dimnames = list(names(pars_int), names(pars_int))))
  resid <- d$.y - as.numeric(stats::predict(fit))
  n <- nrow(d)
  k <- length(pars_int)
  df_resid <- max(n - k, 1L)
  sigma <- sqrt(sum(resid^2) / df_resid)
  out <- list(
    model = model,
    fit = fit,
    data = d,
    coefficients_internal = pars_int,
    coefficients = .agf_internal_to_public(model, pars_int),
    vcov_internal = vc,
    residuals = resid,
    fitted = d$.y - resid,
    sigma = sigma,
    df_residual = df_resid,
    rss = sum(resid^2),
    n = n,
    k = k,
    engine = engine,
    lower_internal = lower,
    upper_internal = upper,
    attempts = attempts,
    aggregation = aggregation,
    sampling = sampling,
    unit_name = unit_name,
    observation_key = paste(format(d$.t, digits = 17), format(d$.y, digits = 17), d$.unit, d$.group, sep = "|", collapse = "\n"),
    time_support = range(d$.t),
    response_support = range(d$.y)
  )
  class(out) <- "agri_growth_fit"
  out
}

.agf_fit_one <- function(d, model, start = NULL, n_start = 1L, seed = NULL,
                         engine = c("auto", "nls", "minpack.lm"), control = list()) {
  model <- .agf_model_alias(model)
  engine <- match.arg(engine)
  if (identical(engine, "auto")) engine <- if (requireNamespace("minpack.lm", quietly = TRUE)) "minpack.lm" else "nls"
  sb <- .agf_start_bounds(d, model)
  if (!is.null(start)) {
    start_int <- .agf_public_to_internal(model, start)
  } else start_int <- sb$start
  start_int <- .agf_check_start(start_int, sb$lower, sb$upper, model)
  starts <- .agf_random_starts(start_int, sb$lower, sb$upper, n_start = n_start, seed = seed)

  attempt_rows <- vector("list", length(starts))
  attempt_objs <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    a <- .agf_fit_attempt(d, model, starts[[i]], sb$lower, sb$upper, engine = engine, control = control)
    attempt_objs[[i]] <- a
    row <- data.frame(
      attempt = i,
      converged = a$converged,
      rss = a$rss,
      warning = paste(a$warnings, collapse = " | "),
      error = a$error %||% "",
      stringsAsFactors = FALSE
    )
    for (nm in names(starts[[i]])) row[[paste0("start_", nm)]] <- starts[[i]][[nm]]
    attempt_rows[[i]] <- row
  }
  attempts <- do.call(rbind, attempt_rows)
  good <- which(vapply(attempt_objs, function(a) isTRUE(a$converged) && is.finite(a$rss), logical(1)))
  if (!length(good)) {
    msg <- unique(c(attempts$error[nzchar(attempts$error)], attempts$warning[nzchar(attempts$warning)]))
    stop("No fitting attempt converged for model `", model, "`.", if (length(msg)) paste0(" Last messages: ", paste(utils::tail(msg, 3L), collapse = " | ")) else "", call. = FALSE)
  }
  rss <- vapply(attempt_objs[good], `[[`, numeric(1), "rss")
  best_idx <- good[which.min(rss)]
  .agf_build_fit(
    d, model, best = attempt_objs[[best_idx]], attempts = attempts,
    lower = sb$lower, upper = sb$upper, engine = engine,
    aggregation = attr(d, "aggregation"), sampling = attr(d, "sampling"),
    unit_name = attr(d, "unit_name")
  )
}

#' Fit parametric plant-growth models
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param model One or more built-in model names.
#' @param time,response Column names when `x` is a data frame.
#' @param group Optional grouping column for separate descriptive curves.
#' @param start Optional named public starting values for a single model.
#' @param n_start Number of fitting starts per model and group.
#' @param seed Optional reproducibility seed.
#' @param engine One of `"auto"`, `"nls"`, or `"minpack.lm"`.
#' @param aggregate Destructive-data aggregation rule.
#' @param control Optional engine control list.
#'
#' @return An `agri_growth_fit`, `agri_growth_fit_set`, or `agri_growth_fit_collection`.
#' @export
#'
#' @examples
#' # 1) A logistic fit
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' coef(f)
#'
#' # 2) Several models in one call
#' fs <- growth_fit(d1, c("logistic", "gompertz"), time = "day", response = "biomass_g")
#' fs$models
#'
#' # 3) One fit per group
#' fc <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
#'                  group = "cultivar")
#' fc$groups
growth_fit <- function(x,
                       model = "logistic",
                       time = NULL,
                       response = NULL,
                       group = NULL,
                       start = NULL,
                       n_start = 1L,
                       seed = NULL,
                       engine = c("auto", "nls", "minpack.lm"),
                       aggregate = c("auto", "none", "mean"),
                       control = list()) {
  engine <- match.arg(engine)
  aggregate <- match.arg(aggregate)
  if (!is.character(model) || !length(model)) stop("`model` must contain one or more built-in model names.", call. = FALSE)
  models <- unique(vapply(model, .agf_model_alias, character(1)))
  if (length(models) > 1L && !is.null(start)) stop("Supply `start` only when fitting one model at a time.", call. = FALSE)

  d <- .agf_prepare_parametric(x, time = time, response = response, group = group,
                               aggregate = aggregate, warn_pooling = TRUE,
                               warn_dependence = TRUE)

  if (!is.null(group)) {
    lev <- unique(d$.group)
    fits <- vector("list", length(lev))
    names(fits) <- lev
    for (i in seq_along(lev)) {
      dg <- d[d$.group == lev[[i]], , drop = FALSE]
      for (at in c("time_name", "response_name", "group_name", "unit_name", "sampling", "aggregation")) attr(dg, at) <- attr(d, at)
      if (nrow(dg) < 4L || length(unique(dg$.t)) < 4L) {
        stop("Group `", lev[[i]], "` does not contain at least four observations at four distinct times.", call. = FALSE)
      }
      if (length(models) == 1L) {
        fits[[i]] <- .agf_fit_one(dg, models[[1L]], start = start, n_start = n_start,
                                  seed = if (is.null(seed)) NULL else seed + i - 1L,
                                  engine = engine, control = control)
      } else {
        sfits <- lapply(seq_along(models), function(j) .agf_fit_one(
          dg, models[[j]], n_start = n_start,
          seed = if (is.null(seed)) NULL else seed + i * 1000L + j,
          engine = engine, control = control
        ))
        names(sfits) <- models
        z <- list(fits = sfits, models = models, data = dg, group = lev[[i]])
        class(z) <- "agri_growth_fit_set"
        fits[[i]] <- z
      }
    }
    out <- list(fits = fits, group = group, groups = lev, models = models, data = d)
    class(out) <- "agri_growth_fit_collection"
    return(out)
  }

  if (length(models) == 1L) {
    return(.agf_fit_one(d, models[[1L]], start = start, n_start = n_start,
                        seed = seed, engine = engine, control = control))
  }
  fits <- lapply(seq_along(models), function(i) .agf_fit_one(
    d, models[[i]], n_start = n_start,
    seed = if (is.null(seed)) NULL else seed + i - 1L,
    engine = engine, control = control
  ))
  names(fits) <- models
  out <- list(fits = fits, models = models, data = d)
  class(out) <- "agri_growth_fit_set"
  out
}

#' Explicit multistart nonlinear growth fitting
#'
#' @inheritParams growth_fit
#' @param n_start Number of starts; defaults to 30.
#' @return Same fit classes as `growth_fit()`.
#' @export
#'
#' @examples
#' # 1) Several starting values and the best fit
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' fm <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
#'                         n_start = 10, seed = 1)
#' sum(fm$attempts$converged)
#'
#' # 2) A fixed seed makes the result reproducible
#' a <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
#'                        n_start = 5, seed = 42)
#' b <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
#'                        n_start = 5, seed = 42)
#' identical(coef(a), coef(b))
#'
#' # 3) An explicit starting point
#' growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
#'                   start = list(asym = 220, mid = 55, scale = 12), n_start = 3)
growth_multistart <- function(x, model = "logistic", time = NULL, response = NULL,
                              group = NULL, start = NULL, n_start = 30L, seed = NULL,
                              engine = c("auto", "nls", "minpack.lm"),
                              aggregate = c("auto", "none", "mean"), control = list()) {
  growth_fit(x, model = model, time = time, response = response, group = group,
             start = start, n_start = n_start, seed = seed, engine = engine,
             aggregate = aggregate, control = control)
}

#' @export
#' @examples
#' # 1) Named coefficients
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' coef(f)
#'
#' # 2) Access by name
#' coef(f)[["asym"]]
#'
#' # 3) Rounded vector
#' round(coef(f), 3)
coef.agri_growth_fit <- function(object, ...) {
  object$coefficients
}

#' @export
#' @examples
#' # 1) Fit summary
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
#' print(f)
#'
#' # 2) Main components
#' c(n = f$n, rss = f$rss, sigma = f$sigma)
#'
#' # 3) Invisible return
#' identical(print(f), f)
print.agri_growth_fit <- function(x, ...) {
  cat("<agri_growth_fit> model:", x$model, " engine:", x$engine, "\n")
  cat("Observations:", x$n, " RSS:", .agf_fmt(x$rss), " sigma:", .agf_fmt(x$sigma), "\n")
  cat("Aggregation:", x$aggregation, "\n")
  print(x$coefficients)
  cat("Multistart:", sum(x$attempts$converged), "of", nrow(x$attempts), "attempts converged\n")
  invisible(x)
}

#' @export
#' @examples
#' # 1) A set of models
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' fs <- growth_fit(d1, c("logistic", "gompertz"), time = "day", response = "biomass_g")
#' print(fs)
#'
#' # 2) Access one fit of the set
#' class(fs$fits[["logistic"]])
#'
#' # 3) Invisible return
#' identical(print(fs), fs)
print.agri_growth_fit_set <- function(x, ...) {
  cat("<agri_growth_fit_set> models:", paste(x$models, collapse = ", "), "\n")
  tab <- data.frame(
    model = names(x$fits),
    n = vapply(x$fits, `[[`, numeric(1), "n"),
    rss = vapply(x$fits, `[[`, numeric(1), "rss"),
    stringsAsFactors = FALSE
  )
  print(tab, row.names = FALSE)
  invisible(x)
}

#' @export
#' @examples
#' # 1) A collection by group
#' d <- growth_example_data("sunflower_sigmoid")
#' fc <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
#'                  group = "cultivar")
#' print(fc)
#'
#' # 2) Groups and one specific fit
#' fc$groups
#' coef(fc$fits[[1]])
#'
#' # 3) Invisible return
#' identical(print(fc), fc)
print.agri_growth_fit_collection <- function(x, ...) {
  cat("<agri_growth_fit_collection> group:", x$group, "\n")
  cat("Groups:", paste(x$groups, collapse = ", "), "\n")
  cat("Models:", paste(x$models, collapse = ", "), "\n")
  invisible(x)
}
