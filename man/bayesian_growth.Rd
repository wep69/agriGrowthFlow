\name{bayesian_growth}
\alias{growth_prior}
\alias{growth_bayes}
\alias{growth_prior_predict}
\alias{growth_pp_check}
\alias{growth_bayes_diagnose}
\alias{growth_posterior_traits}
\title{Bayesian nonlinear and hierarchical plant-growth analysis}
\description{
Construct data-scaled prior templates, fit Bayesian logistic, Gompertz, or Richards growth curves with optional treatment and persistent-unit effects, inspect prior or posterior predictive behavior, diagnose MCMC sampling, and propagate posterior uncertainty to biologically interpretable growth traits.
}
\usage{
growth_prior(
  x = NULL,
  model = "logistic",
  time = NULL,
  response = NULL,
  group = NULL,
  unit = NULL,
  aggregate = c("auto", "none", "mean")
)

growth_bayes(
  x,
  model = "logistic",
  time = NULL,
  response = NULL,
  group = NULL,
  unit = NULL,
  group_effects = c("auto", "none", "all"),
  random = c("auto", "none", "asym", "timing", "all"),
  nlpar_formulas = NULL,
  prior = NULL,
  family = stats::gaussian(),
  chains = 4L,
  iter = 2000L,
  warmup = floor(iter / 2),
  cores = getOption("mc.cores", 1L),
  backend = c("rstan", "cmdstanr"),
  seed = NULL,
  sample_prior = c("yes", "no", "only"),
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  aggregate = c("auto", "none", "mean"),
  refresh = 0,
  ...
)

growth_prior_predict(
  x,
  model = "logistic",
  time = NULL,
  response = NULL,
  group = NULL,
  unit = NULL,
  group_effects = c("auto", "none", "all"),
  random = c("auto", "none", "asym", "timing", "all"),
  nlpar_formulas = NULL,
  prior = NULL,
  family = stats::gaussian(),
  chains = 4L,
  iter = 1000L,
  warmup = floor(iter / 2),
  cores = getOption("mc.cores", 1L),
  backend = c("rstan", "cmdstanr"),
  seed = NULL,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  aggregate = c("auto", "none", "mean"),
  refresh = 0,
  ...
)

growth_pp_check(object, type = "dens_overlay", ndraws = 50L, ...)

growth_bayes_diagnose(object, rhat_threshold = 1.01, min_ess = 400)

growth_posterior_traits(
  object,
  group = NULL,
  unit = NULL,
  re_formula = NA,
  ndraws = NULL,
  probs = c(0.025, 0.975),
  grid_n = 201L,
  seed = NULL
)
}
\arguments{
  \item{x}{Growth data object, data frame, or for \code{growth_prior()} optionally a fitted parametric curve.}
  \item{model}{Bayesian model family. Version 0.4.0 supports logistic, Gompertz, and Richards parameterizations.}
  \item{time,response}{Column names for plain data frames.}
  \item{group}{Optional treatment/group column. The declared treatment role is used automatically for \code{agri_growth_data}.}
  \item{unit}{Optional persistent-unit column for plain data frames.}
  \item{aggregate}{Destructive-data aggregation rule.}
  \item{group_effects}{Whether group effects enter every nonlinear parameter predictor.}
  \item{random}{Template for persistent-unit random effects.}
  \item{nlpar_formulas}{Optional named formulas overriding default nonlinear-parameter predictors.}
  \item{prior}{Package prior object, \code{brmsprior}, or \code{NULL}.}
  \item{family}{Response family passed to \code{brms::brm()}.}
  \item{chains,iter,warmup,cores}{MCMC controls.}
  \item{backend}{Stan backend used by brms.}
  \item{seed}{Optional random seed.}
  \item{sample_prior}{Whether prior draws are omitted, retained with posterior sampling, or sampled without conditioning on the response.}
  \item{control}{Stan sampler controls.}
  \item{refresh}{brms progress refresh frequency.}
  \item{...}{Additional arguments passed to brms functions.}
  \item{object}{An \code{agri_growth_bayes}.}
  \item{type}{Posterior predictive-check plot type.}
  \item{ndraws}{Number of draws to use or display.}
  \item{rhat_threshold}{R-hat flagging threshold.}
  \item{min_ess}{Simple minimum effective sample size flag.}
  \item{re_formula}{brms random-effect prediction specification. \code{NA} gives population-level predictions.}
  \item{probs}{Two posterior interval probabilities.}
  \item{grid_n}{Grid size for AUC over observed support.}
}
\details{
Positive growth parameters are modeled through log-transformed nonlinear predictors. For example, \code{asym = exp(logAsym)} and \code{scale = exp(logScale)}. This keeps these quantities positive without a hard truncation boundary in the Stan parameter space. The Richards shape is treated similarly.

The default prior table is scaled to the observed time and response range and should be treated as a starting template. A scientific analysis should inspect prior predictive behavior and replace weakly informative defaults with biologically justified priors when prior information is available.

When treatment groups are present, \code{group_effects = "auto"} enters the group factor in every nonlinear parameter. When repeated persistent units are present, \code{random = "auto"} adds a unit-level random effect to the transformed asymptote only. More complex random structures can be requested explicitly, but model identifiability, divergences, R-hat, effective sample size and posterior predictive behavior must be checked.

Version 0.4.0 intentionally restricts the Bayesian wrapper to logistic, Gompertz and Richards models. The remaining frequentist model families include domain constraints or piecewise behavior that require separate validated Stan parameterizations before they should be exposed through this interface.
}
\value{
\code{growth_prior()} returns an \code{agri_growth_prior}. \code{growth_bayes()} and \code{growth_prior_predict()} return \code{agri_growth_bayes} objects containing the underlying \code{brmsfit}. \code{growth_pp_check()} returns the brms/bayesplot check. \code{growth_bayes_diagnose()} returns an MCMC diagnostic object. \code{growth_posterior_traits()} returns a long posterior trait summary.
}
\examples{

## growth_prior()
# 1) Logistic priors
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
growth_prior(d1, "logistic", time = "day", response = "biomass_g")

# 2) Another model
growth_prior(d1, "gompertz", time = "day", response = "biomass_g")

# 3) A model with a shape parameter
growth_prior(d1, "richards", time = "day", response = "biomass_g")

## growth_bayes()
# 1) Bayesian logistic fit (requires brms and a Stan backend)
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  class(b)
}
}

