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
