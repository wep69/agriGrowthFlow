#' Orthogonal polynomial coefficients for experimental-unit growth curves
#'
#' @description
#' Reduces each persistent unit's trajectory on a common time grid to an intercept
#' plus orthogonal polynomial coefficients. This modernizes the coefficient-based
#' growth-curve decomposition used in classical plant-breeding growth analysis.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,response,unit,group Column names.
#' @param degree Polynomial degree.
#' @param transform `"none"` or `"log"` response transformation.
#' @param aggregate Destructive-sampling aggregation rule.
#' @return A data frame with one row per persistent unit.
#' @export
#' @examples
#' # 1) Orthogonal components of degree 2
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' cc <- growth_curve_coefficients(g, response = "height_cm")
#' head(cc)
#'
#' # 2) Degree 3 on the log scale
#' head(growth_curve_coefficients(g, response = "height_cm", degree = 3,
#'                                transform = "log"))
#'
#' # 3) Stored attributes
#' attr(cc, "degree"); attr(cc, "transform")
growth_curve_coefficients <- function(x,
                                      time = NULL,
                                      response = NULL,
                                      unit = NULL,
                                      group = NULL,
                                      degree = 2L,
                                      transform = c("none", "log"),
                                      aggregate = c("auto", "none", "mean")) {
  degree <- as.integer(degree)
  if (!is.finite(degree) || degree < 1L || degree > 5L) stop("`degree` must be an integer from 1 to 5.", call. = FALSE)
  transform <- match.arg(transform)
  aggregate <- match.arg(aggregate)
  # Guard log-positivity on raw responses before aggregation hides zeros
  if (identical(transform, "log")) {
    raw_response_name <- response
    if (is.null(raw_response_name) && inherits(x, "agri_growth_data")) {
      raw_response_name <- .agf_role(x, "total_mass") %||% .agf_role(x, "leaf_area") %||% .agf_role(x, "leaf_mass")
    }
    if (!is.null(raw_response_name)) {
      raw_data_for_check <- if (inherits(x, "agri_growth_data")) x$data else x
      if (raw_response_name %in% names(raw_data_for_check)) {
        raw_vals <- raw_data_for_check[[raw_response_name]]
        if (any(raw_vals <= 0, na.rm = TRUE)) {
          stop("Log transformation requires strictly positive responses.", call. = FALSE)
        }
      }
    }
  }
  d <- .agf_prepare_longitudinal(
    x, time = time, response = response, unit = unit, group = group,
    aggregate = aggregate, require_unit = TRUE, min_times = degree + 1L,
    auto_group = TRUE, auto_block = FALSE
  )
  if (identical(transform, "log")) {
    if (any(d$.y <= 0)) stop("Log transformation requires strictly positive responses.", call. = FALSE)
    d$.y <- log(d$.y)
  }

  unit_group_counts <- tapply(as.character(d$.group), d$.unit, function(z) length(unique(z)))
  if (any(unit_group_counts > 1L)) {
    stop("`group` must be invariant within each persistent unit for coefficient MANOVA.", call. = FALSE)
  }
  grids <- lapply(split(d$.t, d$.unit), function(z) sort(unique(z)))
  ref <- grids[[1L]]
  same <- vapply(grids, function(z) length(z) == length(ref) && max(abs(z - ref)) < 1e-10, logical(1))
  if (!all(same)) {
    stop("`growth_curve_coefficients()` requires the same observed time grid for every persistent unit. It does not silently interpolate missing harvests.", call. = FALSE)
  }
  if (length(ref) < degree + 1L) stop("Insufficient common time points for the requested polynomial degree.", call. = FALSE)
  basis <- stats::poly(ref, degree = degree, raw = FALSE)
  X <- cbind(level = 1, basis)
  colnames(X) <- c("level", paste0("P", seq_len(degree)))

  parts <- split(d, d$.unit)
  rows <- lapply(names(parts), function(id) {
    z <- parts[[id]][order(parts[[id]]$.t), , drop = FALSE]
    if (anyDuplicated(z$.t)) stop("Duplicate unit-time observations remain after aggregation.", call. = FALSE)
    cf <- as.numeric(qr.solve(X, z$.y))
    out <- data.frame(unit = id, group = as.character(z$.group[[1L]]), stringsAsFactors = FALSE)
    for (j in seq_along(cf)) out[[colnames(X)[j]]] <- cf[[j]]
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  attr(out, "time_grid") <- ref
  attr(out, "basis") <- basis
  attr(out, "degree") <- degree
  attr(out, "transform") <- transform
  out
}

#' Multivariate comparison of plant growth-curve components
#'
#' @description
#' Fits MANOVA to orthogonal polynomial growth components derived for each
#' persistent experimental unit. The unit-level coefficient matrix, multivariate
#' test, and component-wise ANOVAs are returned together. The method requires a
#' common observed time grid and does not replace mixed-effects modeling when the
#' inferential question is explicitly longitudinal.
#'
#' @inheritParams growth_curve_coefficients
#' @param test Multivariate test statistic: `"Pillai"`, `"Wilks"`, `"Hotelling-Lawley"`, or `"Roy"`.
#' @return An object of class `agri_growth_manova`.
#' @export
#' @examples
#' # 1) Pillai multivariate test
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' mv <- growth_manova(g, response = "height_cm", group = "water_regime")
#' mv$test
#'
#' # 2) Another test statistic
#' growth_manova(g, response = "height_cm", group = "water_regime",
#'               test = "Wilks")$test
#'
#' # 3) ANOVA per curve component
#' names(growth_manova(g, response = "height_cm",
#'                     group = "water_regime")$component_anova)
growth_manova <- function(x,
                          time = NULL,
                          response = NULL,
                          unit = NULL,
                          group = NULL,
                          degree = 2L,
                          transform = c("none", "log"),
                          aggregate = c("auto", "none", "mean"),
                          test = c("Pillai", "Wilks", "Hotelling-Lawley", "Roy")) {
  test <- match.arg(test)
  cf <- growth_curve_coefficients(x, time = time, response = response, unit = unit,
                                  group = group, degree = degree, transform = transform,
                                  aggregate = aggregate)
  if (length(unique(cf$group)) < 2L) stop("MANOVA requires at least two growth groups.", call. = FALSE)
  resp <- c("level", paste0("P", seq_len(as.integer(degree))))
  lhs <- paste0("cbind(", paste(resp, collapse = ","), ")")
  form <- stats::as.formula(paste(lhs, "~ group"))
  fit <- stats::manova(form, data = cf)
  multi <- summary(fit, test = test)
  component <- stats::summary.aov(fit)
  out <- list(
    fit = fit,
    coefficients = cf,
    multivariate = multi,
    component_anova = component,
    degree = as.integer(degree),
    test = test,
    time_grid = attr(cf, "time_grid"),
    transform = attr(cf, "transform")
  )
  class(out) <- "agri_growth_manova"
  out
}

#' @export
#' @examples
#' # 1) Multivariate test summary
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' mv <- growth_manova(g, response = "height_cm", group = "water_regime")
#' print(mv)
#'
#' # 2) Test statistics
#' mv$multivariate$stats
#'
#' # 3) Invisible return
#' identical(print(mv), mv)
print.agri_growth_manova <- function(x, ...) {
  cat("<agri_growth_manova> degree:", x$degree, " test:", x$test, "\n")
  cat("Persistent units:", nrow(x$coefficients), " groups:", paste(unique(x$coefficients$group), collapse = ", "), "\n")
  print(x$multivariate)
  invisible(x)
}
