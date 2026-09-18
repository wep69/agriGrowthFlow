test_that("unknown growth model names raise the documented error", {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  expect_error(growth_fit(d1, "monomolecular", time = "day", response = "biomass_g"),
               "Unknown growth model")
  expect_error(growth_start(d1, "brody", time = "day", response = "biomass_g"),
               "Unknown growth model")
  expect_error(growth_design_sim(model = "brody",
                                 parameters = list(asym = 100, mid = 40, scale = 10),
                                 times = c(10, 20, 30)),
               "Unknown growth model")
})

test_that("growth_threshold returns an empty table when no crossing exists", {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  f <- growth_fit(d1, "logistic", time = "day", response = "biomass_g")
  out <- growth_threshold(f, 100, type = "absolute", direction = "decreasing")
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0L)
  expect_equal(nrow(growth_threshold(f, 10000, type = "absolute")), 0L)
  ok <- growth_threshold(f, 100, type = "absolute")
  expect_equal(nrow(ok), 1L)
})

test_that("growth_design resolves auto and records the request", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", treatment = "nitrogen",
                   block = "block", total_mass = "total_mass_g")
  dz <- growth_design(g)
  expect_identical(dz$design_requested, "auto")
  expect_identical(dz$design, "serial_destructive")
  expect_identical(growth_design(g, design = "rcbd", block = "block")$design, "rcbd")
  b <- growth_example_data("bean_repeated")
  gb <- growth_data(b, time = "day", sampling = "repeated",
                    experimental_unit = "plant_id", treatment = "water_regime")
  expect_identical(growth_design(gb)$design, "repeated")
  expect_identical(growth_validate(dz)$status, "ok")
})

test_that("functions with a seed argument preserve the global RNG state", {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  f <- suppressWarnings(growth_fit(d1, "logistic", time = "day", response = "biomass_g"))
  chamadas <- list(
    function() growth_fit(d1, "logistic", time = "day", response = "biomass_g", seed = 1),
    function() growth_multistart(d1, "logistic", time = "day", response = "biomass_g",
                                 n_start = 2, seed = 1),
    function() growth_boot(f, R = 20, seed = 1),
    function() growth_design_sim(model = "logistic",
                                 parameters = list(asym = 100, mid = 40, scale = 10),
                                 times = c(10, 20, 30, 40), n_unit = 4, seed = 1),
    function() growth_power(effect = 0.5, trait_sd = 1, n_unit = 8, n_sim = 100, seed = 1)
  )
  for (ch in chamadas) {
    set.seed(1000); antes <- .Random.seed
    suppressWarnings(suppressMessages(ch()))
    expect_identical(antes, .Random.seed)
  }
  set.seed(7); a <- { suppressWarnings(growth_fit(d1, "logistic", time = "day",
                                                  response = "biomass_g", seed = 1)); runif(2) }
  set.seed(9); b <- { suppressWarnings(growth_fit(d1, "logistic", time = "day",
                                                  response = "biomass_g", seed = 1)); runif(2) }
  expect_false(isTRUE(all.equal(a, b)))
})

test_that("event functions accept both the declared object and a raw frame", {
  d <- growth_example_data("bean_defoliation")
  g <- growth_data(d, time = "day", sampling = "repeated",
                   experimental_unit = "plant_id", treatment = "treatment",
                   total_mass = "total_mass_g", leaf_mass = "leaf_mass_g",
                   leaf_area = "leaf_area_m2")
  expect_s3_class(growth_event(g, time = "day", response = "total_mass_g", event_time = 30),
                  "agri_growth_event")
  expect_s3_class(growth_event(d, time = "day", response = "total_mass_g", event_time = 30),
                  "agri_growth_event")
  expect_s3_class(growth_defoliation(g, time = "day", total_mass = "total_mass_g",
                                     leaf_mass = "leaf_mass_g", leaf_area = "leaf_area_m2"),
                  "agri_growth_defoliation")
})

test_that("growth_table reports which components an object can serve", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", total_mass = "total_mass_g")
  f <- suppressWarnings(growth_fit(g, "logistic", time = "day", response = "total_mass_g"))
  err <- tryCatch(growth_table(f, component = "intervals"), error = function(e) conditionMessage(e))
  expect_match(err, "Available components")
  expect_match(err, "coefficients")
})

test_that("the Bayesian formula uses brms-valid parameter names", {
  d <- growth_example_data("sunflower_sigmoid")
  d1 <- subset(d, cultivar == unique(d$cultivar)[1])
  g <- growth_data(d1, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", total_mass = "biomass_g")
  pr <- growth_prior(g, "logistic")
  expect_false(any(grepl("_", unique(pr$nlpar))))
  skip_if_not_installed("brms")
  form <- agriGrowthFlow:::.agf_bayes_formula(
    "logistic",
    agriGrowthFlow:::.agf_prepare_bayes(g, aggregate = "auto"),
    group_effects = "none", random = "none")
  expect_s3_class(form, "brmsformula")
  skip_if_not_installed("cmdstanr")
  skip_on_cran()
  b <- suppressWarnings(growth_bayes(g, "logistic", backend = "cmdstanr",
                                     chains = 1, iter = 100, warmup = 50,
                                     cores = 1, seed = 1, refresh = 0,
                                     sample_prior = "only"))
  expect_s3_class(b, "agri_growth_bayes")
})
