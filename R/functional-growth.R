.agf_functional_lists <- function(d) {
  spl <- split(d, d$.unit)
  spl <- lapply(spl, function(z) {
    z <- z[order(z$.t), , drop = FALSE]
    if (anyDuplicated(z$.t)) {
      z <- stats::aggregate(z[".y"], by = z[".t"], FUN = mean, na.rm = TRUE)
      z$.unit <- NA
    }
    z
  })
  list(
    ids = names(spl),
    Lt = lapply(spl, function(z) as.numeric(z$.t)),
    Ly = lapply(spl, function(z) as.numeric(z$.y))
  )
}

.agf_grid_fpca <- function(d, grid_n, npc, pve, smooth) {
  parts <- split(d, d$.unit)
  mins <- vapply(parts, function(z) min(z$.t), numeric(1))
  maxs <- vapply(parts, function(z) max(z$.t), numeric(1))
  lo <- max(mins); hi <- min(maxs)
  if (!is.finite(lo) || !is.finite(hi) || hi <= lo) {
    stop("Persistent units do not share a positive common time interval. Use a sparse FPCA engine such as `fdapace` instead of forcing extrapolation.", call. = FALSE)
  }
  grid <- seq(lo, hi, length.out = as.integer(grid_n))
  curves <- t(vapply(parts, function(z) {
    z <- z[order(z$.t), , drop = FALSE]
    if (anyDuplicated(z$.t)) z <- stats::aggregate(z[".y"], by = z[".t"], FUN = mean, na.rm = TRUE)
    if (nrow(z) < 3L) stop("Each unit requires at least three distinct observations for grid FPCA.", call. = FALSE)
    if (identical(smooth, "smooth_spline")) {
      stats::predict(stats::smooth.spline(z$.t, z$.y), x = grid)$y
    } else {
      stats::approx(z$.t, z$.y, xout = grid, method = "linear", rule = 1)$y
    }
  }, numeric(length(grid))))
  rownames(curves) <- names(parts)
  if (any(!is.finite(curves))) stop("Grid reconstruction produced missing values inside the common support.", call. = FALSE)

  dt <- if (length(grid) > 1L) mean(diff(grid)) else 1
  weighted <- curves * sqrt(dt)
  pc <- stats::prcomp(weighted, center = TRUE, scale. = FALSE)
  pve_each <- pc$sdev^2 / sum(pc$sdev^2)
  if (is.null(npc)) npc <- which(cumsum(pve_each) >= pve)[1L]
  npc <- min(as.integer(npc), ncol(pc$rotation))
  efun <- pc$rotation[, seq_len(npc), drop = FALSE] / sqrt(dt)
  scores <- pc$x[, seq_len(npc), drop = FALSE]
  mean_curve <- colMeans(curves)
  list(
    engine_fit = pc,
    grid = grid,
    curves = curves,
    mean = mean_curve,
    eigenfunctions = efun,
    scores = scores,
    eigenvalues = pc$sdev[seq_len(npc)]^2,
    pve_each = pve_each[seq_len(npc)],
    pve_cumulative = cumsum(pve_each)[seq_len(npc)],
    npc = npc,
    common_support = c(lo, hi)
  )
}

