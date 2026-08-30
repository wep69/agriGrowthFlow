\name{growth_smooth}
\alias{growth_smooth}
\alias{growth_smooth_predict}
\alias{growth_derivative}
\alias{growth_acceleration}
\alias{growth_smooth_traits}
\title{Flexible smoothing and derivatives of plant growth trajectories}
\usage{
growth_smooth(x, time = NULL, response = NULL, unit = NULL, group = NULL,
  method = c("smooth_spline", "loess", "gam", "scam"),
  aggregate = c("auto", "none", "mean"), population = TRUE,
  spar = NULL, cv = FALSE, span = 0.75, loess_degree = 2L,
  k = 10L, bs = "tp", constraint = c("increasing", "decreasing"),
  rho = 0, gam_method = "REML")

growth_smooth_predict(object, time = NULL, n = 100L)

growth_derivative(object, order = 1L, time = NULL, n = 100L, eps = 1e-4)

growth_acceleration(object, time = NULL, n = 100L, eps = 1e-4)

growth_smooth_traits(object, n = 400L)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time}{Optional time column for fitting, or optional prediction or derivative times for post-fit functions.}
\item{response, unit, group}{Column names. The optional persistent-unit column ensures equal unit weighting before population smoothing.}
\item{method}{Smoothing engine.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{population}{Whether to fit the persistent-unit time-specific mean trajectory.}
\item{spar, cv}{Smoothing-spline controls.}
\item{span, loess_degree}{LOESS controls.}
\item{k, bs, gam_method}{GAM/SCAM basis and smoothing controls.}
\item{constraint}{Opt-in monotonicity constraint for SCAM.}
\item{rho}{Optional Gaussian SCAM AR1 coefficient.}
\item{object}{A smooth object returned by \code{growth_smooth()}.}
\item{n}{Grid size.}
\item{order}{Derivative order, one or two.}
\item{eps}{Relative finite-difference step for LOESS, GAM, and SCAM.}
}
\description{
Fits form-flexible growth trajectories and derives first and second derivatives without forcing a predefined biological growth equation. Smoothing splines and LOESS are available in base R; GAM and monotone SCAM engines are optional.
}
\details{
Monotonicity is never imposed automatically. A shape constraint is inappropriate when biological senescence, defoliation, stress, or measurement dynamics can create a decline. Population smoothing estimates a descriptive mean trajectory and is not a substitute for mixed-effects longitudinal inference.
}
\value{Smooth fitting returns \code{agri_growth_smooth} objects or a grouped collection. Prediction, derivative, acceleration, and trait functions return data frames.}
