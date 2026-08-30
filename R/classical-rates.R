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
growth_lar <- function(leaf_area, total_mass) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(total_mass, "total_mass")
  z <- .agf_recycle_numeric(list(leaf_area, total_mass), c('leaf_area', 'total_mass'))
  if (any(z$total_mass <= 0, na.rm = TRUE)) stop("LAR requires positive total mass.", call. = FALSE)
  z$leaf_area / z$total_mass
}

#' @rdname classical_growth_rates
#' @export
growth_sla <- function(leaf_area, leaf_mass) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(leaf_mass, "leaf_mass")
  z <- .agf_recycle_numeric(list(leaf_area, leaf_mass), c('leaf_area', 'leaf_mass'))
  if (any(z$leaf_mass <= 0, na.rm = TRUE)) stop("SLA requires positive leaf mass.", call. = FALSE)
  z$leaf_area / z$leaf_mass
}

#' @rdname classical_growth_rates
#' @export
growth_lmr <- function(leaf_mass, total_mass) {
  .agf_assert_numeric(leaf_mass, "leaf_mass")
  .agf_assert_numeric(total_mass, "total_mass")
  z <- .agf_recycle_numeric(list(leaf_mass, total_mass), c('leaf_mass', 'total_mass'))
  if (any(z$total_mass <= 0, na.rm = TRUE)) stop("LMR requires positive total mass.", call. = FALSE)
  z$leaf_mass / z$total_mass
}

#' @rdname classical_growth_rates
#' @export
growth_lai <- function(leaf_area, ground_area) {
  .agf_assert_numeric(leaf_area, "leaf_area")
  .agf_assert_numeric(ground_area, "ground_area")
  z <- .agf_recycle_numeric(list(leaf_area, ground_area), c('leaf_area', 'ground_area'))
  if (any(z$ground_area <= 0, na.rm = TRUE)) stop("LAI requires positive ground area.", call. = FALSE)
  z$leaf_area / z$ground_area
}

#' @rdname classical_growth_rates
#' @export
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
#' growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10))

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
