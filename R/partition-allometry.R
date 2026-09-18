#' Biomass partitioning with closure checks
#'
#' @param data A data frame or `agri_growth_data` object.
#' @param total_mass Total-mass column. When omitted for `agri_growth_data`, the declared role is used.
#' @param components Character vector of component-mass columns. When omitted for
#'   `agri_growth_data`, available root, stem, leaf and reproductive mass roles are used.
#' @param normalize If `FALSE` (default), fractions are calculated against declared total mass.
#'   If `TRUE`, fractions are normalized by the sum of supplied components.
#' @param tolerance Relative tolerance used to flag component closure departures.
#' @param prefix Prefix for fraction columns.
#'
#' @return A data frame of component fractions, component sum, closure and unallocated fraction.
#' @export
#' @examples
#' # 1) Components detected from the declared object
#' d <- growth_example_data("soybean_partition")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'                  experimental_unit = "plot_id", total_mass = "total_mass_g",
#'                  leaf_mass = "leaf_mass_g", root_mass = "root_mass_g",
#'                  stem_mass = "stem_mass_g",
#'                  reproductive_mass = "reproductive_mass_g")
#' pt <- growth_partition(g)
#' head(pt[, c("frac_leaf_mass_g", "closure", "closure_ok")])
#'
#' # 2) Components declared on a raw data frame
#' pt2 <- growth_partition(d, total_mass = "total_mass_g",
#'                         components = c("leaf_mass_g", "stem_mass_g", "root_mass_g"))
#' sum(!pt2$closure_ok)
#'
#' # 3) Normalization and prefix
#' names(growth_partition(g, normalize = TRUE, prefix = "p_"))[1:4]

growth_partition <- function(data,
                             total_mass = NULL,
                             components = NULL,
                             normalize = FALSE,
                             tolerance = 0.02,
                             prefix = "frac_") {
  if (inherits(data, "agri_growth_data")) {
    x <- data
    data <- x$data
    total_mass <- total_mass %||% .agf_role(x, "total_mass")
    if (is.null(components)) {
      components <- c(.agf_role(x, "root_mass"), .agf_role(x, "stem_mass"), .agf_role(x, "leaf_mass"), .agf_role(x, "reproductive_mass"))
      components <- components[!vapply(components, is.null, logical(1))]
    }
  }
  .agf_assert_data_frame(data)
  .agf_assert_column(data, total_mass, "total_mass", allow_null = normalize)
  .agf_assert_columns(data, components, "components")
  if (length(components) < 2L) stop("Supply at least two biomass component columns.", call. = FALSE)

  vals <- data[components]
  if (any(!vapply(vals, is.numeric, logical(1)))) stop("All component columns must be numeric.", call. = FALSE)
  if (any(vapply(vals, function(z) any(z < 0, na.rm = TRUE), logical(1)))) stop("Component masses must be non-negative.", call. = FALSE)
  component_sum <- rowSums(vals, na.rm = FALSE)

  if (normalize) {
    denom <- component_sum
    if (any(denom <= 0, na.rm = TRUE)) stop("Normalized partitioning requires a positive component sum.", call. = FALSE)
    closure <- rep(1, nrow(data))
    unallocated <- rep(0, nrow(data))
  } else {
    tm <- data[[total_mass]]
    if (!is.numeric(tm) || any(tm <= 0, na.rm = TRUE)) stop("Declared total mass must be positive and numeric.", call. = FALSE)
    denom <- tm
    closure <- component_sum / tm
    unallocated <- 1 - closure
  }

  fractions <- sweep(as.matrix(vals), 1L, denom, "/")
  fractions <- as.data.frame(fractions, stringsAsFactors = FALSE)
  names(fractions) <- paste0(prefix, components)
  out <- cbind(fractions,
               component_sum = component_sum,
               closure = closure,
               unallocated_fraction = unallocated,
               closure_ok = abs(closure - 1) <= tolerance)
  attr(out, "components") <- components
  attr(out, "normalized") <- normalize
  attr(out, "tolerance") <- tolerance
  class(out) <- c("agri_growth_partition", "data.frame")
  out
}

#' Fit a log-log allometric relationship
#'
#' @description
#' Fits `log(y) = log(a) + k log(x)` by ordinary least squares, optionally within groups.
#' The exponent `k` is the allometric coefficient under this parameterization.
#' Ordinary least squares treats the predictor as the explanatory variable and is not
#' interchangeable with standardized major-axis regression.
#'
#' @param data A data frame.
#' @param x,y Positive numeric variable names.
#' @param group Optional grouping column.
#' @param level Confidence level for coefficient intervals.
#'
#' @return An `agri_growth_allometry` object.
#' @export
#' @examples
#' # 1) Single log-log fit
#' d <- growth_example_data("soybean_partition")
#' growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g")$summary
#'
#' # 2) One fit per group
#' growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g",
#'                  group = "cultivar")$summary
#'
#' # 3) Different confidence level
#' growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g",
#'                  level = 0.90)$summary[, c("k", "k_low", "k_high")]

