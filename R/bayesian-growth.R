.agf_require_brms <- function() {
  if (!requireNamespace("brms", quietly = TRUE)) {
    stop("Bayesian growth analysis requires the optional `brms` package.", call. = FALSE)
  }
}

.agf_require_posterior <- function() {
  if (!requireNamespace("posterior", quietly = TRUE)) {
    stop("Posterior diagnostics require the optional `posterior` package.", call. = FALSE)
  }
}

.agf_require_loo <- function() {
  if (!requireNamespace("loo", quietly = TRUE)) {
    stop("LOO evaluation and model weighting require the optional `loo` package.", call. = FALSE)
  }
}

.agf_bayes_supported_models <- function() c("logistic", "gompertz", "richards")

.agf_bayes_check_model <- function(model) {
  model <- .agf_model_alias(model)
  if (!model %in% .agf_bayes_supported_models()) {
    stop(
      "The 0.4.0 Bayesian layer supports logistic, Gompertz, and Richards models. `",
      model,
      "` remains available through frequentist and bootstrap workflows until a constrained Stan parameterization is validated for that family.",
      call. = FALSE
    )
  }
  model
}

.agf_bayes_nlpars <- function(model) {
  model <- .agf_bayes_check_model(model)
  switch(model,
    logistic = c("logAsym", "mid", "logScale"),
    gompertz = c("logAsym", "mid", "logScale"),
    richards = c("logAsym", "mid", "logScale", "logShape")
  )
}

.agf_bayes_main_formula <- function(model) {
  model <- .agf_bayes_check_model(model)
  txt <- switch(model,
    logistic = "agf_y ~ exp(logAsym) / (1 + exp(-(agf_time - mid) / exp(logScale)))",
    gompertz = "agf_y ~ exp(logAsym) * exp(-exp(-(agf_time - mid) / exp(logScale)))",
    richards = "agf_y ~ exp(logAsym) * (1 + exp(logShape) * exp(-(agf_time - mid) / exp(logScale)))^(-1 / exp(logShape))"
  )
  stats::as.formula(txt)
}

.agf_prepare_bayes <- function(x,
                               time = NULL,
                               response = NULL,
                               group = NULL,
                               unit = NULL,
                               aggregate = c("auto", "none", "mean")) {
  aggregate <- match.arg(aggregate)
  source_is_growth <- inherits(x, "agri_growth_data")

  if (source_is_growth) {
    group <- group %||% .agf_role(x, "treatment")
    if (!is.null(unit)) {
      warning("`unit` is ignored for an `agri_growth_data` object; its declared persistent experimental unit is used.", call. = FALSE)
    }
    d <- .agf_prepare_parametric(
      x,
      time = time,
      response = response,
      group = group,
      aggregate = aggregate,
      warn_pooling = FALSE,
      warn_dependence = FALSE
    )
  } else {
    .agf_assert_data_frame(x)
    if (is.null(time) || is.null(response)) {
      stop("`time` and `response` are required when `x` is a data frame.", call. = FALSE)
    }
    .agf_assert_column(x, time, "time", allow_null = FALSE)
    .agf_assert_column(x, response, "response", allow_null = FALSE)
    .agf_assert_column(x, group, "group", allow_null = TRUE)
    .agf_assert_column(x, unit, "unit", allow_null = TRUE)
    if (!is.null(unit)) {
      gx <- growth_data(
        x,
        time = time,
        sampling = "repeated",
        experimental_unit = unit,
        treatment = group,
        total_mass = response
      )
      d <- .agf_prepare_parametric(
        gx,
        time = time,
        response = response,
        group = group,
        aggregate = aggregate,
        warn_pooling = FALSE,
        warn_dependence = FALSE
      )
    } else {
      d <- .agf_prepare_parametric(
        x,
        time = time,
        response = response,
        group = group,
        aggregate = aggregate,
        warn_pooling = FALSE,
        warn_dependence = FALSE
      )
    }
  }

  out <- data.frame(
    agf_y = as.numeric(d$.y),
    agf_time = as.numeric(d$.t),
    agf_group = factor(as.character(d$.group)),
    agf_unit = factor(as.character(d$.unit)),
    stringsAsFactors = FALSE
  )
  attr(out, "time_name") <- attr(d, "time_name")
  attr(out, "response_name") <- attr(d, "response_name")
  attr(out, "group_name") <- attr(d, "group_name")
  attr(out, "unit_name") <- attr(d, "unit_name")
  attr(out, "sampling") <- attr(d, "sampling")
  attr(out, "aggregation") <- attr(d, "aggregation")
  out
}

.agf_bayes_has_group <- function(d) length(levels(d$agf_group)) > 1L
.agf_bayes_has_unit <- function(d) length(levels(d$agf_unit)) > 1L && any(table(d$agf_unit) > 1L)

.agf_bayes_random_nlpars <- function(model, random, has_unit) {
  nlpars <- .agf_bayes_nlpars(model)
  if (!has_unit) return(character())
  random <- match.arg(random, c("auto", "none", "asym", "timing", "all"))
  if (identical(random, "auto")) random <- "asym"
  switch(random,
    none = character(),
    asym = intersect("logAsym", nlpars),
    timing = intersect("mid", nlpars),
    all = nlpars
  )
}

