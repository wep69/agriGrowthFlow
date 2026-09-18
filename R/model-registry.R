.agf_model_alias <- function(model) {
  if (!is.character(model) || length(model) != 1L || is.na(model) || !nzchar(model)) {
    stop("`model` must be a single non-empty model name.", call. = FALSE)
  }
  key <- tolower(gsub("[- ]", "_", model))
  aliases <- c(
    logistic = "logistic",
    gompertz = "gompertz",
    richards = "richards",
    chapman_richards = "chapman_richards",
    chapmanrichards = "chapman_richards",
    weibull = "weibull",
    von_bertalanffy = "von_bertalanffy",
    vonbertalanffy = "von_bertalanffy",
    bertalanffy = "von_bertalanffy",
    beta = "beta_growth",
    beta_growth = "beta_growth",
    betagrowth = "beta_growth",
    expolinear = "expolinear"
  )
  out <- unname(aliases[key])
  if (is.na(out)) {
    stop("Unknown growth model `", model, "`. Use growth_models() to inspect supported models.", call. = FALSE)
  }
  out
}

.agf_log1pexp <- function(z) {
  out <- numeric(length(z))
  hi <- z > 35
  lo <- z < -35
  mid <- !(hi | lo)
  out[hi] <- z[hi] + log1p(exp(-z[hi]))
  out[lo] <- exp(z[lo])
  out[mid] <- log1p(exp(z[mid]))
  out
}

.agf_log_expm1 <- function(z) {
  out <- numeric(length(z))
  hi <- z > 35
  lo <- z <= 0
  mid <- !(hi | lo)
  out[hi] <- z[hi] + log1p(-exp(-z[hi]))
  out[lo] <- -Inf
  out[mid] <- log(expm1(z[mid]))
  out
}

.agf_logistic <- function(t, asym, mid, scale) {
  asym / (1 + exp(-(t - mid) / scale))
}

.agf_gompertz <- function(t, asym, mid, scale) {
  asym * exp(-exp(-(t - mid) / scale))
}

.agf_richards <- function(t, asym, mid, scale, shape) {
  asym * (1 + shape * exp(-(t - mid) / scale))^(-1 / shape)
}

.agf_chapman_richards <- function(t, asym, rate, shape, origin) {
  u <- rate * (t - origin)
  base <- numeric(length(u))
  pos <- u > 0
  base[pos] <- -expm1(-u[pos])
  asym * base^shape
}

.agf_weibull <- function(t, asym, scale, shape, origin) {
  x <- (t - origin) / scale
  out <- numeric(length(x))
  pos <- x > 0
  out[pos] <- asym * (-expm1(-(x[pos]^shape)))
  out
}

.agf_von_bertalanffy <- function(t, asym, rate, origin) {
  .agf_chapman_richards(t, asym = asym, rate = rate, shape = 3, origin = origin)
}

.agf_beta_internal <- function(t, wmax, tm, gap) {
  te <- tm + gap
  out <- numeric(length(t))
  inside <- is.finite(t) & t > 0 & t < te
  if (any(inside)) {
    tt <- t[inside]
    first <- 1 + (te - tt) / gap
    exponent <- te / gap
    out[inside] <- wmax * first * (tt / te)^exponent
  }
  out[is.finite(t) & t >= te] <- wmax
  out[is.finite(t) & t <= 0] <- 0
  out
}

.agf_expolinear <- function(t, cm, rm, tb) {
  z <- rm * (t - tb)
  (cm / rm) * .agf_log1pexp(z)
}

.agf_model_registry <- function() {
  data.frame(
    model = c(
      "logistic", "gompertz", "richards", "chapman_richards",
      "weibull", "von_bertalanffy", "beta_growth", "expolinear"
    ),
    family = c(
      "sigmoid", "sigmoid", "flexible_sigmoid", "asymptotic_sigmoid",
      "asymptotic_sigmoid", "asymptotic_sigmoid", "determinate", "crop_growth"
    ),
    public_parameters = c(
      "asym, mid, scale",
      "asym, mid, scale",
      "asym, mid, scale, shape",
      "asym, rate, shape, origin",
      "asym, scale, shape, origin",
      "asym, rate, origin",
      "wmax, tm, te",
      "cm, rm, tb"
    ),
    finite_upper_level = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    determinate_end = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE),
    reference_key = c(
      "Richards1959", "ArchontoulisMiguez2015", "Richards1959", "Richards1959",
      "ArchontoulisMiguez2015", "ArchontoulisMiguez2015", "YinEtAl2003", "GoudriaanMonteith1990"
    ),
    stringsAsFactors = FALSE
  )
}

