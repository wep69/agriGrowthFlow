\name{growth_predict}
\alias{growth_predict}
\alias{growth_compare}
\alias{growth_diagnose}
\title{Predict, compare, and diagnose parametric growth models}
\usage{
growth_predict(object, time = NULL,
  interval = c("none", "confidence", "prediction"), level = 0.95)

growth_compare(...)

growth_diagnose(object, boundary_fraction = 0.01)
}
\arguments{
\item{object}{A parametric growth fit, fit set, or grouped fit collection as appropriate.}
\item{time}{Optional numeric prediction times.}
\item{interval}{Point predictions, confidence intervals, or prediction intervals.}
\item{level}{Interval confidence level.}
\item{...}{Parametric fits or one candidate fit set.}
\item{boundary_fraction}{Fraction of a hard-bound span used to flag near-bound coefficients.}
}
\description{Produces fitted trajectories and local delta-method intervals, refuses information-criterion comparison across different prepared observations, and summarizes residual, convergence, boundary, conditioning, and within-unit lag diagnostics.}
\value{Data frames or an \code{agri_growth_diagnostics} object, depending on the function.}
