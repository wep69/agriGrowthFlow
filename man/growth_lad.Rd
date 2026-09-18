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

\examples{

## growth_lad()
# 1) Total leaf area duration
growth_lad(lai = c(0.5, 1.2, 2.5, 3.1), time = c(14, 28, 42, 56))

# 2) Interval-by-interval table
growth_lad(lai = c(0.5, 1.2, 2.5, 3.1), time = c(14, 28, 42, 56),
           intervals = TRUE)

# 3) Handling gaps
growth_lad(lai = c(0.5, NA, 2.5), time = c(14, 28, 42), na.rm = TRUE)
growth_lad(lai = c(0.5, NA, 2.5), time = c(14, 28, 42), na.rm = FALSE)
}