.agf_bayes_default_nlpar_formulas <- function(model, d, group_effects = c("auto", "none", "all"), random = c("auto", "none", "asym", "timing", "all")) {
  group_effects <- match.arg(group_effects)
  random <- match.arg(random)
  has_group <- .agf_bayes_has_group(d)
  has_unit <- .agf_bayes_has_unit(d)
  if (identical(group_effects, "auto")) group_effects <- if (has_group) "all" else "none"
  random_nlpars <- .agf_bayes_random_nlpars(model, random, has_unit)
  nlpars <- .agf_bayes_nlpars(model)
  out <- vector("list", length(nlpars)); names(out) <- nlpars
  for (p in nlpars) {
    rhs <- "1"
    if (identical(group_effects, "all") && has_group) rhs <- paste(rhs, "+ agf_group")
    if (p %in% random_nlpars) rhs <- paste(rhs, "+ (1 | agf_unit)")
    out[[p]] <- stats::as.formula(paste(p, "~", rhs))
  }
  out
}

.agf_bayes_merge_nlpar_formulas <- function(model, defaults, nlpar_formulas = NULL) {
  if (is.null(nlpar_formulas)) return(defaults)
  if (!is.list(nlpar_formulas) || is.null(names(nlpar_formulas))) {
    stop("`nlpar_formulas` must be a named list indexed by nonlinear parameter name.", call. = FALSE)
  }
  valid <- .agf_bayes_nlpars(model)
  bad <- setdiff(names(nlpar_formulas), valid)
  if (length(bad)) stop("Unknown nonlinear parameter formula names: ", paste(bad, collapse = ", "), ".", call. = FALSE)
  for (nm in names(nlpar_formulas)) {
    f <- nlpar_formulas[[nm]]
    if (is.character(f) && length(f) == 1L) {
      if (grepl("~", f, fixed = TRUE)) defaults[[nm]] <- stats::as.formula(f)
      else defaults[[nm]] <- stats::as.formula(paste(nm, "~", f))
    } else if (inherits(f, "formula")) {
      defaults[[nm]] <- f
    } else {
      stop("Each `nlpar_formulas` entry must be a formula or one formula string.", call. = FALSE)
    }
  }
  defaults
}

.agf_prior_template <- function(t, y, model) {
  tr <- diff(range(t))
  if (!is.finite(tr) || tr <= 0) tr <- 1
  ymax <- max(y, na.rm = TRUE)
  if (!is.finite(ymax) || ymax <= 0) ymax <- 1
  mid0 <- stats::median(t)
  rows <- list(
    data.frame(nlpar = "logAsym", role = "intercept", class = "b", coef = "Intercept",
               prior = paste0("normal(", signif(log(1.1 * ymax), 6), ", 0.7)"),
               transformation = "asym = exp(logAsym)", stringsAsFactors = FALSE),
    data.frame(nlpar = "logAsym", role = "non_intercept", class = "b", coef = NA_character_,
               prior = "normal(0, 0.5)", transformation = "asym = exp(logAsym)", stringsAsFactors = FALSE),
    data.frame(nlpar = "mid", role = "intercept", class = "b", coef = "Intercept",
               prior = paste0("normal(", signif(mid0, 6), ", ", signif(max(tr / 2, 1e-3), 6), ")"),
               transformation = "mid = mid", stringsAsFactors = FALSE),
    data.frame(nlpar = "mid", role = "non_intercept", class = "b", coef = NA_character_,
               prior = paste0("normal(0, ", signif(max(tr / 3, 1e-3), 6), ")"),
               transformation = "mid = mid", stringsAsFactors = FALSE),
    data.frame(nlpar = "logScale", role = "intercept", class = "b", coef = "Intercept",
               prior = paste0("normal(", signif(log(max(tr / 5, 1e-3)), 6), ", 1)"),
               transformation = "scale = exp(logScale)", stringsAsFactors = FALSE),
    data.frame(nlpar = "logScale", role = "non_intercept", class = "b", coef = NA_character_,
               prior = "normal(0, 0.5)", transformation = "scale = exp(logScale)", stringsAsFactors = FALSE)
  )
  if (identical(model, "richards")) {
    rows <- c(rows, list(
      data.frame(nlpar = "logShape", role = "intercept", class = "b", coef = "Intercept",
                 prior = "normal(0, 0.7)", transformation = "shape = exp(logShape)", stringsAsFactors = FALSE),
      data.frame(nlpar = "logShape", role = "non_intercept", class = "b", coef = NA_character_,
                 prior = "normal(0, 0.5)", transformation = "shape = exp(logShape)", stringsAsFactors = FALSE)
    ))
  }
  do.call(rbind, rows)
}

#' Construct weakly informative priors for Bayesian plant-growth curves
#'
#' @param x Optional growth data object, data frame, or `agri_growth_fit` used to
#'   scale priors to the observed response and time ranges.
#' @param model Bayesian-supported model name.
#' @param time,response Column names when `x` is a data frame.
#' @param group Optional treatment/group column used only to prepare the same
#'   design-aware analysis data.
#' @param unit Optional persistent-unit column when `x` is a data frame.
#' @param aggregate Destructive-data aggregation rule.
#'
#' @description
#' The Bayesian layer uses log-transformed positive nonlinear parameters so that
#' asymptotes, scale parameters, and the Richards shape remain positive without
#' hard truncation. Priors are returned on those transformed predictors. They are
#' starting templates, not universal agronomic priors, and should be checked with
#' prior predictive simulation for each scientific application.
#'
#' @return An object of class `agri_growth_prior`, also a data frame.
#' @export
#'
#' @examples
#' # 1) Logistic priors
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' growth_prior(d1, "logistic", time = "day", response = "biomass_g")
#'
#' # 2) Another model
#' growth_prior(d1, "gompertz", time = "day", response = "biomass_g")
#'
#' # 3) A model with a shape parameter
#' growth_prior(d1, "richards", time = "day", response = "biomass_g")
growth_prior <- function(x = NULL,
                         model = "logistic",
                         time = NULL,
                         response = NULL,
                         group = NULL,
                         unit = NULL,
                         aggregate = c("auto", "none", "mean")) {
  model <- .agf_bayes_check_model(model)
  aggregate <- match.arg(aggregate)
  if (inherits(x, "agri_growth_fit")) {
    t <- x$data$.t; y <- x$data$.y
  } else if (!is.null(x)) {
    d <- .agf_prepare_bayes(x, time = time, response = response, group = group, unit = unit, aggregate = aggregate)
    t <- d$agf_time; y <- d$agf_y
  } else {
    t <- c(0, 1); y <- c(0.1, 1)
  }
  out <- .agf_prior_template(t, y, model)
  out$model <- model
  out <- out[, c("model", "nlpar", "role", "class", "coef", "prior", "transformation")]
  class(out) <- c("agri_growth_prior", "data.frame")
  out
}

