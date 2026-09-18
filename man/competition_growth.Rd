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

\examples{

## growth_density()
# 1) Density and per-plant mass analysis
d <- growth_example_data("maize_density")
dn <- growth_density(d, density = "density_plants_m2",
                     plant_mass = "plant_mass_g")
class(dn)

# 2) Structure of the result
str(dn, max.level = 1)

# 3) Printed summary
print(dn)

## growth_neighbor()
# 1) Neighborhood index
d <- growth_example_data("tree_competition")
nb <- growth_neighbor(d, id = "plant_id", x = "x_m", y = "y_m", size = "size_cm")
head(nb)

# 2) Limited neighborhood radius
head(growth_neighbor(d, id = "plant_id", x = "x_m", y = "y_m", size = "size_cm",
                     radius = 5))

# 3) Distance and size powers
head(growth_neighbor(d, id = "plant_id", x = "x_m", y = "y_m", size = "size_cm",
                     distance_power = 2, size_power = 0.5))

## growth_competition()
# 1) Coupled logistic simulation
cm <- growth_competition(initial_size = c(1, 1.5), times = seq(0, 60, by = 10),
                         r = c(0.15, 0.12), K = c(100, 90),
                         competition_matrix = matrix(c(1, 0.4, 0.3, 1), 2, 2))
class(cm)

# 2) Smaller integration step
growth_competition(initial_size = c(1, 1.5), times = seq(0, 60, by = 10),
                   r = c(0.15, 0.12), K = c(100, 90),
                   competition_matrix = matrix(c(1, 0.4, 0.3, 1), 2, 2),
                   dt = 0.05)$settings

# 3) Printed summary
print(cm)

## print.agri_growth_density()
# 1) Density analysis summary
d <- growth_example_data("maize_density")
dn <- growth_density(d, density = "density_plants_m2", plant_mass = "plant_mass_g")
print(dn)

# 2) Structure
str(dn, max.level = 1)

# 3) Invisible return
identical(print(dn), dn)

## print.agri_growth_competition()
# 1) Simulation summary
cm <- growth_competition(initial_size = c(1, 1.5), times = seq(0, 60, by = 10),
                         r = c(0.15, 0.12), K = c(100, 90),
                         competition_matrix = matrix(c(1, 0.4, 0.3, 1), 2, 2))
print(cm)

# 2) Structure
str(cm, max.level = 1)

# 3) Invisible return
identical(print(cm), cm)
}
