args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) normalizePath(args[[1L]], winslash = "/", mustWork = TRUE) else normalizePath(".", winslash = "/", mustWork = TRUE)

message("agriGrowthFlow 1.0.0 local validation helper")
message("Package root: ", root)

req <- c("devtools", "testthat", "rmarkdown", "knitr", "roxygen2")
missing <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Missing validation packages: ", paste(missing, collapse = ", "), ". Install them explicitly before validation.", call. = FALSE)
}

dcf <- read.dcf(file.path(root, "DESCRIPTION"))
stopifnot(dcf[1, "Package"] == "agriGrowthFlow")
stopifnot(dcf[1, "Version"] == "1.0.0")

message("[1/6] Loading source package")
devtools::load_all(root, quiet = TRUE)

message("[2/6] Running numerical known-truth controls")
stopifnot(isTRUE(all.equal(growth_agr(10, 16, 2, 5), 2)))
stopifnot(isTRUE(all.equal(growth_rgr(10, 16, 2, 5), (log(16) - log(10)) / 3)))
leaf_area <- 0.24
leaf_mass <- 6
plant_mass <- 30
stopifnot(isTRUE(all.equal(
  growth_lar(leaf_area, plant_mass),
  growth_sla(leaf_area, leaf_mass) * growth_lmr(leaf_mass, plant_mass)
)))

message("[3/6] Running consolidated-release smoke tests")
sun <- growth_example_data("sunflower_sigmoid")
w0 <- growth_workflow(sun, time = "day", response = "biomass_g", execute = FALSE, seed = 2001)
stopifnot(inherits(w0, "agri_growth_workflow"))
stopifnot(is.null(w0$core))
a0 <- growth_workflow_audit(w0)
stopifnot(!any(a0$status == "FAIL"))

w1 <- growth_workflow(
  sun,
  time = "day",
  response = "biomass_g",
  strategy = "parametric",
  models = c("logistic", "gompertz"),
  n_start = 3,
  seed = 2002
)
stopifnot(inherits(w1, "agri_growth_workflow"))
stopifnot(!is.null(w1$core))
stopifnot(is.data.frame(growth_table(w1, "traits")))

bundle <- tempfile("agf_bundle_")
growth_export(w1, bundle, format = "bundle")
needed <- c("object.rds", "workflow_audit.csv", "method_guide.csv", "report.md")
stopifnot(all(file.exists(file.path(bundle, needed))))
stopifnot(inherits(readRDS(file.path(bundle, "object.rds")), "agri_growth_workflow"))

message("[4/6] Running testthat suite")
devtools::test(root, reporter = "summary")

message("[5/6] Building vignettes")
devtools::build_vignettes(root)

if (identical(tolower(Sys.getenv("AGRIGROWTHFLOW_RUN_BAYES_TESTS", "false")), "true")) {
  message("[6/6] Bayesian gate requested")
  bayes_req <- c("brms", "posterior", "loo")
  bayes_missing <- bayes_req[!vapply(bayes_req, requireNamespace, logical(1), quietly = TRUE)]
  if (length(bayes_missing)) stop("Missing Bayesian packages: ", paste(bayes_missing, collapse = ", "), call. = FALSE)
  devtools::test(root, filter = "bayesian-growth", reporter = "summary")
} else {
  message("[6/6] Bayesian gate not requested. Set AGRIGROWTHFLOW_RUN_BAYES_TESTS=true to enable it.")
}

message("Source-level R validation helper completed.")
message("Next mandatory shell gates:")
message("  R CMD build agriGrowthFlow")
message("  R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz")
