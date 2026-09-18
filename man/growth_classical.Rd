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

\examples{

## growth_classical()
# 1) Indices per persistent unit
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", treatment = "nitrogen",
                 block = "block", total_mass = "total_mass_g",
                 leaf_area = "leaf_area_m2", leaf_mass = "leaf_mass_g",
                 ground_area = "ground_area_m2")
cl <- growth_classical(g)
head(cl$intervals[, c("plot_id", "t1", "t2", "AGR", "RGR")])

# 2) Group by treatment
names(growth_classical(g, by = "nitrogen")$intervals)[1:3]

# 3) Unit declared explicitly
growth_classical(g, unit = "plot_id")$unit

## growth_indices()
# 1) Shortcut for growth_classical()
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", treatment = "nitrogen",
                 block = "block", total_mass = "total_mass_g")
ii <- growth_indices(g)
class(ii)

# 2) Available metrics
setdiff(names(ii$intervals), c("nitrogen", "block", "plot_id", "t1", "t2", "dt"))

# 3) Table aggregated by unit and time
head(ii$aggregated, 3)

## print.agri_growth_indices()
# 1) Summary of the object
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
print(growth_indices(g))

# 2) Invisible return
ii <- growth_indices(g)
identical(print(ii), ii)

# 3) Structure
str(ii, max.level = 1)
}
