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

\examples{

## growth_fpca()
# 1) Functional principal components with the grid engine
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
fp <- growth_fpca(g, response = "height_cm", engine = "grid", grid_n = 41)
class(fp)

# 2) A fixed number of components
growth_fpca(g, response = "height_cm", engine = "grid", npc = 2, grid_n = 41)

# 3) One fit per group
growth_fpca(g, response = "height_cm", group = "water_regime",
            engine = "grid", grid_n = 31)

## growth_functional()
# 1) Same interface as growth_fpca()
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
class(growth_functional(g, response = "height_cm", engine = "grid", grid_n = 41))

# 2) Linear smoothing and a smaller basis
growth_functional(g, response = "height_cm", engine = "grid",
                  smooth = "linear", nbasis = 8, grid_n = 31)

# 3) fdapace engine (requires the fdapace package)
\donttest{
if (requireNamespace("fdapace", quietly = TRUE)) {
  growth_functional(g, response = "height_cm", engine = "fdapace")
}
}

## print.agri_growth_fpca()
# 1) FPCA summary
b <- growth_example_data("bean_repeated")
g <- growth_data(b, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "water_regime")
fp <- growth_fpca(g, response = "height_cm", engine = "grid", grid_n = 31)
print(fp)

# 2) Structure
str(fp, max.level = 1)

# 3) Invisible return
identical(print(fp), fp)
}