# 2) Without group effects and without random effects
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
               group_effects = "none", random = "none",
               chains = 1, iter = 200, warmup = 100, cores = 1,
               seed = 1, refresh = 0)$random
}
}

# 3) Prior-only sampling, useful to check the assumptions
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
               sample_prior = "only", chains = 1, iter = 200, warmup = 100,
               cores = 1, seed = 1, refresh = 0)$prior_only
}
}

## growth_prior_predict()
# 1) Prior predictive simulation
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  pp <- growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
                             chains = 1, iter = 200, warmup = 100, cores = 1,
                             seed = 1, refresh = 0)
  class(pp)
}
}

# 2) Without group effects
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
                       group_effects = "none", random = "none",
                       chains = 1, iter = 200, warmup = 100, cores = 1,
                       seed = 1, refresh = 0)$has_group
}
}

# 3) Structure of the result
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  pp <- growth_prior_predict(d1, "logistic", time = "day", response = "biomass_g",
                             group_effects = "none", random = "none",
                             chains = 1, iter = 200, warmup = 100, cores = 1,
                             seed = 1, refresh = 0)
  str(pp, max.level = 1)
}
}

## growth_pp_check()
# 1) Posterior predictive check
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_pp_check(b, type = "dens_overlay", ndraws = 10)
}
}

# 2) Another plot type
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_pp_check(b, type = "hist", ndraws = 10)
}
}

# 3) The output is a ggplot object
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  class(growth_pp_check(b, ndraws = 5))[1]
}
}

## growth_bayes_diagnose()
# 1) MCMC diagnostics
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_bayes_diagnose(b)
}
}

# 2) Stricter thresholds
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_bayes_diagnose(b, rhat_threshold = 1.001, min_ess = 1000)
}
}

# 3) Structure of the diagnostics
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  str(growth_bayes_diagnose(b), max.level = 1)
}
}

## growth_posterior_traits()
# 1) Posterior traits with intervals
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_posterior_traits(b, grid_n = 51)
}
}

# 2) Different central probabilities
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_posterior_traits(b, probs = c(0.1, 0.5, 0.9), grid_n = 51)
}
}

# 3) Structure of the result
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  str(growth_posterior_traits(b, grid_n = 31), max.level = 1)
}
}

## print.agri_growth_prior()
# 1) Prior table
d <- growth_example_data("sunflower_sigmoid")
d1 <- subset(d, cultivar == unique(d$cultivar)[1])
pr <- growth_prior(d1, "logistic", time = "day", response = "biomass_g")
print(pr)

# 2) Subset of rows
pr[pr$role == "intercept", c("nlpar", "prior")]

# 3) Invisible return
identical(print(pr), pr)

## print.agri_growth_bayes()
# 1) Bayesian fit summary
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  print(b)
}
}

# 2) Formula actually fitted
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  b$formula
}
}

# 3) Object structure
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  str(b, max.level = 1)
}
}
}
