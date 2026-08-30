\name{growth_fpca}
\alias{growth_fpca}
\alias{growth_functional}
\title{Functional principal component analysis of plant growth trajectories}
\usage{
growth_fpca(x, time = NULL, response = NULL, unit = NULL, group = NULL,
  engine = c("grid", "fdapace", "refund"),
  aggregate = c("auto", "none", "mean"), grid_n = 101L,
  npc = NULL, pve = 0.95, smooth = c("smooth_spline", "linear"),
  nbasis = 10L)

growth_functional(x, time = NULL, response = NULL, unit = NULL,
  group = NULL, engine = c("grid", "fdapace", "refund"),
  aggregate = c("auto", "none", "mean"), grid_n = 101L,
  npc = NULL, pve = 0.95, smooth = c("smooth_spline", "linear"),
  nbasis = 10L)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time, response, unit, group}{Column names.}
\item{engine}{Functional-data engine.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{grid_n}{Common-support grid size for the built-in engine.}
\item{npc}{Optional number of functional principal components.}
\item{pve}{Target cumulative proportion of variance explained.}
\item{smooth}{Grid-reconstruction method.}
\item{nbasis}{Basis dimension for \code{refund::fpca.sc()}.}
}
\description{
Treats each persistent plant or experimental unit as a curve and decomposes between-trajectory variation with functional principal components.
}
\details{
The built-in grid engine never extrapolates beyond the common observed support. It performs a discretized L2-scaled FPCA. Optional \code{fdapace} and \code{refund} engines are intended for sparse or irregular functional data and are not installed automatically.
}
\value{An object of class \code{agri_growth_fpca} containing scores, eigenfunctions, eigenvalues, variance explained, mean curve, and support information.}
