\name{growth_traits}
\alias{growth_traits}
\alias{growth_inflection}
\alias{growth_maxrate}
\alias{growth_time_to}
\title{Extract biologically interpretable traits from growth curves}
\usage{
growth_traits(object)

growth_inflection(object)

growth_maxrate(object)

growth_time_to(object, fraction = NULL, target = NULL)
}
\arguments{
\item{object}{A parametric growth fit, candidate fit set, or grouped fit collection.}
\item{fraction}{Optional fractions of a finite upper level.}
\item{target}{Optional absolute response targets.}
}
\description{Translates model-specific coefficients into common growth landmarks including inflection, maximum absolute rate, t10, t50, t90, and area under the fitted trajectory over observed time support.}
\value{A data frame.}

\examples{

## growth_traits()
# 1) Traits of the fit
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_traits(f)[, c("asymptote", "inflection_time", "maximum_absolute_rate")]

# 2) Times at fractions of the asymptote
growth_traits(f)[, c("t10", "t50", "t90")]

# 3) Traits by group
fc <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
                 group = "cultivar")
growth_traits(fc)[, c("model", "asymptote", "group")]

## growth_inflection()
# 1) Inflection point
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_inflection(f)

# 2) Isolated values
growth_inflection(f)$inflection_time

# 3) It coincides with the maximum-rate time for the logistic model
isTRUE(all.equal(growth_inflection(f)$inflection_time,
                 growth_maxrate(f)$time_maximum_rate))

## growth_maxrate()
# 1) Maximum absolute rate
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_maxrate(f)

# 2) Isolated values
growth_maxrate(f)$maximum_absolute_rate

# 3) Another model has another time of maximum rate
fg <- growth_fit(d1, "gompertz", time = "day", response = "biomass_g")
c(logistic = growth_maxrate(f)$time_maximum_rate,
  gompertz = growth_maxrate(fg)$time_maximum_rate)

## growth_time_to()
# 1) Time to a fraction of the asymptote
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_time_to(f, fraction = 0.5)

# 2) Time to an absolute target
growth_time_to(f, target = 150)

# 3) Supplying both routes at once is refused
try(growth_time_to(f, fraction = 0.5, target = 150))
}
