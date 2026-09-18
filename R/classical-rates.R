#' Classical plant growth quantities
#'
#' @description
#' Vectorized functions implementing foundational plant growth quantities over one
#' or more intervals. Inputs must use mutually compatible physical units.
#'
#' @param w1,w2 Total dry mass at the beginning and end of an interval.
#' @param t1,t2 Beginning and end times.
#' @param a1,a2 Leaf area at the beginning and end of an interval.
#' @param leaf_area Leaf area.
#' @param total_mass Total dry mass.
#' @param leaf_mass Leaf dry mass.
#' @param ground_area Ground area represented by the observation.
#' @param tolerance Numerical tolerance for equal-area limits in NAR.
#'
#' @details
#' The mean interval quantities are
#' \deqn{AGR = (W_2-W_1)/(t_2-t_1),}
#' \deqn{RGR = [\log(W_2)-\log(W_1)]/(t_2-t_1),}
#' and, for positive unequal leaf areas,
#' \deqn{NAR = [(W_2-W_1)/(t_2-t_1)] [\log(A_2)-\log(A_1)]/(A_2-A_1).}
#' When `a1` and `a2` are numerically equal, `growth_nar()` uses the continuous
#' limit `AGR / A` rather than returning a numerical singularity.
#'
#' @return Numeric vectors.
#' @references
#' Hunt R (1990). *Basic Growth Analysis: Plant Growth Analysis for Beginners*.
#' Springer/Unwin Hyman. doi:10.1007/978-94-010-9117-6.
#' @name classical_growth_rates
NULL

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) One interval
#' growth_agr(w1 = 10, w2 = 25, t1 = 14, t2 = 28)
#'
#' # 2) Several intervals at once
#' growth_agr(c(10, 25, 60), c(25, 60, 110), c(14, 28, 42), c(28, 42, 56))
#'
#' # 3) Columns of a data frame
#' d <- data.frame(w1 = c(5, 8), w2 = c(9, 20), t1 = c(0, 7), t2 = c(7, 14))
#' with(d, growth_agr(w1, w2, t1, t2))
growth_agr <- function(w1, w2, t1, t2) {
  .agf_assert_numeric(w1, "w1")
  .agf_assert_numeric(w2, "w2")
  .agf_assert_numeric(t1, "t1")
  .agf_assert_numeric(t2, "t2")
  z <- .agf_recycle_numeric(list(w1, w2, t1, t2), c("w1", "w2", "t1", "t2"))
  dt <- z$t2 - z$t1
  if (any(dt == 0, na.rm = TRUE)) stop("Time intervals must be non-zero.", call. = FALSE)
  (z$w2 - z$w1) / dt
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) One interval
#' growth_rgr(w1 = 10, w2 = 25, t1 = 14, t2 = 28)
#'
#' # 2) A mass loss gives a negative rate
#' growth_rgr(w1 = 25, w2 = 10, t1 = 14, t2 = 28)
#'
#' # 3) Vectorized
#' growth_rgr(c(10, 25), c(25, 60), c(14, 28), c(28, 42))
growth_rgr <- function(w1, w2, t1, t2) {
  .agf_assert_numeric(w1, "w1")
  .agf_assert_numeric(w2, "w2")
  .agf_assert_numeric(t1, "t1")
  .agf_assert_numeric(t2, "t2")
  z <- .agf_recycle_numeric(list(w1, w2, t1, t2), c("w1", "w2", "t1", "t2"))
  if (any(z$w1 <= 0 | z$w2 <= 0, na.rm = TRUE)) stop("RGR requires positive beginning and end masses.", call. = FALSE)
  dt <- z$t2 - z$t1
  if (any(dt == 0, na.rm = TRUE)) stop("Time intervals must be non-zero.", call. = FALSE)
  (log(z$w2) - log(z$w1)) / dt
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) One interval with unequal leaf areas
#' growth_nar(w1 = 10, w2 = 25, a1 = 2, a2 = 5, t1 = 14, t2 = 28)
#'
#' # 2) Equal areas use the continuous limit
#' growth_nar(w1 = 10, w2 = 25, a1 = 3, a2 = 3, t1 = 14, t2 = 28)
#'
#' # 3) Tolerance for near-equality
#' growth_nar(10, 25, 3, 3 + 1e-10, 14, 28, tolerance = 1e-6)
growth_nar <- function(w1, w2, a1, a2, t1, t2, tolerance = sqrt(.Machine$double.eps)) {
  .agf_assert_numeric(w1, "w1")
  .agf_assert_numeric(w2, "w2")
  .agf_assert_numeric(a1, "a1")
  .agf_assert_numeric(a2, "a2")
  z <- .agf_recycle_numeric(list(w1, w2, a1, a2, t1, t2), c("w1", "w2", "a1", "a2", "t1", "t2"))
  if (any(z$a1 <= 0 | z$a2 <= 0, na.rm = TRUE)) stop("NAR requires positive leaf areas.", call. = FALSE)
  agr <- growth_agr(z$w1, z$w2, z$t1, z$t2)
  delta_a <- z$a2 - z$a1
  same <- abs(delta_a) <= tolerance * pmax(1, abs(z$a1), abs(z$a2))
  factor <- rep(NA_real_, length(delta_a))
  factor[same] <- 1 / ((z$a1[same] + z$a2[same]) / 2)
  factor[!same] <- (log(z$a2[!same]) - log(z$a1[!same])) / delta_a[!same]
  agr * factor
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) Leaf area ratio
#' growth_lar(leaf_area = 0.5, total_mass = 25)
#'
#' # 2) Vectorized
#' growth_lar(c(0.5, 0.9), c(25, 40))
#'
#' # 3) Columns of a data frame
#' d <- data.frame(area = c(0.5, 0.9), mass = c(25, 40))
#' with(d, growth_lar(area, mass))
growth_lar <- function(leaf_area, total_mass) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(total_mass, "total_mass")
  z <- .agf_recycle_numeric(list(leaf_area, total_mass), c('leaf_area', 'total_mass'))
  if (any(z$total_mass <= 0, na.rm = TRUE)) stop("LAR requires positive total mass.", call. = FALSE)
  z$leaf_area / z$total_mass
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) Specific leaf area
#' growth_sla(leaf_area = 0.5, leaf_mass = 10)
#'
#' # 2) Vectorized
#' growth_sla(c(0.5, 0.8), c(10, 12))
#'
#' # 3) Invalid input
#' try(growth_sla(leaf_area = -0.5, leaf_mass = 10))
growth_sla <- function(leaf_area, leaf_mass) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(leaf_mass, "leaf_mass")
  z <- .agf_recycle_numeric(list(leaf_area, leaf_mass), c('leaf_area', 'leaf_mass'))
  if (any(z$leaf_mass <= 0, na.rm = TRUE)) stop("SLA requires positive leaf mass.", call. = FALSE)
  z$leaf_area / z$leaf_mass
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) Leaf mass ratio
#' growth_lmr(leaf_mass = 10, total_mass = 25)
#'
#' # 2) Vectorized
#' growth_lmr(c(10, 18), c(25, 40))
#'
#' # 3) The identity LAR = SLA x LMR
#' sla <- growth_sla(leaf_area = 0.5, leaf_mass = 10)
#' lmr <- growth_lmr(leaf_mass = 10, total_mass = 25)
#' c(sla = sla, lmr = lmr, product = sla * lmr, lar = growth_lar(0.5, 25))
growth_lmr <- function(leaf_mass, total_mass) {
  .agf_assert_numeric(leaf_mass, "leaf_mass")
  .agf_assert_numeric(total_mass, "total_mass")
  z <- .agf_recycle_numeric(list(leaf_mass, total_mass), c('leaf_mass', 'total_mass'))
  if (any(z$total_mass <= 0, na.rm = TRUE)) stop("LMR requires positive total mass.", call. = FALSE)
  z$leaf_mass / z$total_mass
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) Leaf area index
#' growth_lai(leaf_area = 0.5, ground_area = 0.25)
#'
#' # 2) Vectorized
#' growth_lai(c(0.5, 1.0, 2.0), ground_area = 0.25)
#'
#' # 3) Invalid ground area
#' try(growth_lai(leaf_area = 0.5, ground_area = 0))
growth_lai <- function(leaf_area, ground_area) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(ground_area, "ground_area")
  z <- .agf_recycle_numeric(list(leaf_area, ground_area), c('leaf_area', 'ground_area'))
  if (any(z$ground_area <= 0, na.rm = TRUE)) stop("LAI requires positive ground area.", call. = FALSE)
  z$leaf_area / z$ground_area
}