#' @export
#' @examples
#' # 1) Prior table
#' d <- growth_example_data("sunflower_sigmoid")
#' d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#' pr <- growth_prior(d1, "logistic", time = "day", response = "biomass_g")
#' print(pr)
#'
#' # 2) Subset of rows
#' pr[pr$role == "intercept", c("nlpar", "prior")]
#'
#' # 3) Invisible return
#' identical(print(pr), pr)
print.agri_growth_prior <- function(x, ...) {
  cat("<agri_growth_prior> model:", unique(x$model), "\n")
  print.data.frame(x, row.names = FALSE)
  invisible(x)
}

.agf_prior_to_brms <- function(prior) {
  .agf_require_brms()
  if (inherits(prior, "brmsprior")) return(prior)
  if (!inherits(prior, "agri_growth_prior")) {
    stop("`prior` must be created by growth_prior() or be a `brmsprior` object.", call. = FALSE)
  }
  pieces <- vector("list", nrow(prior))
  for (i in seq_len(nrow(prior))) {
    args <- list(prior = prior$prior[[i]], class = prior$class[[i]], nlpar = prior$nlpar[[i]])
    if (!is.na(prior$coef[[i]]) && nzchar(prior$coef[[i]])) args$coef <- prior$coef[[i]]
    pieces[[i]] <- do.call(brms::set_prior, args)
  }
  do.call(c, pieces)
}

.agf_bayes_formula <- function(model, d, group_effects, random, nlpar_formulas = NULL) {
  .agf_require_brms()
  defaults <- .agf_bayes_default_nlpar_formulas(model, d, group_effects = group_effects, random = random)
  forms <- .agf_bayes_merge_nlpar_formulas(model, defaults, nlpar_formulas)
  do.call(brms::bf, c(list(.agf_bayes_main_formula(model)), unname(forms), list(nl = TRUE)))
}

#' Fit a Bayesian nonlinear plant-growth model with optional hierarchy
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param model One of the Bayesian-supported models: logistic, Gompertz, or Richards.
#' @param time,response Column names when `x` is a data frame.
#' @param group Optional treatment/group column. For `agri_growth_data`, the
#'   declared treatment role is used automatically when `group` is omitted.
#' @param unit Optional persistent-unit column for a plain data frame.
#' @param group_effects Whether group effects enter all nonlinear parameters.
#' @param random Unit-level random-effect template. `"auto"` uses a random effect
#'   on asymptote when repeated persistent units are available.
#' @param nlpar_formulas Optional named list overriding nonlinear-parameter formulas.
#' @param prior An `agri_growth_prior`, a `brmsprior`, or `NULL` for the package template.
#' @param family Response family passed to `brms::brm()`.
#' @param chains,iter,warmup,cores Standard MCMC controls.
#' @param backend `"rstan"` or `"cmdstanr"`.
#' @param seed Optional seed.
#' @param sample_prior Passed to `brms::brm()`: `"no"`, `"yes"`, or `"only"`.
#' @param control Stan sampler controls. Defaults to `adapt_delta = 0.95` and
#'   `max_treedepth = 12`.
#' @param aggregate Destructive-data aggregation rule.
#' @param refresh Console refresh frequency passed to `brms::brm()`.
#' @param ... Additional arguments passed to `brms::brm()`.
#'
#' @return An `agri_growth_bayes` object containing the `brmsfit`, standardized
#' analysis data, prior specification, nonlinear formulas and design metadata.
#' @export
#'
#' @examples
#' # 1) Bayesian logistic fit (requires brms and a Stan backend)
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   class(b)
#' }
#' }
#'
#' # 2) Without group effects and without random effects
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                group_effects = "none", random = "none",
#'                chains = 1, iter = 200, warmup = 100, cores = 1,
#'                seed = 1, refresh = 0)$random
#' }
#' }
#'
#' # 3) Prior-only sampling, useful to check the assumptions
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                sample_prior = "only", chains = 1, iter = 200, warmup = 100,
#'                cores = 1, seed = 1, refresh = 0)$prior_only
#' }
#' }
growth_bayes <- function(x,
                         model = "logistic",
                         time = NULL,
                         response = NULL,
                         group = NULL,
                         unit = NULL,
                         group_effects = c("auto", "none", "all"),
                         random = c("auto", "none", "asym", "timing", "all"),
                         nlpar_formulas = NULL,
                         prior = NULL,
                         family = stats::gaussian(),
                         chains = 4L,
                         iter = 2000L,
                         warmup = floor(iter / 2),
                         cores = getOption("mc.cores", 1L),
                         backend = c("rstan", "cmdstanr"),
                         seed = NULL,
                         sample_prior = c("yes", "no", "only"),
                         control = list(adapt_delta = 0.95, max_treedepth = 12),
                         aggregate = c("auto", "none", "mean"),
                         refresh = 0,
                         ...) {
  .agf_require_brms()
  model <- .agf_bayes_check_model(model)
  group_effects <- match.arg(group_effects)
  random <- match.arg(random)
  backend <- match.arg(backend)
  sample_prior <- match.arg(sample_prior)
  aggregate <- match.arg(aggregate)
  if (identical(backend, "cmdstanr") && !requireNamespace("cmdstanr", quietly = TRUE)) {
    stop("Backend `cmdstanr` was requested but cmdstanr is not installed.", call. = FALSE)
  }
  d <- .agf_prepare_bayes(x, time = time, response = response, group = group, unit = unit, aggregate = aggregate)
  form <- .agf_bayes_formula(model, d, group_effects = group_effects, random = random, nlpar_formulas = nlpar_formulas)
  if (is.null(prior)) {
    ptab <- .agf_prior_template(d$agf_time, d$agf_y, model)
    ptab$model <- model
    ptab <- ptab[, c("model", "nlpar", "role", "class", "coef", "prior", "transformation")]
    class(ptab) <- c("agri_growth_prior", "data.frame")
    prior <- ptab
  }
  brms_prior <- .agf_prior_to_brms(prior)
  fit <- brms::brm(
    formula = form,
    data = d,
    family = family,
    prior = brms_prior,
    chains = chains,
    iter = iter,
    warmup = warmup,
    cores = cores,
    backend = backend,
    seed = seed,
    sample_prior = sample_prior,
    control = control,
    refresh = refresh,
    ...
  )
  out <- list(
    model = model,
    fit = fit,
    data = d,
    formula = form,
    prior = prior,
    brms_prior = brms_prior,
    group_effects = group_effects,
    random = random,
    nlpar_formulas = nlpar_formulas,
    family = family,
    backend = backend,
    sample_prior = sample_prior,
    prior_only = identical(sample_prior, "only"),
    has_group = .agf_bayes_has_group(d),
    has_unit = .agf_bayes_has_unit(d),
    time_support = range(d$agf_time),
    response_support = range(d$agf_y),
    observation_key = paste(format(d$agf_time, digits = 17), format(d$agf_y, digits = 17), as.character(d$agf_unit), as.character(d$agf_group), sep = "|", collapse = "\n"),
    aggregation = attr(d, "aggregation"),
    sampling = attr(d, "sampling"),
    original_names = list(time = attr(d, "time_name"), response = attr(d, "response_name"), group = attr(d, "group_name"), unit = attr(d, "unit_name"))
  )
  class(out) <- "agri_growth_bayes"
  out
}

