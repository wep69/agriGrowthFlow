\name{growth_lad}
\alias{growth_lad}
\title{Leaf area duration}
\usage{growth_lad(lai, time, intervals = FALSE, na.rm = FALSE)}
\arguments{
\item{lai}{Leaf area index values.}
\item{time}{Corresponding times.}
\item{intervals}{Return interval contributions when TRUE.}
\item{na.rm}{Omit missing interval contributions from the total when TRUE.}
}
\description{Calculates leaf area duration as trapezoidal area under the LAI-time trajectory.}
