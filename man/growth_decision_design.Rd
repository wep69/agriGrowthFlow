\name{growth_decision_design}
\alias{growth_threshold}
\alias{growth_plateau_time}
\alias{growth_harvest_opt}
\alias{growth_schedule}
\alias{growth_design_sim}
\alias{growth_power}
\title{Biological thresholds, planning heuristics, harvest optimization, and power}
\usage{
growth_threshold(object, threshold, type = c("absolute", "fraction"),
  interval = NULL, direction = c("increasing", "decreasing"), n = 2001L)

growth_plateau_time(object, criterion = c("rate", "response"),
  rate_fraction = 0.05, response_fraction = 0.95,
  interval = NULL, n = 3001L)

growth_harvest_opt(object, price = 1, cost_per_time = 0,
  discount_rate = 0, harvest_cost = 0, interval = NULL, n = 2001L)

growth_schedule(object = NULL, time_range = NULL, n = 6L,
  method = c("rate_curvature", "equal"), grid_size = 2001L)

growth_design_sim(model, parameters, times, n_unit = 12L, sigma = 1,
  random_asym_sd = 0, treatment = NULL, treatment_multiplier = NULL,
  seed = NULL)

growth_power(effect, trait_sd, n_unit, alpha = 0.05, n_sim = 5000L,
  alternative = c("two.sided", "greater", "less"), seed = NULL)
}
\arguments{
\item{object}{A supported fitted growth object.}
\item{threshold}{Absolute response threshold or fraction of a finite upper level.}
\item{type}{Absolute or fractional threshold type.}
\item{interval}{Optional time interval for search or optimization.}
\item{direction}{Direction of threshold crossing.}
\item{n}{Grid density or number of planned times, according to function.}
\item{criterion}{Rate-based or response-based plateau definition.}
\item{rate_fraction}{Fraction of maximum growth rate defining practical plateau.}
\item{response_fraction}{Fraction of finite upper response defining practical plateau.}
\item{price,cost_per_time,discount_rate,harvest_cost}{User-supplied economic assumptions.}
\item{time_range}{Explicit planning interval.}
\item{method}{Observation-schedule method.}
\item{grid_size}{Internal planning grid density.}
\item{model}{Built-in parametric model name.}
\item{parameters}{Named public model parameters.}
\item{times}{Observation times for simulation.}
\item{n_unit}{Persistent units per simulation or per group, according to function.}
\item{sigma}{Residual standard deviation.}
\item{random_asym_sd}{Log-scale between-unit variation in the upper-level parameter.}
\item{treatment}{Optional treatment labels.}
\item{treatment_multiplier}{Optional named treatment multipliers for the upper-level parameter.}
\item{seed}{Optional random seed.}
\item{effect}{Expected treatment-minus-control difference in a derived trait.}
\item{trait_sd}{Between-unit standard deviation of that derived trait.}
\item{alpha}{Type-I error rate.}
\item{n_sim}{Number of Monte Carlo replicates.}
\item{alternative}{Alternative hypothesis for the simulated two-sample test.}
}
\description{Extracts model-conditioned biological decision points, proposes transparent observation schedules, simulates growth-design data, and approximates power for derived trait contrasts. Harvest optimization is conditional on the supplied model and economic assumptions. The schedule is a heuristic, not an optimal-design proof.}
\value{Data frames or structured planning and decision objects.}

\examples{

## growth_threshold()
# 1) Threshold as a fraction of the asymptote
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_threshold(f, 0.5, type = "fraction")

# 2) Absolute threshold
growth_threshold(f, 100, type = "absolute")

# 3) Without a crossing the result has zero rows
growth_threshold(f, 100, type = "absolute", direction = "decreasing")
nrow(growth_threshold(f, 10000, type = "absolute"))

## growth_plateau_time()
# 1) Rate criterion
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_plateau_time(f)

# 2) Response criterion
growth_plateau_time(f, criterion = "response", response_fraction = 0.9)

# 3) Explicit grid and rate fraction
growth_plateau_time(f, criterion = "rate", rate_fraction = 0.1,
                    interval = c(0, 120), n = 501)

## growth_harvest_opt()
# 1) Optimum without costs
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
ho <- growth_harvest_opt(f)
ho$optimum_time

# 2) Optimum with economic assumptions
growth_harvest_opt(f, price = 2, cost_per_time = 0.1, discount_rate = 0.02,
                   harvest_cost = 5, interval = c(0, 120), n = 501)

# 3) Assumptions stored in the object
ho$assumptions

## growth_schedule()
# 1) Schedule driven by rate curvature
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
growth_schedule(f, n = 6)

# 2) Equal spacing
growth_schedule(f, time_range = c(0, 100), n = 5, method = "equal")

# 3) Without a fitted object
growth_schedule(time_range = c(0, 100), n = 5)

## growth_design_sim()
# 1) Simulated trial with a single logistic curve
ds <- growth_design_sim(model = "logistic",
                        parameters = list(asym = 100, mid = 40, scale = 10),
                        times = c(10, 20, 30, 40, 50), n_unit = 6, sigma = 3,
                        seed = 1)
head(ds)

# 2) Two treatments with a multiplicative effect
ds2 <- growth_design_sim(model = "logistic",
                         parameters = list(asym = 100, mid = 40, scale = 10),
                         times = c(10, 20, 30, 40, 50), n_unit = 6, sigma = 3,
                         treatment = rep(c("A", "B"), each = 3),
                         treatment_multiplier = c(A = 1, B = 1.3), seed = 1)
unique(ds2$treatment)

# 3) Between-unit heterogeneity
ds3 <- growth_design_sim(model = "logistic",
                         parameters = list(asym = 100, mid = 40, scale = 10),
                         times = c(10, 20, 30, 40, 50), n_unit = 8, sigma = 2,
                         random_asym_sd = 0.2, seed = 1)
tapply(ds3$expected[ds3$time == 50], ds3$unit[ds3$time == 50], unique)

## growth_power()
# 1) Power for one effect and sample size
growth_power(effect = 0.5, trait_sd = 1, n_unit = 10, n_sim = 500, seed = 1)

# 2) One-sided alternative
growth_power(effect = 0.5, trait_sd = 1, n_unit = 10, n_sim = 500,
             alternative = "greater", seed = 1)$power

# 3) A grid of sample sizes
sapply(c(6, 10, 16), function(n)
  growth_power(0.5, 1, n_unit = n, n_sim = 500, seed = 1)$power)

## print.agri_growth_harvest()
# 1) Harvest optimum summary
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
print(growth_harvest_opt(f))

# 2) Net-value curve
head(growth_harvest_opt(f)$curve)

# 3) Invisible return
ho <- growth_harvest_opt(f)
identical(print(ho), ho)

## print.agri_growth_power()
# 1) Power calculation summary
pw <- growth_power(effect = 0.5, trait_sd = 1, n_unit = 10, n_sim = 500, seed = 1)
print(pw)

# 2) Structure
str(pw, max.level = 1)

# 3) Invisible return
identical(print(pw), pw)
}