#' @export
#' @examples
#' # 1) Bayesian fit summary
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   print(b)
#' }
#' }
#'
#' # 2) Formula actually fitted
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   b$formula
#' }
#' }
#'
#' # 3) Object structure
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(b, max.level = 1)
#' }
#' }
print.agri_growth_bayes <- function(x, ...) {
  cat("<agri_growth_bayes> model:", x$model, "\n")
  cat("Backend:", x$backend, " Prior-only:", x$prior_only, " Group effects:", x$group_effects, " Random template:", x$random, "\n")
  print(x$fit)
  invisible(x)
}

#' Fit a prior-predictive Bayesian growth model
#'
#' @inheritParams growth_bayes
#'
#' @description
#' This is a convenience wrapper around `growth_bayes(sample_prior = "only")`.
#' Prior predictive simulation is intended to be inspected before fitting the
#' posterior model so biologically implausible priors can be revised explicitly.
#'
#' @return An `agri_growth_bayes` object with `prior_only = TRUE`.
#' @export
#'
#' @examples
#' # 1) Prior predictive simulation
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   pp <- growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
#'                              chains = 1, iter = 200, warmup = 100, cores = 1,
#'                              seed = 1, refresh = 0)
#'   class(pp)
#' }
#' }
#'
#' # 2) Without group effects
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
#'                        group_effects = "none", random = "none",
#'                        chains = 1, iter = 200, warmup = 100, cores = 1,
#'                        seed = 1, refresh = 0)$has_group
#' }
#' }
#'
#' # 3) Structure of the result
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   pp <- growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
#'                              group_effects = "none", random = "none",
#'                              chains = 1, iter = 200, warmup = 100, cores = 1,
#'                              seed = 1, refresh = 0)
#'   str(pp, max.level = 1)
#' }
#' }
growth_prior_predict <- function(x,
                                 model = "logistic",
                                 time = NULL,
                                 response = NULL,
                                 group = NULL,
                                 unit = NULL,
                                 group_effects = c("auto", "none", "all"),
                                 random = c("auto", "none", "asym", "timing", "all"),
                                 nlpar_formulas = NULL,
                                 prior = NULL,
                                 family = stats::gaussian(),
                                 chains = 4L,
                                 iter = 1000L,
                                 warmup = floor(iter / 2),
                                 cores = getOption("mc.cores", 1L),
                                 backend = c("rstan", "cmdstanr"),
                                 seed = NULL,
                                 control = list(adapt_delta = 0.95, max_treedepth = 12),
                                 aggregate = c("auto", "none", "mean"),
                                 refresh = 0,
                                 ...) {
  growth_bayes(
    x = x,
    model = model,
    time = time,
    response = response,
    group = group,
    unit = unit,
    group_effects = match.arg(group_effects),
    random = match.arg(random),
    nlpar_formulas = nlpar_formulas,
    prior = prior,
    family = family,
    chains = chains,
    iter = iter,
    warmup = warmup,
    cores = cores,
    backend = match.arg(backend),
    seed = seed,
    sample_prior = "only",
    control = control,
    aggregate = match.arg(aggregate),
    refresh = refresh,
    ...
  )
}

