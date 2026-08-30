\name{growth_classical}
\alias{growth_classical}
\alias{growth_indices}
\title{Design-aware classical interval growth analysis}
\usage{
growth_classical(x, time = NULL, total_mass = NULL, leaf_area = NULL,
  leaf_mass = NULL, ground_area = NULL, unit = NULL, by = NULL,
  na.rm = TRUE)

growth_indices(x, ...)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time,total_mass,leaf_area,leaf_mass,ground_area}{Measurement column names.}
\item{unit}{Stable interval unit.}
\item{by}{Additional grouping columns carried into output.}
\item{na.rm}{Remove missing values when averaging sampling replicates within unit and time.}
\item{...}{Arguments passed to \code{growth_classical()}.}
}
\description{Summarizes sampling replicates within stable unit and harvest time, then calculates consecutive interval growth quantities. This is especially important for serial destructive harvests.}
