\name{multiphase_events}
\alias{growth_multiphase}
\alias{growth_diphasic}
\alias{growth_stability}
\alias{growth_changepoint}
\title{Multiphase growth, stability points, and changepoints}
\usage{
growth_multiphase(x, time = NULL, response = NULL, n_phases = 2L,
  group = NULL, start = NULL, n_start = 20L, seed = NULL,
  aggregate = c("auto", "none", "mean"), control = list())

growth_diphasic(x, time = NULL, response = NULL, group = NULL,
  start = NULL, n_start = 20L, seed = NULL,
  aggregate = c("auto", "none", "mean"), control = list())

growth_stability(object, interval = NULL, n = 2001L)

growth_changepoint(data, time, response, min_segment = 3L,
  candidates = NULL)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time,response}{Time and response columns when required.}
\item{n_phases}{One to three ordered logistic phases.}
\item{group}{Optional column for separate descriptive trajectories.}
\item{start}{Optional internal transformed starting vector.}
\item{n_start}{Number of optimization starts.}
\item{seed}{Optional random seed.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{control}{List passed to \code{stats::optim()}.}
\item{object}{A fitted growth object supported by the numerical derivative layer.}
\item{interval}{Optional time interval for numerical searches.}
\item{n}{Grid density.}
\item{data}{A data frame.}
\item{min_segment}{Minimum number of distinct times required on each side of a changepoint.}
\item{candidates}{Optional candidate changepoint times.}
}
\description{Fits sums of ordered logistic phases, locates fourth-derivative stability points on the complete fitted curve, and provides an exploratory continuous piecewise-linear changepoint search.}
\value{Structured fit or diagnostic objects, or data frames of critical points.}