#' Functional principal component analysis of plant growth trajectories
#'
#' @description
#' Treats each persistent plant or experimental unit as a trajectory. The built-in
#' `"grid"` engine reconstructs every unit only on the common observed support and
#' performs an L2-scaled discretized FPCA. Optional `fdapace` and `refund` engines
#' are available for sparse or irregular functional data and are never installed
#' automatically.
#'
#' @param x An `agri_growth_data` object or data frame.
#' @param time,response,unit Column names.
#' @param group Optional grouping column retained with scores.
#' @param engine One of `"grid"`, `"fdapace"`, or `"refund"`.
#' @param aggregate Destructive-sampling aggregation rule.
#' @param grid_n Grid size for the built-in engine.
#' @param npc Optional number of principal components.
#' @param pve Target cumulative proportion of variance explained when `npc` is omitted.
#' @param smooth `"smooth_spline"` or `"linear"` for grid reconstruction.
#' @param nbasis Basis dimension forwarded to `refund::fpca.sc()`.
#' @return An object of class `agri_growth_fpca`.
#' @export
#' @examples
#' # 1) Functional principal components with the grid engine
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' fp <- growth_fpca(g, response = "height_cm", engine = "grid", grid_n = 41)
#' class(fp)
#'
#' # 2) A fixed number of components
#' growth_fpca(g, response = "height_cm", engine = "grid", npc = 2, grid_n = 41)
#'
#' # 3) One fit per group
#' growth_fpca(g, response = "height_cm", group = "water_regime",
#'             engine = "grid", grid_n = 31)
growth_fpca <- function(x,
                        time = NULL,
                        response = NULL,
                        unit = NULL,
                        group = NULL,
                        engine = c("grid", "fdapace", "refund"),
                        aggregate = c("auto", "none", "mean"),
                        grid_n = 101L,
                        npc = NULL,
                        pve = 0.95,
                        smooth = c("smooth_spline", "linear"),
                        nbasis = 10L) {
  engine <- match.arg(engine)
  aggregate <- match.arg(aggregate)
  smooth <- match.arg(smooth)
  if (!is.numeric(pve) || length(pve) != 1L || pve <= 0 || pve > 1) stop("`pve` must be in (0, 1].", call. = FALSE)
  if (!is.null(npc) && (!is.numeric(npc) || length(npc) != 1L || npc < 1)) stop("`npc` must be a positive integer.", call. = FALSE)
  d <- .agf_prepare_longitudinal(
    x, time = time, response = response, unit = unit, group = group,
    aggregate = aggregate, require_unit = TRUE, min_times = 3L,
    auto_group = FALSE, auto_block = FALSE
  )
  per_unit <- table(d$.unit)
  if (any(per_unit < 3L)) stop("Every persistent unit needs at least three observations for FPCA.", call. = FALSE)
  group_levels_by_unit <- tapply(as.character(d$.group), d$.unit, function(z) length(unique(z)))
  if (any(group_levels_by_unit > 1L)) {
    stop("`group` must be invariant within each persistent unit for FPCA score labeling.", call. = FALSE)
  }
  id_group <- tapply(as.character(d$.group), d$.unit, function(z) unique(z)[1L])

  if (identical(engine, "grid")) {
    z <- .agf_grid_fpca(d, grid_n = grid_n, npc = npc, pve = pve, smooth = smooth)
  } else if (identical(engine, "fdapace")) {
    if (!requireNamespace("fdapace", quietly = TRUE)) stop("`engine = \"fdapace\"` requires the optional `fdapace` package.", call. = FALSE)
    L <- .agf_functional_lists(d)
    opts <- list(dataType = "Sparse", error = TRUE, verbose = FALSE)
    if (is.null(npc)) {
      opts$methodSelectK <- "FVE"
      opts$FVEthreshold <- pve
    } else {
      opts$methodSelectK <- as.integer(npc)
      opts$maxK <- max(as.integer(npc), 2L)
    }
    fit <- fdapace::FPCA(L$Ly, L$Lt, opts)
    ev <- fit$lambda
    use <- min(if (!is.null(fit$selectK)) fit$selectK else length(ev), length(ev))
    total_fve <- if (!is.null(fit$FVE) && is.finite(fit$FVE)) fit$FVE else 1
    pe <- ev[seq_len(use)] / sum(ev[seq_len(use)]) * total_fve
    z <- list(
      engine_fit = fit,
      grid = fit$workGrid,
      curves = NULL,
      mean = fit$mu,
      eigenfunctions = fit$phi[, seq_len(use), drop = FALSE],
      scores = fit$xiEst[, seq_len(use), drop = FALSE],
      eigenvalues = ev[seq_len(use)],
      pve_each = pe,
      pve_cumulative = cumsum(pe),
      npc = use,
      common_support = range(unlist(L$Lt))
    )
    rownames(z$scores) <- L$ids
  } else {
    if (!requireNamespace("refund", quietly = TRUE)) stop("`engine = \"refund\"` requires the optional `refund` package.", call. = FALSE)
    ydata <- data.frame(.id = as.character(d$.unit), .index = d$.t, .value = d$.y)
    args <- list(ydata = ydata, nbasis = as.integer(nbasis), pve = pve)
    if (!is.null(npc)) args$npc <- as.integer(npc)
    fit <- do.call(refund::fpca.sc, args)
    use <- fit$npc
    total_pve <- if (!is.null(fit$pve) && is.finite(fit$pve)) fit$pve else 1
    pe <- fit$evalues[seq_len(use)] / sum(fit$evalues[seq_len(use)]) * total_pve
    z <- list(
      engine_fit = fit,
      grid = fit$argvals,
      curves = fit$Y,
      mean = fit$mu,
      eigenfunctions = fit$efunctions[, seq_len(use), drop = FALSE],
      scores = fit$scores[, seq_len(use), drop = FALSE],
      eigenvalues = fit$evalues[seq_len(use)],
      pve_each = pe,
      pve_cumulative = cumsum(pe),
      npc = use,
      common_support = range(d$.t)
    )
    if (is.null(rownames(z$scores))) rownames(z$scores) <- levels(d$.unit)[seq_len(nrow(z$scores))]
  }

  score_ids <- rownames(z$scores)
  score_groups <- unname(id_group[score_ids])
  scores_df <- data.frame(unit = score_ids, group = score_groups, z$scores, check.names = FALSE, stringsAsFactors = FALSE)
  names(scores_df)[-(1:2)] <- paste0("FPC", seq_len(z$npc))
  out <- c(z, list(
    engine = engine,
    scores_table = scores_df,
    time_name = attr(d, "time_name"),
    response_name = attr(d, "response_name"),
    unit_name = attr(d, "unit_name"),
    group_name = attr(d, "group_name"),
    aggregation = attr(d, "aggregation"),
    input_data = d
  ))
  class(out) <- "agri_growth_fpca"
  out
}

