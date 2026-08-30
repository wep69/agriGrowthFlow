\name{growth_manova}
\alias{growth_curve_coefficients}
\alias{growth_manova}
\title{Orthogonal polynomial growth components and MANOVA}
\usage{
growth_curve_coefficients(x, time = NULL, response = NULL, unit = NULL,
  group = NULL, degree = 2L, transform = c("none", "log"),
  aggregate = c("auto", "none", "mean"))

growth_manova(x, time = NULL, response = NULL, unit = NULL,
  group = NULL, degree = 2L, transform = c("none", "log"),
  aggregate = c("auto", "none", "mean"),
  test = c("Pillai", "Wilks", "Hotelling-Lawley", "Roy"))
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time, response, unit, group}{Column names.}
\item{degree}{Orthogonal polynomial degree.}
\item{transform}{Optional response transformation.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{test}{Multivariate test statistic.}
}
\description{
Represents each persistent experimental unit by orthogonal polynomial curve coefficients and compares groups multivariately with MANOVA.
}
\details{
All persistent units must share the same observed time grid. Missing harvests are not silently interpolated because doing so would change the inferential object. For destructive experiments, subsamples are first averaged within persistent experimental unit and harvest time under automatic aggregation.
}
\value{\code{growth_curve_coefficients()} returns one coefficient row per persistent unit. \code{growth_manova()} returns an \code{agri_growth_manova} object containing the MANOVA fit, multivariate summary, and component-wise ANOVAs.}
