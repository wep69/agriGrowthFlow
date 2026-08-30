test_that("method guide is design-aware and transparent", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", treatment = "nitrogen",
                   total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
                   leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2")
  z <- growth_method_guide(g, objective = "rates")
  expect_s3_class(z, "agri_growth_method_guide")
  expect_true(all(c("method", "suitability", "priority", "backend", "backend_available", "rationale") %in% names(z)))
  expect_equal(z$method[[1]], "classical")
})

test_that("planning-only workflow freezes a contract without fitting", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", treatment = "nitrogen",
                   total_mass = "total_mass_g", leaf_area = "leaf_area_m2")
  w <- growth_workflow(g, objective = "trajectory", execute = FALSE, seed = 101)
  expect_s3_class(w, "agri_growth_workflow")
  expect_false(w$executed)
  expect_null(w$core)
  a <- growth_workflow_audit(w)
  expect_true(any(a$gate == "execution" & a$status == "INFO"))
  expect_true(any(grepl("Planning-only", w$notes, fixed = TRUE)))
})

test_that("parametric workflow preserves comparison and biological traits", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  w <- growth_workflow(d, time = "day", response = "biomass_g",
                       strategy = "parametric", models = c("logistic", "gompertz"),
                       n_start = 2, seed = 102)
  expect_s3_class(w, "agri_growth_workflow")
  expect_true(w$executed)
  expect_s3_class(w$core, "agri_growth_fit_set")
  expect_true(is.data.frame(w$comparison))
  expect_true(is.data.frame(w$traits))
  expect_true(all(c("model", "aicc") %in% names(w$comparison)))
})

test_that("standard tables expose stable release views", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  f <- growth_fit(d, "logistic", time = "day", response = "biomass_g")
  cf <- growth_table(f, component = "coefficients")
  expect_true(all(c("term", "estimate", "model") %in% names(cf)))

  w <- growth_workflow(d, time = "day", response = "biomass_g", execute = FALSE)
  expect_true(is.data.frame(growth_table(w, component = "audit")))
  expect_true(is.data.frame(growth_table(w, component = "guide")))
})

test_that("Markdown report records safeguards without inventing conclusions", {
  d <- growth_example_data("sunflower_sigmoid")
  w <- growth_workflow(d, time = "day", response = "biomass_g", execute = FALSE, seed = 7)
  txt <- growth_report(w)
  expect_true(is.character(txt))
  expect_true(any(grepl("Interpretation safeguards", txt, fixed = TRUE)))
  expect_true(any(grepl("Planning-only", txt, fixed = TRUE)))
  f <- tempfile(fileext = ".md")
  growth_report(w, file = f)
  expect_true(file.exists(f))
  expect_true(length(readLines(f, warn = FALSE)) > 10)
})

test_that("release export preserves RDS and review bundles", {
  d <- growth_example_data("sunflower_sigmoid")
  w <- growth_workflow(d, time = "day", response = "biomass_g", execute = FALSE, seed = 8)

  r <- tempfile(fileext = ".rds")
  growth_export(w, r, format = "rds")
  expect_true(file.exists(r))
  expect_s3_class(readRDS(r), "agri_growth_workflow")

  c <- tempfile(fileext = ".csv")
  growth_export(growth_workflow_audit(w), c, format = "csv")
  expect_true(file.exists(c))

  b <- tempfile(pattern = "agf_bundle_")
  growth_export(w, b, format = "bundle")
  expect_true(all(file.exists(file.path(b, c("object.rds", "workflow_audit.csv", "method_guide.csv", "report.md")))))
})