#' @rdname classical_growth_rates
#' @export
#' @examples
#' # 1) Unit ground area
#' growth_cgr(10, 25, 14, 28)
#'
#' # 2) Declared ground area
#' growth_cgr(10, 25, 14, 28, ground_area = 0.25)
#'
#' # 3) Vectorized
#' growth_cgr(c(10, 25), c(25, 60), c(14, 28), c(28, 42), ground_area = 0.5)
growth_cgr <- function(w1, w2, t1, t2, ground_area = 1) {
  .agf_assert_numeric(w1, "w1")
  .agf_assert_numeric(w2, "w2")
  .agf_assert_numeric(t1, "t1")
  .agf_assert_numeric(t2, "t2")
  .agf_assert_numeric(ground_area, "ground_area")
  z <- .agf_recycle_numeric(list(w1, w2, t1, t2, ground_area), c("w1", "w2", "t1", "t2", "ground_area"))
  if (any(z$ground_area <= 0, na.rm = TRUE)) stop("CGR requires positive ground area.", call. = FALSE)
  growth_agr(z$w1, z$w2, z$t1, z$t2) / z$ground_area
}

#' Leaf area duration by trapezoidal integration
#'
#' @param lai Numeric leaf area index values in temporal order.
#' @param time Numeric times corresponding to `lai`.
#' @param intervals If `TRUE`, return interval contributions instead of the total.
#' @param na.rm If `TRUE`, intervals containing missing values are omitted from the total.
#'
#' @return A scalar LAD when `intervals = FALSE`, otherwise a data frame.
#' @export
#'
#' @examples
#' # 1) Total leaf area duration
#' growth_lad(lai = c(0.5, 1.2, 2.5, 3.1), time = c(14, 28, 42, 56))
#'
#' # 2) Interval-by-interval table
#' growth_lad(lai = c(0.5, 1.2, 2.5, 3.1), time = c(14, 28, 42, 56),
#'            intervals = TRUE)
#'
#' # 3) Handling gaps
#' growth_lad(lai = c(0.5, NA, 2.5), time = c(14, 28, 42), na.rm = TRUE)
#' growth_lad(lai = c(0.5, NA, 2.5), time = c(14, 28, 42), na.rm = FALSE)

growth_lad <- function(lai, time, intervals = FALSE, na.rm = FALSE) {
  .agf_assert_numeric(lai, "lai")
  .agf_assert_numeric(time, "time")
  if (length(lai) != length(time)) stop("`lai` and `time` must have the same length.", call. = FALSE)
  if (length(lai) < 2L) stop("At least two time points are required for LAD.", call. = FALSE)
  ord <- order(time)
  lai <- lai[ord]
  time <- time[ord]
  dt <- diff(time)
  if (any(dt <= 0, na.rm = TRUE)) stop("`time` must contain distinct increasing values after ordering.", call. = FALSE)
  contribution <- ((lai[-length(lai)] + lai[-1L]) / 2) * dt
  out <- data.frame(
    t1 = time[-length(time)],
    t2 = time[-1L],
    dt = dt,
    lai1 = lai[-length(lai)],
    lai2 = lai[-1L],
    lad = contribution
  )
  if (intervals) return(out)
  sum(contribution, na.rm = na.rm)
}