#' Functional growth analysis alias
#' @inheritParams growth_fpca
#' @return An `agri_growth_fpca` object.
#' @export
#' @examples
#' # 1) Same interface as growth_fpca()
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' class(growth_functional(g, response = "height_cm", engine = "grid", grid_n = 41))
#'
#' # 2) Linear smoothing and a smaller basis
#' growth_functional(g, response = "height_cm", engine = "grid",
#'                   smooth = "linear", nbasis = 8, grid_n = 31)
#'
#' # 3) fdapace engine (requires the fdapace package)
#' \donttest{
#' if (requireNamespace("fdapace", quietly = TRUE)) {
#'   growth_functional(g, response = "height_cm", engine = "fdapace")
#' }
#' }
growth_functional <- function(x, time = NULL, response = NULL, unit = NULL, group = NULL,
                              engine = c("grid", "fdapace", "refund"), aggregate = c("auto", "none", "mean"),
                              grid_n = 101L, npc = NULL, pve = 0.95,
                              smooth = c("smooth_spline", "linear"), nbasis = 10L) {
  growth_fpca(x, time = time, response = response, unit = unit, group = group,
              engine = engine, aggregate = aggregate, grid_n = grid_n, npc = npc,
              pve = pve, smooth = smooth, nbasis = nbasis)
}

#' @export
#' @examples
#' # 1) FPCA summary
#' b <- growth_example_data("bean_repeated")
#' g <- growth_data(b, time = "day", sampling = "repeated",
#'                  experimental_unit = "plant_id", treatment = "water_regime")
#' fp <- growth_fpca(g, response = "height_cm", engine = "grid", grid_n = 31)
#' print(fp)
#'
#' # 2) Structure
#' str(fp, max.level = 1)
#'
#' # 3) Invisible return
#' identical(print(fp), fp)
print.agri_growth_fpca <- function(x, ...) {
  cat("<agri_growth_fpca> engine:", x$engine, " components:", x$npc, "\n")
  cat("Units:", nrow(x$scores_table), " support:", paste(.agf_fmt(x$common_support), collapse = " to "), "\n")
  tab <- data.frame(component = paste0("FPC", seq_len(x$npc)), pve = x$pve_each, cumulative = x$pve_cumulative)
  print(tab, row.names = FALSE)
  invisible(x)
}
