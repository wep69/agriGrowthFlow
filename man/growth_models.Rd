\name{growth_models}
\alias{growth_models}
\alias{growth_start}
\alias{agri_growth_start}
\title{Inspect parametric growth models and starting values}
\usage{
growth_models()

growth_start(x, model, time = NULL, response = NULL, group = NULL,
  aggregate = c("auto", "none", "mean"))
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{model}{Built-in growth-model name.}
\item{time,response}{Column names when \code{x} is a data frame.}
\item{group}{Optional grouping column.}
\item{aggregate}{Rule used to aggregate destructive sampling replicates.}
}
\description{Lists the built-in 0.2.0 parametric equations and exposes deterministic automatic starting values plus hard bounds before nonlinear optimization.}
\value{\code{growth_models()} returns a data frame. \code{growth_start()} returns an object of class \code{agri_growth_start}.}
