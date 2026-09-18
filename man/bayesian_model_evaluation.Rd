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

## growth_loo()
# 1) Leave-one-out evaluation
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_loo(b)
}
}

# 2) Moment matching for problematic Pareto-k
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  growth_loo(b, moment_match = TRUE)
}
}

# 3) Structure of the result
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  str(growth_loo(b), max.level = 1)
}
}

## growth_model_average()
# 1) Model averaging by stacking
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  growth_model_average(b1, b2, ndraws = 50, seed = 2)
}
}

# 2) Pseudo-BMA weights
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  growth_model_average(b1, b2, method = "pseudobma", ndraws = 50, seed = 2)$weights
}
}

# 3) Averaged prediction from the ensemble
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  ma <- growth_model_average(b1, b2, type = "epred", ndraws = 50, seed = 2)
  class(ma)
}
}

## print.agri_growth_bayes_diagnostics()
# 1) Printed diagnostics
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  print(growth_bayes_diagnose(b))
}
}

# 2) Structure
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

# 3) Invisible return
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  bd <- growth_bayes_diagnose(b)
  identical(print(bd), bd)
}
}

## print.agri_growth_loo()
# 1) LOO summary
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  print(growth_loo(b))
}
}

# 2) Structure
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  str(growth_loo(b), max.level = 1)
}
}

# 3) Invisible return
\donttest{
if (requireNamespace("brms", quietly = TRUE) && requireNamespace("loo", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                    group_effects = "none", random = "none",
                    chains = 1, iter = 200, warmup = 100, cores = 1,
                    seed = 1, refresh = 0)
  l <- growth_loo(b)
  identical(print(l), l)
}
}

## print.agri_growth_model_average()
# 1) Model-averaging summary
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
  print(ma)
}
}

# 2) Structure
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
  str(ma, max.level = 1)
}
}

# 3) Invisible return
\donttest{
if (requireNamespace("brms", quietly = TRUE)) {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  b1 <- growth_bayes(d1, "logistic", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  b2 <- growth_bayes(d1, "gompertz", time = "day", response = "biomass_g",
                     group_effects = "none", random = "none",
                     chains = 1, iter = 200, warmup = 100, cores = 1,
                     seed = 1, refresh = 0)
  ma <- growth_model_average(b1, b2, ndraws = 50, seed = 2)
  identical(print(ma), ma)
}
}
}