growth_allometry <- function(data, x, y, group = NULL, level = 0.95) {
  .agf_assert_data_frame(data)
  .agf_assert_column(data, x, "x", allow_null = FALSE)
  .agf_assert_column(data, y, "y", allow_null = FALSE)
  .agf_assert_column(data, group, "group", allow_null = TRUE)
  if (!is.numeric(data[[x]]) || !is.numeric(data[[y]])) stop("Allometric variables must be numeric.", call. = FALSE)
  if (any(data[[x]] <= 0 | data[[y]] <= 0, na.rm = TRUE)) stop("Log-log allometry requires positive x and y values.", call. = FALSE)
  if (!is.numeric(level) || length(level) != 1L || level <= 0 || level >= 1) stop("`level` must be between 0 and 1.", call. = FALSE)

  groups <- if (is.null(group)) list(`.all` = seq_len(nrow(data))) else split(seq_len(nrow(data)), data[[group]], drop = TRUE)
  fits <- list()
  summaries <- list()
  alpha <- 1 - level

  for (nm in names(groups)) {
    z <- data[groups[[nm]], c(x, y), drop = FALSE]
    z <- z[stats::complete.cases(z), , drop = FALSE]
    if (nrow(z) < 3L) next
    z$log_x <- log(z[[x]])
    z$log_y <- log(z[[y]])
    fit <- stats::lm(log_y ~ log_x, data = z)
    cf <- stats::coef(fit)
    se <- sqrt(diag(stats::vcov(fit)))
    df <- stats::df.residual(fit)
    q <- stats::qt(1 - alpha / 2, df = df)
    ci_low <- cf - q * se
    ci_high <- cf + q * se
    k <- unname(cf[[2L]])
    a <- exp(unname(cf[[1L]]))
    s <- summary(fit)
    summaries[[length(summaries) + 1L]] <- data.frame(
      group = nm,
      n = nrow(z),
      a = a,
      k = k,
      k_se = unname(se[[2L]]),
      k_low = unname(ci_low[[2L]]),
      k_high = unname(ci_high[[2L]]),
      r_squared = unname(s$r.squared),
      residual_sd_log = unname(s$sigma),
      stringsAsFactors = FALSE
    )
    fits[[nm]] <- fit
  }
  if (!length(summaries)) stop("No group contained at least three complete positive observations.", call. = FALSE)
  out <- list(summary = do.call(rbind, summaries), fits = fits, x = x, y = y, group = group, level = level, method = "loglog_ols")
  rownames(out$summary) <- NULL
  class(out) <- "agri_growth_allometry"
  out
}

#' @export
#' @examples
#' # 1) Summary of the fit
#' d <- growth_example_data("soybean_partition")
#' al <- growth_allometry(d, x = "total_mass_g", y = "leaf_mass_g")
#' print(al)
#'
#' # 2) Coefficient table
#' al$summary[, c("n", "a", "k", "r_squared")]
#'
#' # 3) Invisible return
#' identical(print(al), al)
print.agri_growth_allometry <- function(x, ...) {
  cat("<agri_growth_allometry> method:", x$method, "\n")
  cat("Relationship:", x$y, "= a *", x$x, "^ k\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' @export
#' @examples
#' # 1) Partition summary
#' d <- growth_example_data("soybean_partition")
#' pt <- growth_partition(d, total_mass = "total_mass_g",
#'                        components = c("leaf_mass_g", "stem_mass_g"))
#' print(pt)
#'
#' # 2) Stored attributes
#' attr(pt, "components")
#' attr(pt, "tolerance")
#'
#' # 3) Invisible return
#' identical(print(pt), pt)
print.agri_growth_partition <- function(x, ...) {
  cat("<agri_growth_partition>\n")
  cat("Components:", paste(attr(x, "components"), collapse = ", "), "\n")
  cat("Normalized:", isTRUE(attr(x, "normalized")), " tolerance:", attr(x, "tolerance"), "\n")
  cat("Rows:", nrow(x), " closure failures:", sum(!x$closure_ok, na.rm = TRUE), "\n")
  print(utils::head(as.data.frame(x), 6L), row.names = FALSE)
  invisible(x)
}
