\name{growth_fit}
\alias{growth_fit}
\alias{growth_multistart}
\alias{agri_growth_fit}
\alias{agri_growth_fit_set}
\alias{agri_growth_fit_collection}
\title{Fit parametric plant-growth models}
\usage{
growth_fit(x, model = "logistic", time = NULL, response = NULL, group = NULL,
  start = NULL, n_start = 1L, seed = NULL,
  engine = c("auto", "nls", "minpack.lm"),
  aggregate = c("auto", "none", "mean"), control = list())

growth_multistart(x, model = "logistic", time = NULL, response = NULL,
  group = NULL, start = NULL, n_start = 30L, seed = NULL,
  engine = c("auto", "nls", "minpack.lm"),
  aggregate = c("auto", "none", "mean"), control = list())
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{model}{One or more built-in model names.}
\item{time,response}{Column names when \code{x} is a data frame.}
\item{group}{Optional grouping column for separate descriptive fits.}
\item{start}{Optional named public starting values for one model.}
\item{n_start}{Number of fitting starts.}
\item{seed}{Optional random seed for multistart generation.}
\item{engine}{Base \code{nls}, optional \code{minpack.lm}, or automatic engine selection.}
\item{aggregate}{Destructive-data aggregation rule.}
\item{control}{Optional optimizer-control list.}
}
\description{Fits bounded nonlinear plant-growth models. Serial destructive or repeated structures retain explicit warnings because ordinary nonlinear least squares does not represent within-unit longitudinal dependence.}
\value{A single fit, candidate fit set, or grouped fit collection.}
