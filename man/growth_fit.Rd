\name{growth_fit}
\alias{growth_fit}
\alias{growth_multistart}
\alias{agri_growth_fit}
\alias{agri_growth_fit_set}
\alias{agri_growth_fit_collection}
\title{Fit parametric plant-growth models}
\usage{
growth_fit(x, model = "logistic", time = NULL, response = NULL, group = NULL,
  start = NULL, n_start = 1L, seed = NULL,
  engine = c("auto", "nls", "minpack.lm"),
  aggregate = c("auto", "none", "mean"), control = list())

growth_multistart(x, model = "logistic", time = NULL, response = NULL,
  group = NULL, start = NULL, n_start = 30L, seed = NULL,
  engine = c("auto", "nls", "minpack.lm"),
  aggregate = c("auto", "none", "mean"), control = list())
}
\arguments{
\item{x}{An \code{agri_growth_data} object or data frame.}
\item{model}{One or more built-in model names.}
\item{time,response}{Column names when \code{x} is a data frame.}
\item{group}{Optional grouping column for separate descriptive fits.}
\item{start}{Optional named public starting values for one model.}
\item{n_start}{Number of fitting starts.}
\item{seed}{Optional random seed for multistart generation.}
\item{engine}{Base \code{nls}, optional \code{minpack.lm}, or automatic engine selection.}
\item{aggregate}{Destructive-data aggregation rule.}
\item{control}{Optional optimizer-control list.}
}
\description{Fits bounded nonlinear plant-growth models. Serial destructive or repeated structures retain explicit warnings because ordinary nonlinear least squares does not represent within-unit longitudinal dependence.}
\value{A single fit, candidate fit set, or grouped fit collection.}

\examples{

## growth_fit()
# 1) A logistic fit
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
coef(f)

# 2) Several models in one call
fs <- growth_fit(d1, c("logistic", "gompertz"), time = "day", response = "biomass_g")
fs$models

# 3) One fit per group
fc <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
                 group = "cultivar")
fc$groups

## growth_multistart()
# 1) Several starting values and the best fit
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
fm <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
                        n_start = 10, seed = 1)
sum(fm$attempts$converged)

# 2) A fixed seed makes the result reproducible
a <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
                       n_start = 5, seed = 42)
b <- growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
                       n_start = 5, seed = 42)
identical(coef(a), coef(b))

# 3) An explicit starting point
growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
                  start = list(asym = 220, mid = 55, scale = 12), n_start = 3)

## coef.agri_growth_fit()
# 1) Named coefficients
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
coef(f)

# 2) Access by name
coef(f)[["asym"]]

# 3) Rounded vector
round(coef(f), 3)

## print.agri_growth_fit()
# 1) Fit summary
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
print(f)

# 2) Main components
c(n = f$n, rss = f$rss, sigma = f$sigma)

# 3) Invisible return
identical(print(f), f)

## print.agri_growth_fit_set()
# 1) A set of models
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
fs <- growth_fit(d1, c("logistic", "gompertz"), time = "day", response = "biomass_g")
print(fs)

# 2) Access one fit of the set
class(fs$fits[["logistic"]])

# 3) Invisible return
identical(print(fs), fs)

## print.agri_growth_fit_collection()
# 1) A collection by group
d <- growth_example_data("sunflower_sigmoid")
fc <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
                 group = "cultivar")
print(fc)

# 2) Groups and one specific fit
fc$groups
coef(fc$fits[[1]])

# 3) Invisible return
identical(print(fc), fc)
}
