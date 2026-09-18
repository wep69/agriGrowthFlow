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

\examples{

## growth_design()
# 1) Automatic resolution from the sampling mechanism
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", treatment = "nitrogen",
                 block = "block", total_mass = "total_mass_g")
growth_design(g)

# 2) Design declared explicitly
des <- growth_design(g, design = "rcbd", treatment = "nitrogen", block = "block")
des$design

# 3) Harvest unit and metadata
growth_design(g, design = "serial_destructive", treatment = "nitrogen",
              harvest_unit = "harvest_unit", metadata = list(trial = "E1"))

## growth_validate()
# 1) Well-behaved data
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
growth_validate(g)

# 2) Negative mass raises an error-level issue
d2 <- d; d2$total_mass_g[1] <- -1
g2 <- growth_data(d2, time = "day", sampling = "destructive",
                  experimental_unit = "plot_id", total_mass = "total_mass_g")
growth_validate(g2)$issues

# 3) strict stops on error-level issues
try(growth_validate(g2, strict = TRUE))

## growth_plan()
# 1) Recommendations for complete data
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
length(growth_plan(g)$recommendations)

# 2) An extra recommendation when time support is short
g2 <- growth_data(d[d$day \%in\% c(14, 28), ], time = "day",
                  sampling = "destructive", experimental_unit = "plot_id",
                  total_mass = "total_mass_g")
setdiff(growth_plan(g2)$recommendations, growth_plan(g)$recommendations)

# 3) The plan also accepts a design object
growth_plan(growth_design(g, treatment = "nitrogen", block = "block"))

## print.agri_growth_design()
# 1) Automatically resolved design
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", treatment = "nitrogen",
                 block = "block", total_mass = "total_mass_g")
print(growth_design(g))

# 2) Declared design
print(growth_design(g, design = "rcbd", treatment = "nitrogen", block = "block"))

# 3) Invisible return
dz <- growth_design(g)
identical(print(dz), dz)

## print.agri_growth_validation()
# 1) Validation without issues
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
print(growth_validate(g))

# 2) Validation with listed issues
d2 <- d; d2$total_mass_g[1] <- -1
g2 <- growth_data(d2, time = "day", sampling = "destructive",
                  experimental_unit = "plot_id", total_mass = "total_mass_g")
print(growth_validate(g2))

# 3) Invisible return
v <- growth_validate(g)
identical(print(v), v)

## print.agri_growth_plan()
# 1) Plan with recommendations
d <- growth_example_data("maize_destructive")
g <- growth_data(d, time = "day", sampling = "destructive",
                 experimental_unit = "plot_id", total_mass = "total_mass_g")
print(growth_plan(g))

# 2) Invisible return
p <- growth_plan(g)
identical(print(p), p)

# 3) Structure
str(growth_plan(g), max.level = 1)
}