#' Posterior or prior predictive check for a Bayesian growth model
#'
#' @param object An `agri_growth_bayes` object.
#' @param type Plot type passed to `brms::pp_check()`.
#' @param ndraws Number of predictive draws displayed.
#' @param ... Additional arguments passed to `brms::pp_check()`.
#'
#' @return A posterior predictive-check plot produced by brms/bayesplot.
#' @export
#'
#' @examples
#' # 1) Posterior predictive check
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_pp_check(b, type = "dens_overlay", ndraws = 10)
#' }
#' }
#'
#' # 2) Another plot type
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_pp_check(b, type = "hist", ndraws = 10)
#' }
#' }
#'
#' # 3) The output is a ggplot object
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   class(growth_pp_check(b, ndraws = 5))[1]
#' }
#' }
growth_pp_check <- function(object, type = "dens_overlay", ndraws = 50L, ...) {
  .agf_require_brms()
  if (!inherits(object, "agri_growth_bayes")) stop("`object` must be created by growth_bayes() or growth_prior_predict().", call. = FALSE)
  brms::pp_check(object$fit, type = type, ndraws = ndraws, ...)
}

#' Diagnose MCMC sampling for a Bayesian growth model
#'
#' @param object An `agri_growth_bayes` object.
#' @param rhat_threshold Threshold above which rank-normalized R-hat is flagged.
#' @param min_ess Minimum effective sample size used for a simple warning flag.
#'
#' @return An `agri_growth_bayes_diagnostics` object with parameter summaries,
#' divergence count, extrema of R-hat and effective sample size, and a status flag.
#' @export
#'
#' @examples
#' # 1) MCMC diagnostics
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_bayes_diagnose(b)
#' }
#' }
#'
#' # 2) Stricter thresholds
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_bayes_diagnose(b, rhat_threshold = 1.001, min_ess = 1000)
#' }
#' }
#'
#' # 3) Structure of the diagnostics
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(growth_bayes_diagnose(b), max.level = 1)
#' }
#' }
growth_bayes_diagnose <- function(object, rhat_threshold = 1.01, min_ess = 400) {
  .agf_require_brms(); .agf_require_posterior()
  if (!inherits(object, "agri_growth_bayes")) stop("`object` must be created by growth_bayes().", call. = FALSE)
  draws <- brms::as_draws_df(object$fit)
  summ <- posterior::summarise_draws(draws, "mean", "sd", "rhat", "ess_bulk", "ess_tail")
  finite_rhat <- summ$rhat[is.finite(summ$rhat)]
  finite_bulk <- summ$ess_bulk[is.finite(summ$ess_bulk)]
  finite_tail <- summ$ess_tail[is.finite(summ$ess_tail)]
  np <- tryCatch(brms::nuts_params(object$fit), error = function(e) NULL)
  divergences <- 0L
  if (!is.null(np) && all(c("Parameter", "Value") %in% names(np))) {
    divergences <- sum(np$Parameter == "divergent__" & np$Value > 0, na.rm = TRUE)
  }
  rhat_max <- if (length(finite_rhat)) max(finite_rhat) else NA_real_
  ess_bulk_min <- if (length(finite_bulk)) min(finite_bulk) else NA_real_
  ess_tail_min <- if (length(finite_tail)) min(finite_tail) else NA_real_
  status <- if (divergences > 0L || (is.finite(rhat_max) && rhat_max > rhat_threshold) ||
                (is.finite(ess_bulk_min) && ess_bulk_min < min_ess) ||
                (is.finite(ess_tail_min) && ess_tail_min < min_ess)) "warning" else "ok"
  out <- list(
    model = object$model,
    status = status,
    divergences = divergences,
    rhat_max = rhat_max,
    ess_bulk_min = ess_bulk_min,
    ess_tail_min = ess_tail_min,
    rhat_threshold = rhat_threshold,
    min_ess = min_ess,
    summary = summ
  )
  class(out) <- "agri_growth_bayes_diagnostics"
  out
}

#' @export
#' @examples
#' # 1) Printed diagnostics
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   print(growth_bayes_diagnose(b))
#' }
#' }
#'
#' # 2) Structure
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(growth_bayes_diagnose(b), max.level = 1)
#' }
#' }
#'
#' # 3) Invisible return
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   bd <- growth_bayes_diagnose(b)
#'   identical(print(bd), bd)
#' }
#' }
print.agri_growth_bayes_diagnostics <- function(x, ...) {
  cat("<agri_growth_bayes_diagnostics> model:", x$model, " status:", x$status, "\n")
  cat("Divergences:", x$divergences, " max R-hat:", .agf_fmt(x$rhat_max),
      " min bulk ESS:", .agf_fmt(x$ess_bulk_min), " min tail ESS:", .agf_fmt(x$ess_tail_min), "\n")
  invisible(x)
}

.agf_bayes_reference_data <- function(object, group = NULL, unit = NULL, re_formula = NA) {
  d <- object$data
  groups <- levels(d$agf_group)
  units <- levels(d$agf_unit)
  if (object$has_group) {
    if (is.null(group)) group <- groups
    if (any(!group %in% groups)) stop("Unknown group level. Available levels: ", paste(groups, collapse = ", "), ".", call. = FALSE)
  } else group <- groups[[1L]]
  if (is.null(re_formula) && object$has_unit) {
    if (is.null(unit)) unit <- units[[1L]]
    if (length(unit) != 1L || !unit %in% units) stop("For unit-specific traits, `unit` must identify one fitted persistent unit.", call. = FALSE)
  } else {
    unit <- units[[1L]]
  }
  data.frame(
    agf_y = mean(d$agf_y),
    agf_time = stats::median(d$agf_time),
    agf_group = factor(group, levels = groups),
    agf_unit = factor(rep(unit, length(group)), levels = units),
    stringsAsFactors = FALSE
  )
}

