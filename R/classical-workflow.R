.agf_resolve_role <- function(x, supplied, role, required = FALSE) {
  val <- supplied
  if (is.null(val) && inherits(x, "agri_growth_data")) val <- .agf_role(x, role)
  if (required && is.null(val)) {
    stop("No column is available for role `", role, "`. Supply it explicitly or declare it with growth_data().", call. = FALSE)
  }
  val
}

.agf_time_numeric <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x))
  if (inherits(x, c("POSIXct", "POSIXt"))) return(as.numeric(x) / 86400)
  as.numeric(x)
}

.agf_first_nonmissing <- function(z) {
  z <- z[!is.na(z)]
  if (!length(z)) return(NA)
  z[[1L]]
}

#' Design-aware classical growth analysis
#'
#' @description
#' Calculates interval growth quantities after first reducing observations to one
#' value per stable experimental unit and harvest time. For destructive sampling,
#' this means that multiple harvested plants or quadrats within a plot-date are
#' summarized before intervals are formed. For repeated sampling, the stable unit
#' should normally be the plant.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,total_mass,leaf_area,leaf_mass,ground_area Column names. Roles are
#'   inherited from `growth_data()` when omitted.
#' @param unit Stable interval unit. Defaults to experimental unit, plot, then plant.
#' @param by Optional additional grouping columns carried into the result. When omitted,
#'   treatment and block roles are retained if available.
#' @param na.rm Passed to within-unit/time means.
#'
#' @return An object of class `agri_growth_indices` with one row per consecutive interval.
#' @export
#'
#' @examples
#' d <- growth_example_data("maize_destructive")
#' g <- growth_data(d, time = "day", sampling = "destructive",
#'   experimental_unit = "plot_id", treatment = "nitrogen", block = "block",
#'   total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
#'   leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2")
#' growth_indices(g)

