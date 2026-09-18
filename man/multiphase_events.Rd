\name{multiphase_events}
\alias{growth_multiphase}
\alias{growth_diphasic}
\alias{growth_stability}
\alias{growth_changepoint}
\title{Multiphase growth, stability points, and changepoints}
\usage{
growth_multiphase(x, time = NULL, response = NULL, n_phases = 2L,
  group = NULL, start = NULL, n_start = 20L, seed = NULL,
  aggregate = c("auto", "none", "mean"), control = list())

growth_diphasic(x, time = NULL, response = NULL, group = NULL,
  start = NULL, n_start = 20L, seed = NULL,
  aggregate = c("auto", "none", "mean"), control = list())

growth_stability(object, interval = NULL, n = 2001L)

growth_changepoint(data, time, response, min_segment = 3L,
  candidates = NULL)
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{time,response}{Time and response columns when required.}
\item{n_phases}{One to three ordered logistic phases.}
\item{group}{Optional column for separate descriptive trajectories.}
\item{start}{Optional internal transformed starting vector.}
\item{n_start}{Number of optimization starts.}
\item{seed}{Optional random seed.}
\item{aggregate}{Destructive-sampling aggregation rule.}
\item{control}{List passed to \code{stats::optim()}.}
\item{object}{A fitted growth object supported by the numerical derivative layer.}
\item{interval}{Optional time interval for numerical searches.}
\item{n}{Grid density.}
\item{data}{A data frame.}
\item{min_segment}{Minimum number of distinct times required on each side of a changepoint.}
\item{candidates}{Optional candidate changepoint times.}
}
\description{Fits sums of ordered logistic phases, locates fourth-derivative stability points on the complete fitted curve, and provides an exploratory continuous piecewise-linear changepoint search.}
\value{Structured fit or diagnostic objects, or data frames of critical points.}

\examples{

## growth_multiphase()
# 1) Two ordered logistic phases
d <- growth_example_data("coffee_diphasic")
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "treatment",
                 total_mass = "biomass_g")
mp <- growth_multiphase(g, n_phases = 2, n_start = 3, seed = 1)
mp$n_phases

# 2) One and three phases
growth_multiphase(g, n_phases = 1, n_start = 2, seed = 1)$n_phases
growth_multiphase(g, n_phases = 3, n_start = 2, seed = 1)$n_phases

# 3) One fit per treatment
growth_multiphase(g, n_phases = 2, group = "treatment", n_start = 2, seed = 1)

## growth_diphasic()
# 1) Shortcut for two phases
d <- growth_example_data("coffee_diphasic")
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", total_mass = "biomass_g")
dp <- growth_diphasic(g, n_start = 3, seed = 1)
dp$n_phases

# 2) Reproducible result with a fixed seed
a <- growth_diphasic(g, n_start = 2, seed = 7)
b <- growth_diphasic(g, n_start = 2, seed = 7)
identical(a$rss, b$rss)

# 3) Fitted components
growth_diphasic(g, n_start = 2, seed = 1)$components

## growth_stability()
# 1) Stability points of the summed trajectory
d <- growth_example_data("coffee_diphasic")
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", total_mass = "biomass_g")
mp <- growth_multiphase(g, n_phases = 2, n_start = 3, seed = 1)
growth_stability(mp)

# 2) Extended search interval
growth_stability(mp, interval = c(0, 150), n = 501)

# 3) Structure of the result
str(growth_stability(mp), max.level = 1)

## growth_changepoint()
# 1) Exploratory changepoint search
d <- growth_example_data("coffee_diphasic")
cp <- growth_changepoint(d, time = "day", response = "biomass_g")
cp$breakpoint

# 2) Explicit candidates
growth_changepoint(d, time = "day", response = "biomass_g",
                   candidates = c(30, 60, 90))$breakpoint

# 3) Larger minimum segment
growth_changepoint(d, time = "day", response = "biomass_g",
                   min_segment = 5)$candidates

## print.agri_growth_multiphase()
# 1) Multiphase fit summary
d <- growth_example_data("coffee_diphasic")
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", total_mass = "biomass_g")
mp <- growth_multiphase(g, n_phases = 2, n_start = 2, seed = 1)
print(mp)

# 2) Components
mp$components

# 3) Invisible return
identical(print(mp), mp)

## print.agri_growth_multiphase_collection()
# 1) Multiphase collection by group
d <- growth_example_data("coffee_diphasic")
g <- growth_data(d, time = "day", sampling = "repeated",
                 experimental_unit = "plant_id", treatment = "treatment",
                 total_mass = "biomass_g")
mc <- growth_multiphase(g, n_phases = 2, group = "treatment", n_start = 2, seed = 1)
print(mc)

# 2) Group names
names(mc$fits)

# 3) Invisible return
identical(print(mc), mc)

## print.agri_growth_changepoint()
# 1) Changepoint summary
d <- growth_example_data("coffee_diphasic")
cp <- growth_changepoint(d, time = "day", response = "biomass_g")
print(cp)

# 2) Slopes before and after
c(before = cp$slope_before, after = cp$slope_after)

# 3) Invisible return
identical(print(cp), cp)
}
