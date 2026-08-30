\name{growth_plot}
\alias{growth_plot}
\title{Plot plant-growth trajectories}
\usage{growth_plot(x, response = NULL, time = NULL, group = NULL, facet = NULL,
  summary = c("raw", "mean_se", "both"), log_y = FALSE, connect = NULL)}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{response}{Response column.}
\item{time}{Time or x-axis column.}
\item{group}{Grouping/color column.}
\item{facet}{Optional facet column.}
\item{summary}{Raw observations, mean with SE, or both.}
\item{log_y}{Use a logarithmic y scale.}
\item{connect}{Connect observations within a declared stable unit.}
}
\description{Creates an initial ggplot visualization while preserving raw observations and, when requested, within-unit trajectories.}
