\name{growth_partition}
\alias{growth_partition}
\title{Biomass partitioning with closure checks}
\usage{growth_partition(data, total_mass = NULL, components = NULL,
  normalize = FALSE, tolerance = 0.02, prefix = "frac_")}
\arguments{
\item{data}{Data frame or \code{agri_growth_data} object.}
\item{total_mass}{Total mass column.}
\item{components}{Component-mass columns.}
\item{normalize}{Normalize by the supplied component sum rather than total mass.}
\item{tolerance}{Closure tolerance.}
\item{prefix}{Fraction-column prefix.}
}
\description{Calculates biomass fractions while retaining component closure and unallocated biomass. Fractions are not silently renormalized by default.}
