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
