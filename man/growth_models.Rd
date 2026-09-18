\name{growth_models}
\alias{growth_models}
\alias{growth_start}
\alias{agri_growth_start}
\title{Inspect parametric growth models and starting values}
\usage{
growth_models()

growth_start(x, model, time = NULL, response = NULL, group = NULL,
  aggregate = c("auto", "none", "mean"))
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{model}{Built-in growth-model name.}
\item{time,response}{Column names when \code{x} is a data frame.}
\item{group}{Optional grouping column.}
\item{aggregate}{Rule used to aggregate destructive sampling replicates.}
}
\description{Lists the built-in 0.2.0 parametric equations and exposes deterministic automatic starting values plus hard bounds before nonlinear optimization.}
\value{\code{growth_models()} returns a data frame. \code{growth_start()} returns an object of class \code{agri_growth_start}.}

\examples{

## growth_models()
# 1) The complete catalogue
growth_models()

# 2) Models with a finite upper level
subset(growth_models(), finite_upper_level)

# 3) Public parameters of one model
growth_models()[growth_models()$model == "richards", "public_parameters"]

## growth_start()
# 1) Automatic starting values for the logistic model
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
growth_start(d1, "logistic", time = "day", response = "biomass_g")

# 2) Another model
growth_start(d1, "gompertz", time = "day", response = "biomass_g")$start

# 3) A model with four parameters
growth_start(d1, "richards", time = "day", response = "biomass_g")$start

## print.agri_growth_start()
# 1) Summary of the starting values
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
st <- growth_start(d1, "logistic", time = "day", response = "biomass_g")
print(st)

# 2) Public bounds
st$lower; st$upper

# 3) Invisible return
identical(print(st), st)
}
