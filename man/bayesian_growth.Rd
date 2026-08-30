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
Positive growth parameters are modeled through log-transformed nonlinear predictors. For example, \code{asym = exp(log_asym)} and \code{scale = exp(log_scale)}. This keeps these quantities positive without a hard truncation boundary in the Stan parameter space. The Richards shape is treated similarly.

The default prior table is scaled to the observed time and response range and should be treated as a starting template. A scientific analysis should inspect prior predictive behavior and replace weakly informative defaults with biologically justified priors when prior information is available.

When treatment groups are present, \code{group_effects = "auto"} enters the group factor in every nonlinear parameter. When repeated persistent units are present, \code{random = "auto"} adds a unit-level random effect to the transformed asymptote only. More complex random structures can be requested explicitly, but model identifiability, divergences, R-hat, effective sample size and posterior predictive behavior must be checked.

Version 0.4.0 intentionally restricts the Bayesian wrapper to logistic, Gompertz and Richards models. The remaining frequentist model families include domain constraints or piecewise behavior that require separate validated Stan parameterizations before they should be exposed through this interface.
}
\value{
\code{growth_prior()} returns an \code{agri_growth_prior}. \code{growth_bayes()} and \code{growth_prior_predict()} return \code{agri_growth_bayes} objects containing the underlying \code{brmsfit}. \code{growth_pp_check()} returns the brms/bayesplot check. \code{growth_bayes_diagnose()} returns an MCMC diagnostic object. \code{growth_posterior_traits()} returns a long posterior trait summary.
}
\examples{
d <- growth_example_data("sunflower_sigmoid")
p <- growth_prior(d, "logistic", time = "day", response = "biomass_g")
p

if (requireNamespace("brms", quietly = TRUE)) {
  # Bayesian fitting compiles and samples a Stan model and is not run here.
  # b <- growth_bayes(d, "logistic", time = "day", response = "biomass_g")
}
}