#' Inspect built-in parametric plant-growth equations
#'
#' @description
#' Returns the 0.2.0 model registry. The registry is descriptive; fitting remains
#' design-aware and ordinary nonlinear least squares is not a replacement for a
#' longitudinal mixed-effects model when within-unit dependence matters.
#'
#' @return A data frame describing built-in models and their public parameters.
#' @export
#'
#' @examples
#' # 1) The complete catalogue
#' growth_models()
#'
#' # 2) Models with a finite upper level
#' subset(growth_models(), finite_upper_level)
#'
#' # 3) Public parameters of one model
#' growth_models()[growth_models()$model == "richards", "public_parameters"]
growth_models <- function() {
  .agf_model_registry()
}

.agf_model_internal_parameters <- function(model) {
  model <- .agf_model_alias(model)
  switch(model,
    logistic = c("asym", "mid", "scale"),
    gompertz = c("asym", "mid", "scale"),
    richards = c("asym", "mid", "scale", "shape"),
    chapman_richards = c("asym", "rate", "shape", "origin"),
    weibull = c("asym", "scale", "shape", "origin"),
    von_bertalanffy = c("asym", "rate", "origin"),
    beta_growth = c("wmax", "tm", "gap"),
    expolinear = c("cm", "rm", "tb")
  )
}

.agf_model_public_parameters <- function(model) {
  model <- .agf_model_alias(model)
  if (identical(model, "beta_growth")) c("wmax", "tm", "te") else .agf_model_internal_parameters(model)
}

.agf_eval_internal <- function(model, t, pars) {
  model <- .agf_model_alias(model)
  pars <- as.list(pars)
  switch(model,
    logistic = do.call(.agf_logistic, c(list(t = t), pars)),
    gompertz = do.call(.agf_gompertz, c(list(t = t), pars)),
    richards = do.call(.agf_richards, c(list(t = t), pars)),
    chapman_richards = do.call(.agf_chapman_richards, c(list(t = t), pars)),
    weibull = do.call(.agf_weibull, c(list(t = t), pars)),
    von_bertalanffy = do.call(.agf_von_bertalanffy, c(list(t = t), pars)),
    beta_growth = do.call(.agf_beta_internal, c(list(t = t), pars)),
    expolinear = do.call(.agf_expolinear, c(list(t = t), pars))
  )
}

.agf_internal_to_public <- function(model, pars) {
  model <- .agf_model_alias(model)
  pars <- as.numeric(pars)
  names(pars) <- .agf_model_internal_parameters(model)
  if (identical(model, "beta_growth")) {
    return(c(wmax = pars[["wmax"]], tm = pars[["tm"]], te = pars[["tm"]] + pars[["gap"]]))
  }
  pars
}

.agf_public_to_internal <- function(model, pars) {
  model <- .agf_model_alias(model)
  if (is.null(names(pars)) || any(!nzchar(names(pars)))) {
    stop("User-supplied starting values must be a named numeric vector or named list.", call. = FALSE)
  }
  pars <- unlist(pars, use.names = TRUE)
  if (!is.numeric(pars) || any(!is.finite(pars))) {
    stop("Starting values must be finite numeric values.", call. = FALSE)
  }
  if (identical(model, "beta_growth")) {
    needed <- c("wmax", "tm", "te")
    if (!all(needed %in% names(pars))) {
      stop("Beta-growth starting values must contain `wmax`, `tm`, and `te`.", call. = FALSE)
    }
    if (pars[["te"]] <= pars[["tm"]]) {
      stop("Beta-growth starting value `te` must be greater than `tm`.", call. = FALSE)
    }
    return(c(wmax = pars[["wmax"]], tm = pars[["tm"]], gap = pars[["te"]] - pars[["tm"]]))
  }
  needed <- .agf_model_internal_parameters(model)
  if (!all(needed %in% names(pars))) {
    stop("Starting values must contain: ", paste(needed, collapse = ", "), ".", call. = FALSE)
  }
  pars[needed]
}