.agf_draw_ids <- function(object, ndraws = NULL, seed = NULL) {
  .agf_require_brms()
  all_draws <- brms::as_draws_df(object$fit)
  n <- nrow(all_draws)
  if (is.null(ndraws)) return(seq_len(n))
  if (!is.numeric(ndraws) || length(ndraws) != 1L || is.na(ndraws) || ndraws < 1) stop("`ndraws` must be a positive integer or NULL.", call. = FALSE)
  ndraws <- min(as.integer(ndraws), n)
  if (!is.null(seed)) {
    .agf_restore_rng <- .agf_seed_snapshot(); on.exit(.agf_restore_rng(), add = TRUE)
    set.seed(seed)
  }
  sort(sample.int(n, ndraws, replace = FALSE))
}

.agf_nlpar_matrix <- function(object, nlpar, newdata, re_formula, draw_ids) {
  z <- brms::posterior_linpred(
    object$fit,
    newdata = newdata,
    re_formula = re_formula,
    nlpar = nlpar,
    draw_ids = draw_ids,
    transform = FALSE
  )
  if (is.null(dim(z))) z <- matrix(z, ncol = nrow(newdata))
  z
}

.agf_trapz_rows <- function(y, x) {
  if (ncol(y) != length(x)) stop("Internal trapezoid dimensions do not match.", call. = FALSE)
  dx <- diff(x)
  rowSums((y[, -1L, drop = FALSE] + y[, -ncol(y), drop = FALSE]) * rep(dx / 2, each = nrow(y)))
}

.agf_posterior_trait_draws_one <- function(object, refrow, re_formula, draw_ids, grid_n = 201L) {
  nd <- length(draw_ids)
  la <- .agf_nlpar_matrix(object, "logAsym", refrow, re_formula, draw_ids)[, 1L]
  mid <- .agf_nlpar_matrix(object, "mid", refrow, re_formula, draw_ids)[, 1L]
  ls <- .agf_nlpar_matrix(object, "logScale", refrow, re_formula, draw_ids)[, 1L]
  asym <- exp(la); scale <- exp(ls)
  model <- object$model
  if (identical(model, "richards")) {
    lsh <- .agf_nlpar_matrix(object, "logShape", refrow, re_formula, draw_ids)[, 1L]
    shape <- exp(lsh)
  } else shape <- rep(NA_real_, nd)

  if (identical(model, "logistic")) {
    infl_y <- asym / 2
    max_rate <- asym / (4 * scale)
    tfun <- function(f) mid - scale * log(1 / f - 1)
  } else if (identical(model, "gompertz")) {
    infl_y <- asym / exp(1)
    max_rate <- asym / (exp(1) * scale)
    tfun <- function(f) mid - scale * log(-log(f))
  } else {
    infl_y <- asym * (1 + shape)^(-1 / shape)
    max_rate <- asym / scale * (1 + shape)^(-1 / shape - 1)
    tfun <- function(f) {
      z <- ((1 / f)^shape - 1) / shape
      mid - scale * log(z)
    }
  }

  grid <- seq(object$time_support[[1L]], object$time_support[[2L]], length.out = as.integer(grid_n))
  ymat <- matrix(NA_real_, nrow = nd, ncol = length(grid))
  for (j in seq_along(grid)) {
    tt <- grid[[j]]
    if (identical(model, "logistic")) {
      ymat[, j] <- asym / (1 + exp(-(tt - mid) / scale))
    } else if (identical(model, "gompertz")) {
      ymat[, j] <- asym * exp(-exp(-(tt - mid) / scale))
    } else {
      ymat[, j] <- asym * (1 + shape * exp(-(tt - mid) / scale))^(-1 / shape)
    }
  }
  data.frame(
    asymptote = asym,
    inflection_time = mid,
    inflection_response = infl_y,
    maximum_absolute_rate = max_rate,
    time_maximum_rate = mid,
    t10 = tfun(0.10),
    t50 = tfun(0.50),
    t90 = tfun(0.90),
    auc_observed_support = .agf_trapz_rows(ymat, grid),
    stringsAsFactors = FALSE
  )
}

.agf_summarize_draw_vector <- function(x, probs) {
  q <- stats::quantile(x, probs = probs, na.rm = TRUE, names = FALSE, type = 7)
  c(mean = mean(x, na.rm = TRUE), sd = stats::sd(x, na.rm = TRUE), median = stats::median(x, na.rm = TRUE), lower = q[[1L]], upper = q[[2L]])
}

