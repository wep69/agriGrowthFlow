\name{growth_design}
\alias{growth_design}
\alias{growth_validate}
\alias{growth_plan}
\title{Declare, validate, and plan a plant-growth analysis}
\usage{
growth_design(x, design = c("auto", "crd", "rcbd", "repeated", "serial_destructive"),
  treatment = NULL, block = NULL, experimental_unit = NULL, subject = NULL,
  harvest_unit = NULL, phase = NULL, metadata = list())

growth_validate(x, strict = FALSE, min_times = 2L, desirable_times = 4L,
  tolerance = 1e-8)

growth_plan(x, desirable_times = 4L)
}
\arguments{
\item{x}{An \code{agri_growth_data} or \code{agri_growth_design} object.}
\item{design}{Declared experimental design label.}
\item{treatment,block,experimental_unit,subject,harvest_unit,phase}{Optional role columns.}
\item{metadata}{Named list.}
\item{strict}{Stop on error-level validation issues.}
\item{min_times}{Minimum times for an interval analysis.}
\item{desirable_times}{Desirable number of times for characterizing a phase.}
\item{tolerance}{Numerical tolerance.}
}
\description{Provides design-first safeguards for destructive and repeated plant-growth data. Validation detects structural conflicts but does not prove that randomization, sampling, or field execution were valid.}
