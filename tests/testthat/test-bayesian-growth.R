test_that("Bayesian prior templates use transformed positive parameters", {
  d <- growth_example_data("sunflower_sigmoid")
  p <- growth_prior(d, "logistic", time = "day", response = "biomass_g")
  expect_s3_class(p, "agri_growth_prior")
  expect_true(all(c("log_asym", "mid", "log_scale") %in% p$nlpar))
  expect_true(any(grepl("asym = exp", p$transformation, fixed = TRUE)))
})

test_that("Richards prior adds positive shape predictor", {
  d <- growth_example_data("sunflower_sigmoid")
  p <- growth_prior(d, "richards", time = "day", response = "biomass_g")
  expect_true("log_shape" %in% p$nlpar)
  expect_true(any(grepl("shape = exp", p$transformation, fixed = TRUE)))
})

test_that("unsupported Bayesian families are refused explicitly", {
  d <- growth_example_data("wheat_expolinear")
  expect_error(growth_prior(d, "expolinear", time = "day", response = "biomass_g_m2"),
               "supports logistic, Gompertz, and Richards")
})

test_that("Bayesian prepared data preserve group and unit roles", {
  d <- growth_example_data("bean_repeated")
  z <- agriGrowthFlow:::.agf_prepare_bayes(d, time = "day", response = "height_cm",
                                           group = "water_regime", unit = "plant_id")
  expect_true(is.factor(z$agf_group))
  expect_true(is.factor(z$agf_unit))
  expect_equal(length(levels(z$agf_group)), 2)
  expect_equal(length(levels(z$agf_unit)), 32)
})

test_that("default Bayesian formula templates distinguish group and hierarchy", {
  d <- growth_example_data("bean_repeated")
  z <- agriGrowthFlow:::.agf_prepare_bayes(d, time = "day", response = "height_cm",
                                           group = "water_regime", unit = "plant_id")
  fs <- agriGrowthFlow:::.agf_bayes_default_nlpar_formulas("logistic", z, "auto", "auto")
  expect_true(grepl("agf_group", paste(deparse(fs$log_asym), collapse = " "), fixed = TRUE))
  expect_true(grepl("agf_unit", paste(deparse(fs$log_asym), collapse = " "), fixed = TRUE))
  expect_false(grepl("agf_unit", paste(deparse(fs$mid), collapse = " "), fixed = TRUE))
})

test_that("optional Bayesian smoke fit is available behind an explicit environment gate", {
  skip_if_not_installed("brms")
  skip_if(Sys.getenv("AGRIGROWTHFLOW_RUN_BAYES_TESTS") != "true", "Bayesian compilation smoke test is opt-in")
  d <- data.frame(day = seq(0, 60, by = 10))
  d$mass <- 100 / (1 + exp(-(d$day - 30) / 6))
  b <- growth_bayes(d, "logistic", time = "day", response = "mass",
                    chains = 2, iter = 400, warmup = 200, cores = 1,
                    seed = 7, refresh = 0)
  expect_s3_class(b, "agri_growth_bayes")
  dg <- growth_bayes_diagnose(b)
  expect_s3_class(dg, "agri_growth_bayes_diagnostics")
  tr <- growth_posterior_traits(b, ndraws = 50, seed = 2)
  expect_true(all(c("t50", "maximum_absolute_rate") %in% tr$trait))
})
