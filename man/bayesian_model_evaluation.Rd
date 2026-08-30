\name{bayesian_model_evaluation}
\alias{growth_loo}
\alias{growth_model_average}
\title{LOO evaluation and predictive model weighting for Bayesian growth curves}
\description{
Pareto-smoothed leave-one-out evaluation and model weighting using stacking or pseudo-BMA. Candidate Bayesian models must have been fitted to identical prepared observations.
}
\usage{
growth_loo(object, moment_match = FALSE, ...)

growth_model_average(
  ...,
  method = c("stacking", "pseudobma"),
  BB = TRUE,
  type = c("weights", "epred", "predict"),
  newdata = NULL,
  re_formula = NA,
  ndraws = 1000L,
  probs = c(0.025, 0.975),
  seed = NULL,
  keep_draws = FALSE
)
}
\arguments{
  \item{object}{One \code{agri_growth_bayes}.}
  \item{moment_match}{Logical option forwarded to \code{loo::loo()}.}
  \item{...}{For \code{growth_loo()}, additional LOO arguments. For \code{growth_model_average()}, two or more Bayesian growth objects or one list containing them.}
  \item{method}{Stacking or pseudo-BMA weighting.}
  \item{BB}{With pseudo-BMA, use the Bayesian bootstrap to obtain pseudo-BMA+ weights.}
  \item{type}{Return weights only, or additionally combine posterior expected/predictive draws.}
  \item{newdata}{Standardized Bayesian prediction data. Defaults to the shared prepared observations.}
  \item{re_formula}{brms random-effect prediction specification.}
  \item{ndraws}{Number of model-mixture draws.}
  \item{probs}{Two prediction interval probabilities.}
  \item{seed}{Optional seed.}
  \item{keep_draws}{Retain mixture draws in the returned object.}
}
\details{
PSIS-LOO estimates pointwise out-of-sample predictive accuracy from posterior draws. Pareto-k diagnostics are retained because large importance ratios can make the approximation unreliable and can motivate moment matching, exact refitting, K-fold validation, or model revision.

Stacking estimates weights to maximize the leave-one-out predictive density of the combined predictive distribution. Pseudo-BMA+ uses a Bayesian bootstrap to reduce extreme weighting. These weights quantify predictive combination under the candidate set. They do not convert weakly identified or biologically implausible models into acceptable scientific explanations.

For \code{type = "epred"} or \code{"predict"}, the package forms a Monte Carlo mixture by drawing a candidate model according to its LOO weight and then drawing one model-specific posterior expected or posterior predictive trajectory. The resulting interval therefore propagates both within-model posterior uncertainty and the selected form of between-model uncertainty.
}
\value{
\code{growth_loo()} returns \code{agri_growth_loo}. \code{growth_model_average()} returns \code{agri_growth_model_average} with weights, LOO objects, and optional prediction summaries and mixture draws.
}
\examples{
d <- growth_example_data("sunflower_sigmoid")
growth_prior(d, "logistic", time = "day", response = "biomass_g")
growth_prior(d, "gompertz", time = "day", response = "biomass_g")
if (FALSE) growth_model_average(NULL, NULL)
}