#' Summarize posterior uncertainty in biologically interpretable growth traits
#'
#' @param object An `agri_growth_bayes` object.
#' @param group Optional group levels. Defaults to all fitted levels for a
#'   population-level summary.
#' @param unit Optional fitted unit for unit-specific summaries when
#'   `re_formula = NULL`.
#' @param re_formula Passed to brms prediction methods. The default `NA` excludes
#'   group-level random effects and therefore returns population-level traits.
#' @param ndraws Optional number of posterior draws used.
#' @param probs Two posterior interval probabilities.
#' @param grid_n Number of points used only for numerical AUC over observed support.
#' @param seed Optional seed for posterior draw subsampling.
#'
#' @return A long data frame with posterior mean, SD, median and interval for each
#' biological trait and scenario.
#' @export
#'
#' @examples
#' # 1) Posterior traits with intervals
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_posterior_traits(b, grid_n = 51)
#' }
#' }
#'
#' # 2) Different central probabilities
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_posterior_traits(b, probs = c(0.1, 0.5, 0.9), grid_n = 51)
#' }
#' }
#'
#' # 3) Structure of the result
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(growth_posterior_traits(b, grid_n = 31), max.level = 1)
#' }
#' }
growth_posterior_traits <- function(object,
                                    group = NULL,
                                    unit = NULL,
                                    re_formula = NA,
                                    ndraws = NULL,
                                    probs = c(0.025, 0.975),
                                    grid_n = 201L,
                                    seed = NULL) {
  .agf_require_brms()
  if (!inherits(object, "agri_growth_bayes")) stop("`object` must be created by growth_bayes().", call. = FALSE)
  if (object$prior_only) warning("Trait summaries are based on prior-only draws because this object was fitted with sample_prior = 'only'.", call. = FALSE)
  if (!is.numeric(probs) || length(probs) != 2L || any(!is.finite(probs)) || probs[[1L]] <= 0 || probs[[2L]] >= 1 || probs[[1L]] >= probs[[2L]]) {
    stop("`probs` must contain two increasing probabilities strictly between 0 and 1.", call. = FALSE)
  }
  ref <- .agf_bayes_reference_data(object, group = group, unit = unit, re_formula = re_formula)
  ids <- .agf_draw_ids(object, ndraws = ndraws, seed = seed)
  rows <- list(); idx <- 0L
  for (i in seq_len(nrow(ref))) {
    dr <- .agf_posterior_trait_draws_one(object, ref[i, , drop = FALSE], re_formula = re_formula, draw_ids = ids, grid_n = grid_n)
    for (nm in names(dr)) {
      idx <- idx + 1L
      s <- .agf_summarize_draw_vector(dr[[nm]], probs)
      rows[[idx]] <- data.frame(
        model = object$model,
        group = as.character(ref$agf_group[[i]]),
        unit = if (is.null(re_formula) && object$has_unit) as.character(ref$agf_unit[[i]]) else NA_character_,
        trait = nm,
        mean = s[["mean"]],
        sd = s[["sd"]],
        median = s[["median"]],
        lower = s[["lower"]],
        upper = s[["upper"]],
        prob_lower = probs[[1L]],
        prob_upper = probs[[2L]],
        n_draws = length(ids),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

#' Pareto-smoothed leave-one-out evaluation of a Bayesian growth model
#'
#' @param object An `agri_growth_bayes` object.
#' @param moment_match Logical forwarded to `loo::loo()` for difficult Pareto-k cases.
#' @param ... Additional arguments passed to `loo::loo()`.
#'
#' @return An object of class `agri_growth_loo` containing the `psis_loo` result
#' and Pareto-k diagnostics.
#' @export
#'
#' @examples
#' # 1) Leave-one-out evaluation
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_loo(b)
#' }
#' }
#'
#' # 2) Moment matching for problematic Pareto-k
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   growth_loo(b, moment_match = TRUE)
#' }
#' }
#'
#' # 3) Structure of the result
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(growth_loo(b), max.level = 1)
#' }
#' }
growth_loo <- function(object, moment_match = FALSE, ...) {
  .agf_require_brms(); .agf_require_loo()
  if (!inherits(object, "agri_growth_bayes")) stop("`object` must be created by growth_bayes().", call. = FALSE)
  if (object$prior_only) stop("LOO requires a posterior fit, not a prior-only fit.", call. = FALSE)
  z <- loo::loo(object$fit, moment_match = moment_match, ...)
  kval <- tryCatch(loo::pareto_k_values(z), error = function(e) numeric())
  out <- list(
    model = object$model,
    loo = z,
    pareto_k = kval,
    n_bad_k = sum(kval > 0.7, na.rm = TRUE),
    n_very_bad_k = sum(kval > 1, na.rm = TRUE),
    observation_key = object$observation_key
  )
  class(out) <- "agri_growth_loo"
  out
}

#' @export
#' @examples
#' # 1) LOO summary
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   print(growth_loo(b))
#' }
#' }
#'
#' # 2) Structure
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   str(growth_loo(b), max.level = 1)
#' }
#' }
#'
#' # 3) Invisible return
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                     group_effects = "none", random = "none",
#'                     chains = 1, iter = 200, warmup = 100, cores = 1,
#'                     seed = 1, refresh = 0)
#'   l <- growth_loo(b)
#'   identical(print(l), l)
#' }
#' }
print.agri_growth_loo <- function(x, ...) {
  cat("<agri_growth_loo> model:", x$model, " bad Pareto-k > 0.7:", x$n_bad_k, " > 1:", x$n_very_bad_k, "\n")
  print(x$loo)
  invisible(x)
}

.agf_collect_bayes <- function(...) {
  args <- list(...)
  if (length(args) == 1L && is.list(args[[1L]]) && !inherits(args[[1L]], "agri_growth_bayes")) args <- args[[1L]]
  if (length(args) < 2L) stop("Supply at least two Bayesian growth models.", call. = FALSE)
  if (!all(vapply(args, inherits, logical(1), what = "agri_growth_bayes"))) stop("All objects must be created by growth_bayes().", call. = FALSE)
  keys <- vapply(args, `[[`, character(1), "observation_key")
  if (length(unique(keys)) != 1L) stop("Bayesian models were not fitted to identical prepared observations. LOO weighting is refused.", call. = FALSE)
  nms <- vapply(args, `[[`, character(1), "model")
  if (anyDuplicated(nms)) nms <- make.unique(nms)
  names(args) <- nms
  args
}

.agf_model_average_summary <- function(draws, newdata, probs) {
  ql <- apply(draws, 2L, stats::quantile, probs = probs[[1L]], na.rm = TRUE)
  qu <- apply(draws, 2L, stats::quantile, probs = probs[[2L]], na.rm = TRUE)
  out <- newdata
  out$estimate <- colMeans(draws, na.rm = TRUE)
  out$median <- apply(draws, 2L, stats::median, na.rm = TRUE)
  out$lower <- ql
  out$upper <- qu
  out
}

#' LOO-based weighting and averaging of Bayesian growth models
#'
#' @param ... Two or more `agri_growth_bayes` objects, or one list containing them.
#' @param method `"stacking"` or `"pseudobma"` as implemented by `loo`.
#' @param BB Logical. With pseudo-BMA, use the Bayesian bootstrap to obtain
#'   pseudo-BMA+ weights.
#' @param type `"weights"`, `"epred"`, or `"predict"`. The latter two create a
#'   Monte Carlo mixture of model-specific posterior expected or predictive draws.
#' @param newdata Optional standardized Bayesian prediction data. Defaults to the
#'   prepared observations shared by all fitted models.
#' @param re_formula Random-effect formula passed to brms prediction functions.
#' @param ndraws Number of mixture draws when predictions are requested.
#' @param probs Two interval probabilities.
#' @param seed Optional seed.
#' @param keep_draws Logical. Retain mixture draws in the returned object.
#'
#' @return An `agri_growth_model_average` object containing LOO model weights and,
#' when requested, averaged prediction summaries.
#' @export
#'
#' @examples
#' # 1) Model averaging by stacking
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   growth_model_average(b1, b2, ndraws = 50, seed = 2)
#' }
#' }
#'
#' # 2) Pseudo-BMA weights
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   growth_model_average(b1, b2, method = "pseudobma", ndraws = 50, seed = 2)$weights
#' }
#' }
#'
#' # 3) Averaged prediction from the ensemble
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   ma <- growth_model_average(b1, b2, type = "epred", ndraws = 50, seed = 2)
#'   class(ma)
#' }
#' }
growth_model_average <- function(...,
                                 method = c("stacking", "pseudobma"),
                                 BB = TRUE,
                                 type = c("weights", "epred", "predict"),
                                 newdata = NULL,
                                 re_formula = NA,
                                 ndraws = 1000L,
                                 probs = c(0.025, 0.975),
                                 seed = NULL,
                                 keep_draws = FALSE) {
  .agf_require_brms(); .agf_require_loo()
  models <- .agf_collect_bayes(...)
  method <- match.arg(method)
  type <- match.arg(type)
  if (any(vapply(models, `[[`, logical(1), "prior_only"))) stop("Model averaging requires posterior fits, not prior-only fits.", call. = FALSE)
  loos <- lapply(models, function(m) growth_loo(m)$loo)
  weights <- loo::loo_model_weights(loos, method = method, BB = BB)
  wtab <- data.frame(model = names(weights), weight = as.numeric(weights), stringsAsFactors = FALSE)
  prediction <- NULL; mix <- NULL

  if (!identical(type, "weights")) {
    if (!is.numeric(probs) || length(probs) != 2L || probs[[1L]] <= 0 || probs[[2L]] >= 1 || probs[[1L]] >= probs[[2L]]) {
      stop("`probs` must contain two increasing probabilities strictly between 0 and 1.", call. = FALSE)
    }
    if (!is.numeric(ndraws) || length(ndraws) != 1L || is.na(ndraws) || ndraws < 1L) stop("`ndraws` must be a positive integer.", call. = FALSE)
    ndraws <- as.integer(ndraws)
    if (is.null(newdata)) newdata <- models[[1L]]$data
    if (!is.data.frame(newdata)) stop("`newdata` must be a data frame.", call. = FALSE)
    if (!is.null(seed)) {
      .agf_restore_rng <- .agf_seed_snapshot(); on.exit(.agf_restore_rng(), add = TRUE)
      set.seed(seed)
    }
    pred_mats <- lapply(models, function(m) {
      if (identical(type, "epred")) brms::posterior_epred(m$fit, newdata = newdata, re_formula = re_formula)
      else brms::posterior_predict(m$fit, newdata = newdata, re_formula = re_formula)
    })
    nobs <- unique(vapply(pred_mats, ncol, integer(1)))
    if (length(nobs) != 1L) stop("Model prediction matrices do not have the same number of observations.", call. = FALSE)
    mix <- matrix(NA_real_, nrow = ndraws, ncol = nobs)
    chosen <- sample(seq_along(models), size = ndraws, replace = TRUE, prob = as.numeric(weights))
    for (i in seq_len(ndraws)) {
      mm <- pred_mats[[chosen[[i]]]]
      mix[i, ] <- mm[sample.int(nrow(mm), 1L), ]
    }
    prediction <- .agf_model_average_summary(mix, newdata, probs)
  }

  out <- list(
    method = method,
    BB = BB,
    type = type,
    weights = wtab,
    loo = loos,
    prediction = prediction,
    draws = if (isTRUE(keep_draws)) mix else NULL,
    probs = probs
  )
  class(out) <- "agri_growth_model_average"
  out
}

#' @export
#' @examples
#' # 1) Model-averaging summary
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
#'   print(ma)
#' }
#' }
#'
#' # 2) Structure
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
#'   str(ma, max.level = 1)
#' }
#' }
#'
#' # 3) Invisible return
#' \donttest{
#' if (requireNamespace("brms", quietly = TRUE)) {
#'   d <- growth_example_data("sunflower_sigmoid")
#'   d1 <- subset(d, cultivar == unique(d$cultivar)[1])
#'   b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
#'                      group_effects = "none", random = "none",
#'                      chains = 1, iter = 200, warmup = 100, cores = 1,
#'                      seed = 1, refresh = 0)
#'   ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
#'   identical(print(ma), ma)
#' }
#' }
print.agri_growth_model_average <- function(x, ...) {
  cat("<agri_growth_model_average> method:", x$method, " type:", x$type, "\n")
  print(x$weights, row.names = FALSE)
  if (!is.null(x$prediction)) cat("Prediction rows:", nrow(x$prediction), "\n")
  invisible(x)
}
