\name{consolidated_release}
\alias{growth_method_guide}
\alias{growth_workflow}
\alias{growth_workflow_audit}
\alias{growth_table}
\alias{growth_report}
\alias{growth_export}
\title{Consolidated Release Workflow, Audit, Reporting, and Export}
\usage{
growth_method_guide(
  x,
  time = NULL,
  response = NULL,
  unit = NULL,
  group = NULL,
  objective = c("trajectory", "rates", "treatment_comparison", "uncertainty", "phases", "decision"),
  include_optional = TRUE
)

growth_workflow(
  x,
  time = NULL,
  response = NULL,
  unit = NULL,
  group = NULL,
  objective = c("trajectory", "rates", "treatment_comparison", "uncertainty", "phases", "decision"),
  strategy = c("auto", "classical", "parametric", "mixed", "smooth", "multiphase"),
  models = c("logistic", "gompertz", "richards"),
  n_start = 10L,
  smooth_method = c("smooth_spline", "loess", "gam", "scam"),
  mixed_degree = 2L,
  uncertainty = c("none", "auto", "bootstrap", "bayesian"),
  bootstrap_R = 999L,
  uncertainty_args = list(),
  seed = NULL,
  execute = TRUE,
  ...
)

growth_workflow_audit(object)

growth_table(
  object,
  component = c("auto", "audit", "traits", "comparison", "diagnostics", "intervals", "coefficients", "guide")
)

growth_report(
  object,
  file = NULL,
  title = "agriGrowthFlow analysis report",
  digits = 4L
)

growth_export(
  object,
  path,
  format = c("rds", "csv", "bundle"),
  overwrite = FALSE
)
}
\arguments{
  \item{x}{An \code{agri_growth_data} object or a data frame.}
  \item{time}{Optional name of the time column. Roles are inherited from \code{growth_data()} when possible.}
  \item{response}{Optional name of the growth-response column. For a declared growth object, total mass is used by default when available.}
  \item{unit}{Optional persistent experimental-unit identifier.}
  \item{group}{Optional treatment or grouping column.}
  \item{objective}{Scientific objective used for transparent method guidance.}
  \item{include_optional}{If \code{FALSE}, omit methods whose optional backend is unavailable.}
  \item{strategy}{Core workflow strategy. \code{"auto"} uses explicit design/objective priority rules and records the decision.}
  \item{models}{Candidate parametric growth models for the parametric strategy.}
  \item{n_start}{Number of multistart attempts for parametric or multiphase optimization.}
  \item{smooth_method}{Flexible smoother used by the smooth strategy.}
  \item{mixed_degree}{Fixed polynomial degree used by \code{growth_mixed()}.}
  \item{uncertainty}{Optional uncertainty layer. Automatic uncertainty is conservative and is not attached across grouped fit collections.}
  \item{bootstrap_R}{Number of bootstrap replicates when the bootstrap layer is requested.}
  \item{uncertainty_args}{Named list passed only to the selected uncertainty engine.}
  \item{seed}{Optional reproducibility seed.}
  \item{execute}{If \code{FALSE}, freeze the analysis contract without fitting a core model.}
  \item{...}{Additional arguments forwarded only to the selected core strategy.}
  \item{object}{A supported agriGrowthFlow object. Workflow audit and reporting require an \code{agri_growth_workflow}.}
  \item{component}{Requested standardized table view.}
  \item{file}{Optional Markdown output path.}
  \item{title}{Report title.}
  \item{digits}{Number of decimal places displayed in Markdown tables.}
  \item{path}{Output file for RDS/CSV or output directory for a bundle.}
  \item{format}{Export format. RDS preserves the complete nested object.}
  \item{overwrite}{Whether an existing output target may be replaced.}
}
\value{
\code{growth_method_guide()} returns an \code{agri_growth_method_guide} data frame.\cr
\code{growth_workflow()} returns an \code{agri_growth_workflow}.\cr
\code{growth_workflow_audit()} and \code{growth_table()} return data frames.\cr
\code{growth_report()} returns Markdown text and optionally writes it to disk.\cr
\code{growth_export()} invisibly returns the normalized output path.
}
\description{
These functions provide the stable 1.0.0 orchestration layer over the specialist
plant-growth methods developed in earlier package modules. They make the analysis
contract, method-guidance logic, diagnostics, uncertainty choice, reporting, and
export explicit while preserving the declared sampling structure and persistent
experimental unit.
}
\details{
Automatic method guidance is a navigation aid, not proof that one method is
scientifically correct. The consolidated workflow does not select a scientific
conclusion from a single p-value, R-squared, AIC, or AICc value. Candidate model
comparison is retained only when models use identical prepared observations.
Planning-only mode allows the analysis contract to be reviewed before model
fitting. RDS is the preferred complete archival format because flat files cannot
preserve nested fitted-model objects.
}
\examples{
\dontrun{
d <- growth_example_data("sunflower_sigmoid")
plan <- growth_workflow(d, time = "day", response = "biomass_g", execute = FALSE)
growth_workflow_audit(plan)

fit <- growth_workflow(
  d, time = "day", response = "biomass_g",
  strategy = "parametric", models = c("logistic", "gompertz"),
  n_start = 3, seed = 1
)
growth_table(fit, "traits")
growth_report(fit)

growth_export(fit, tempfile(pattern = "agf_bundle_"), format = "bundle")
}
}
