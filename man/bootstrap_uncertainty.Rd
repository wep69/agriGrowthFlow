\name{bootstrap_uncertainty}
\alias{growth_boot}
\alias{growth_boot_ci}
\alias{growth_boot_traits}
\alias{growth_selection_stability}
\title{Design-aware bootstrap uncertainty for plant growth curves}
\description{
Bootstrap resampling for fitted parametric growth curves, confidence intervals for model coefficients and derived biological traits, and bootstrap assessment of candidate-model selection stability. Resampling schemes are explicit about the persistent experimental unit.
}
\usage{
growth_boot(
  object,
  R = 999L,
  method = c("auto", "case", "cluster", "residual", "parametric", "wild", "cluster_wild"),
  seed = NULL,
  n_start = 1L,
  engine = NULL,
  wild_weights = c("rademacher", "mammen"),
  control = list(),
  keep_fits = FALSE
)

growth_boot_ci(
  object,
  source = c("coefficients", "traits"),
  parm = NULL,
  conf = 0.95,
  type = c("percentile", "basic", "normal")
)

growth_boot_traits(
  object,
  traits = NULL,
  conf = 0.95,
  type = c("percentile", "basic", "normal")
)

growth_selection_stability(
  x,
  models,
  time = NULL,
  response = NULL,
  R = 199L,
  method = c("auto", "case", "cluster"),
  seed = NULL,
  n_start = 1L,
  engine = c("auto", "nls", "minpack.lm"),
  aggregate = c("auto", "none", "mean")
)
}
\arguments{
  \item{object}{For \code{growth_boot()}, one \code{agri_growth_fit}. For interval functions, an \code{agri_growth_boot}.}
  \item{R}{Number of bootstrap replicates. At least 20.}
  \item{method}{Resampling method. \code{"auto"} chooses cluster bootstrap when repeated persistent-unit trajectories are retained and case resampling otherwise.}
  \item{seed}{Optional reproducibility seed.}
  \item{n_start}{Number of nonlinear starting values used in each refit.}
  \item{engine}{Optional nonlinear refitting engine.}
  \item{wild_weights}{Rademacher or Mammen multipliers for wild bootstrap.}
  \item{control}{Optional optimizer control list.}
  \item{keep_fits}{Whether successful bootstrap fitted objects should be retained.}
  \item{source}{Coefficient or derived-trait bootstrap distribution.}
  \item{parm}{Names of coefficients or traits to summarize.}
  \item{conf}{Confidence level.}
  \item{type}{Percentile, basic, or normal bootstrap interval.}
  \item{traits}{Optional biological trait names.}
  \item{x}{Growth data object or data frame for selection stability.}
  \item{models}{Two or more candidate parametric growth models.}
  \item{time,response}{Column names when \code{x} is a plain data frame.}
  \item{aggregate}{Destructive-sampling aggregation rule.}
}
\details{
Cluster resampling samples entire persistent experimental-unit trajectories and therefore preserves the observed within-unit time pattern. Case resampling treats rows as resampling units. Residual and parametric bootstrap condition on the fitted curve. Wild bootstrap allows residual magnitude to vary while perturbing signs or Mammen multipliers. Cluster-wild bootstrap assigns one multiplier per persistent experimental unit.

The package does not present row-wise residual, parametric, or wild resampling as a substitute for a longitudinal covariance model. If serial dependence is scientifically important, the resampling scheme and inferential model should reflect that dependence explicitly.

\code{growth_selection_stability()} resamples observed cases or persistent units before fitting every candidate model to the same bootstrap sample. It then records the AICc winner when finite, otherwise the AIC winner. The result is a sensitivity analysis for model selection rather than evidence that the most frequent winner is a true biological law.
}
\value{
\code{growth_boot()} returns an \code{agri_growth_boot}. Interval helpers return data frames. \code{growth_selection_stability()} returns an \code{agri_growth_selection_stability} containing replicate records, model metrics, and winner frequencies.
}
\examples{
d <- growth_example_data("sunflower_sigmoid")
d <- subset(d, cultivar == unique(d$cultivar)[1])
f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
b <- growth_boot(f, R = 25, seed = 123)
growth_boot_ci(b, source = "coefficients")
growth_boot_traits(b, traits = c("t50", "maximum_absolute_rate"))

s <- growth_selection_stability(
  d, c("logistic", "gompertz"), time = "day", response = "biomass_g",
  R = 20, seed = 1
)
s$frequencies
}