growth_classical <- function(x,
                             time = NULL,
                             total_mass = NULL,
                             leaf_area = NULL,
                             leaf_mass = NULL,
                             ground_area = NULL,
                             unit = NULL,
                             by = NULL,
                             na.rm = TRUE) {
  validation <- NULL
  if (inherits(x, "agri_growth_data")) {
    validation <- growth_validate(x, strict = FALSE)
    if (identical(validation$status, "error")) {
      stop("The declared growth-data structure contains error-level validation issues. Resolve them before calculating interval growth indices.", call. = FALSE)
    }
    data <- x$data
    time <- .agf_resolve_role(x, time, "time", TRUE)
    total_mass <- .agf_resolve_role(x, total_mass, "total_mass", FALSE)
    leaf_area <- .agf_resolve_role(x, leaf_area, "leaf_area", FALSE)
    leaf_mass <- .agf_resolve_role(x, leaf_mass, "leaf_mass", FALSE)
    ground_area <- .agf_resolve_role(x, ground_area, "ground_area", FALSE)
    unit <- unit %||% .agf_role(x, "experimental_unit") %||% .agf_role(x, "plot") %||% .agf_role(x, "plant")
    if (is.null(by)) by <- .agf_unique_non_null(list(.agf_role(x, "treatment"), .agf_role(x, "block")))
    sampling <- x$sampling
  } else {
    .agf_assert_data_frame(x)
    data <- x
    if (is.null(time)) stop("`time` is required when `x` is a data frame.", call. = FALSE)
    sampling <- "unspecified"
  }

  .agf_assert_column(data, time, "time", allow_null = FALSE)
  for (nm in c("total_mass", "leaf_area", "leaf_mass", "ground_area", "unit")) {
    val <- get(nm)
    .agf_assert_column(data, val, nm, allow_null = nm != "unit")
  }
  .agf_assert_columns(data, by, "by")

  if (is.null(unit)) {
    stop("A stable interval `unit` is required. For destructive sampling use the plot or another experimental unit that persists across harvest dates; do not use different harvested plants as if they were repeated subjects.", call. = FALSE)
  }
  if (is.null(total_mass) && is.null(leaf_area) && is.null(leaf_mass)) {
    stop("At least one growth quantity must be supplied; total mass is required for AGR/RGR and leaf area for LAI/LAD.", call. = FALSE)
  }

  metric_cols <- unique(c(total_mass, leaf_area, leaf_mass, ground_area))
  metric_cols <- metric_cols[!is.na(metric_cols) & nzchar(metric_cols)]
  id_cols <- unique(c(by, unit, time))

  d <- data[c(id_cols, metric_cols)]
  for (m in metric_cols) {
    if (!is.numeric(d[[m]])) stop("Growth metric `", m, "` must be numeric.", call. = FALSE)
  }

  # Summarize sampling replicates within each stable unit and harvest time.
  agg <- stats::aggregate(
    d[metric_cols],
    by = d[id_cols],
    FUN = function(z) mean(z, na.rm = na.rm)
  )

  # Preserve factor/character grouping columns from aggregation and order explicitly.
  time_num <- .agf_time_numeric(agg[[time]])
  ord_args <- c(lapply(agg[unique(c(by, unit))], as.character), list(time_num))
  ord <- do.call(order, ord_args)
  agg <- agg[ord, , drop = FALSE]
  time_num <- time_num[ord]
  agg$.agf_time_numeric <- time_num

  split_cols <- unique(c(by, unit))
  key <- .agf_group_key(agg, split_cols)
  groups <- split(seq_len(nrow(agg)), key)
  rows <- vector("list", 0L)

  for (idx in groups) {
    z <- agg[idx, , drop = FALSE]
    z <- z[order(z$.agf_time_numeric), , drop = FALSE]
    if (nrow(z) < 2L) next

    for (i in seq_len(nrow(z) - 1L)) {
      j <- i + 1L
      t1n <- z$.agf_time_numeric[i]
      t2n <- z$.agf_time_numeric[j]
      if (!is.finite(t1n) || !is.finite(t2n) || t2n <= t1n) next
      row <- as.list(z[i, c(by, unit), drop = FALSE])
      row$t1 <- z[[time]][i]
      row$t2 <- z[[time]][j]
      row$dt <- t2n - t1n

      if (!is.null(total_mass)) {
        w1 <- z[[total_mass]][i]
        w2 <- z[[total_mass]][j]
        row$mass1 <- w1
        row$mass2 <- w2
        row$AGR <- growth_agr(w1, w2, t1n, t2n)
        row$RGR <- if (is.finite(w1) && is.finite(w2) && w1 > 0 && w2 > 0) growth_rgr(w1, w2, t1n, t2n) else NA_real_
      }

      if (!is.null(leaf_area)) {
        a1 <- z[[leaf_area]][i]
        a2 <- z[[leaf_area]][j]
        row$leaf_area1 <- a1
        row$leaf_area2 <- a2
      }

      if (!is.null(leaf_mass)) {
        lm1 <- z[[leaf_mass]][i]
        lm2 <- z[[leaf_mass]][j]
        row$leaf_mass1 <- lm1
        row$leaf_mass2 <- lm2
      }

      if (!is.null(total_mass) && !is.null(leaf_area)) {
        row$LAR1 <- if (is.finite(w1) && w1 > 0) growth_lar(a1, w1) else NA_real_
        row$LAR2 <- if (is.finite(w2) && w2 > 0) growth_lar(a2, w2) else NA_real_
        row$NAR <- if (all(is.finite(c(w1, w2, a1, a2))) && a1 > 0 && a2 > 0) growth_nar(w1, w2, a1, a2, t1n, t2n) else NA_real_
      }

      if (!is.null(total_mass) && !is.null(leaf_mass)) {
        row$LMR1 <- if (is.finite(w1) && w1 > 0) growth_lmr(lm1, w1) else NA_real_
        row$LMR2 <- if (is.finite(w2) && w2 > 0) growth_lmr(lm2, w2) else NA_real_
      }

      if (!is.null(leaf_area) && !is.null(leaf_mass)) {
        row$SLA1 <- if (is.finite(lm1) && lm1 > 0) growth_sla(a1, lm1) else NA_real_
        row$SLA2 <- if (is.finite(lm2) && lm2 > 0) growth_sla(a2, lm2) else NA_real_
      }

      if (!is.null(ground_area)) {
        ga1 <- z[[ground_area]][i]
        ga2 <- z[[ground_area]][j]
        row$ground_area1 <- ga1
        row$ground_area2 <- ga2
        if (!is.null(total_mass)) {
          ga <- mean(c(ga1, ga2), na.rm = TRUE)
          row$CGR <- if (is.finite(ga) && ga > 0) growth_cgr(w1, w2, t1n, t2n, ground_area = ga) else NA_real_
        }
        if (!is.null(leaf_area)) {
          lai1 <- if (is.finite(ga1) && ga1 > 0) growth_lai(a1, ga1) else NA_real_
          lai2 <- if (is.finite(ga2) && ga2 > 0) growth_lai(a2, ga2) else NA_real_
          row$LAI1 <- lai1
          row$LAI2 <- lai2
          row$LAD <- if (all(is.finite(c(lai1, lai2)))) ((lai1 + lai2) / 2) * (t2n - t1n) else NA_real_
        }
      }

      rows[[length(rows) + 1L]] <- as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
    }
  }

  if (!length(rows)) {
    stop("No valid consecutive intervals could be formed from the declared unit and time columns.", call. = FALSE)
  }
  out_data <- do.call(rbind, rows)
  rownames(out_data) <- NULL
  out <- list(
    intervals = out_data,
    aggregated = agg[setdiff(names(agg), ".agf_time_numeric")],
    unit = unit,
    by = by,
    sampling = sampling,
    validation = validation,
    roles = list(time = time, total_mass = total_mass, leaf_area = leaf_area, leaf_mass = leaf_mass, ground_area = ground_area)
  )
  class(out) <- "agri_growth_indices"
  out
}

#' @rdname growth_classical
#' @export
growth_indices <- function(x, ...) {
  growth_classical(x, ...)
}

#' @export
print.agri_growth_indices <- function(x, ...) {
  cat("<agri_growth_indices>\n")
  cat("Stable unit:", x$unit, " Sampling:", x$sampling, "\n")
  cat("Intervals:", nrow(x$intervals), "\n")
  metric_names <- intersect(c("AGR", "RGR", "NAR", "LAR1", "SLA1", "LMR1", "CGR", "LAI1", "LAD"), names(x$intervals))
  cat("Available metrics:", paste(metric_names, collapse = ", "), "\n")
  print(utils::head(x$intervals, 6L), row.names = FALSE)
  invisible(x)
}
