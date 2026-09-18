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

\examples{

## growth_smooth()
# 1) Smoothing spline
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
sm$method

# 2) LOESS with a smaller span
growth_smooth(g, response = "height_cm", method = "loess", span = 0.5)$method

# 3) Monotonically increasing SCAM
growth_smooth(g, response = "height_cm", method = "scam",
              constraint = "increasing")$constraint

## growth_smooth_predict()
# 1) Prediction on an explicit grid
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
growth_smooth_predict(sm, time = c(10, 20, 30, 40))

# 2) Default grid with n points
nrow(growth_smooth_predict(sm, n = 50))

# 3) Predictions outside the support are flagged
growth_smooth_predict(sm, time = c(1, 20, 60))$inside_support

## growth_derivative()
# 1) First derivative
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
dv <- growth_derivative(sm, order = 1)
head(dv)

# 2) Second derivative
nrow(growth_derivative(sm, order = 2))

# 3) Explicit time grid
growth_derivative(sm, order = 1, time = c(10, 20, 30))

## growth_acceleration()
# 1) Acceleration along the support
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
ac <- growth_acceleration(sm)
head(ac)

# 2) More points and a smaller step
nrow(growth_acceleration(sm, n = 30, eps = 1e-6))

# 3) Explicit grid
growth_acceleration(sm, time = c(15, 25, 35))

## growth_smooth_traits()
# 1) Traits of the smoothed curve
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
growth_smooth_traits(sm)

# 2) More points on the internal grid
growth_smooth_traits(sm, n = 400)$peak_response

# 3) Traits by group
sg <- growth_smooth(g, response = "height_cm", group = "water_regime")
growth_smooth_traits(sg)[, c("group", "maximum_growth_rate")]

## print.agri_growth_smooth()
# 1) Smoother summary
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sm <- growth_smooth(g, response = "height_cm")
print(sm)

# 2) Structure
str(sm, max.level = 1)

# 3) Invisible return
identical(print(sm), sm)

## print.agri_growth_smooth_collection()
# 1) A collection by group
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
sg <- growth_smooth(g, response = "height_cm", group = "water_regime")
print(sg)

# 2) Group names
names(sg$fits)

# 3) Invisible return
identical(print(sg), sg)
}
