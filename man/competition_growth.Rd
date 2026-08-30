\name{competition_growth}
\alias{growth_density}
\alias{growth_neighbor}
\alias{growth_competition}
\title{Plant density, neighborhood competition, and coupled growth simulation}
\usage{
growth_density(data, density, plant_mass)

growth_neighbor(data, id, x, y, size, radius = Inf,
  distance_power = 1, size_power = 1)

growth_competition(initial_size, times, r, K, competition_matrix,
  dt = 0.1)
}
\arguments{
\item{data}{A data frame.}
\item{density,plant_mass}{Density and individual plant-mass columns.}
\item{id,x,y,size}{Plant identifier, planar coordinates, and plant-size columns.}
\item{radius}{Maximum neighborhood radius.}
\item{distance_power}{Distance exponent in the transparent competition index.}
\item{size_power}{Neighbor-to-focal size-ratio exponent.}
\item{initial_size}{Positive initial plant sizes.}
\item{times}{Increasing output times.}
\item{r}{Intrinsic growth rates.}
\item{K}{Carrying sizes.}
\item{competition_matrix}{Non-negative inter-plant competition matrix.}
\item{dt}{Maximum RK4 integration step.}
}
\description{Provides a reciprocal individual-size versus density model, a transparent distance-and-size neighborhood index, and a generic coupled-logistic competition simulator. The simulator is not an implementation of the exact zone-of-influence equations of Gates.}
\value{Structured density or competition objects, or a data frame of neighborhood indices.}
