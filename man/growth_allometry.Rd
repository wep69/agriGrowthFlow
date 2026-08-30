\name{growth_allometry}
\alias{growth_allometry}
\title{Log-log allometric analysis}
\usage{growth_allometry(data, x, y, group = NULL, level = 0.95)}
\arguments{
\item{data}{Data frame.}
\item{x,y}{Positive numeric variable names.}
\item{group}{Optional grouping column.}
\item{level}{Confidence level for the allometric exponent.}
}
\description{Fits log(y) = log(a) + k log(x) by ordinary least squares and returns the allometric coefficient, interval and fit summaries. OLS is directional and is not equivalent to standardized major-axis regression.}
