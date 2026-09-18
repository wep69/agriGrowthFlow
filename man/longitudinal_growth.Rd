\name{growth_mixed}
\alias{growth_mixed}
\alias{growth_mixed_diagnose}
\title{Longitudinal mixed-effects plant growth analysis}
\usage{
growth_mixed(x, time = NULL, response = NULL, unit = NULL, group = NULL,
  block = NULL, degree = 2L, random_degree = 1L,
  correlation = c("none", "ar1", "car1"),
  variance = c("none", "power", "exponential", "group", "time"),
  method = c("REML", "ML"), aggregate = c("auto", "none", "mean"),
  control = list())

growth_mixed_diagnose(object)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time, response, unit, group, block}{Column names when they are not available from the declared growth-data roles.}
\item{degree}{Fixed orthogonal polynomial degree for time.}
\item{random_degree}{Within-unit random polynomial degree; zero gives random intercepts only.}
\item{correlation}{Residual correlation structure.}
\item{variance}{Residual variance structure.}
\item{method}{REML or ML estimation.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{control}{List passed to \code{nlme::lmeControl()}.}
\item{object}{An object returned by \code{growth_mixed()}.}
}
\description{
Fits design-aware polynomial longitudinal growth models using \code{nlme::lme()} and provides residual and within-unit lag diagnostics. Declared treatment and block roles are used automatically for \code{agri_growth_data} inputs.
}
\details{
\code{correlation="ar1"} is restricted to integer-valued time. Use \code{correlation="car1"} for irregular continuous time. Destructive subsamples are averaged within persistent experimental unit and time under the default automatic aggregation rule. The function does not select covariance structures only by significance tests; scientific design, residual dependence, fit diagnostics, and interpretability should be considered together.
}
\value{\code{growth_mixed()} returns an \code{agri_growth_mixed} object. \code{growth_mixed_diagnose()} returns an \code{agri_growth_mixed_diagnostics} object.}

\examples{

## growth_mixed()
# 1) Mixed model with degree 2
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime",
                 block = "block")
mx <- growth_mixed(g, response = "height_cm")
mx$method

# 2) Lower fixed degree
growth_mixed(g, response = "height_cm", degree = 1)$degree

# 3) AR(1) residual correlation
growth_mixed(g, response = "height_cm", correlation = "ar1")$correlation

## growth_mixed_diagnose()
# 1) Diagnostics of the mixed model
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime",
                 block = "block")
mx <- growth_mixed(g, response = "height_cm")
md <- growth_mixed_diagnose(mx)
class(md)

# 2) Printed summary
print(md)

# 3) Structure
str(md, max.level = 1)

## print.agri_growth_mixed()
# 1) Model summary
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
mx <- growth_mixed(g, response = "height_cm")
print(mx)

# 2) Fixed effects
nlme::fixef(mx$fit)

# 3) Invisible return
identical(print(mx), mx)

## print.agri_growth_mixed_diagnostics()
# 1) Printed diagnostics
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
mx <- growth_mixed(g, response = "height_cm")
print(growth_mixed_diagnose(mx))

# 2) Structure
str(growth_mixed_diagnose(mx), max.level = 1)

# 3) Invisible return
md <- growth_mixed_diagnose(mx)
identical(print(md), md)
}
