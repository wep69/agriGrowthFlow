test_that("automatic bootstrap selects case sampling without persistent units", {
  d <- data.frame(day = seq(0, 80, by = 5))
  d$mass <- 180 / (1 + exp(-(d$day - 35) / 7))
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls")
  b <- growth_boot(f, R = 20, seed = 11, engine = "nls")
  expect_s3_class(b, "agri_growth_boot")
  expect_equal(b$method, "case")
  expect_equal(nrow(b$records), 20)
  expect_true(b$success_rate > 0.5)
})

test_that("cluster bootstrap resamples complete persistent-unit trajectories", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", total_mass = "biomass_g")
  f <- suppressWarnings(growth_fit(g, "logistic", engine = "nls"))
  expect_true(length(unique(f$data$.unit)) > 1)
  b <- growth_boot(f, R = 20, method = "cluster", seed = 12, engine = "nls")
  expect_equal(b$method, "cluster")
  expect_equal(nrow(b$coefficients), 20)
})

test_that("bootstrap intervals summarize coefficients and traits", {
  d <- data.frame(day = seq(0, 80, by = 4))
  d$mass <- 150 / (1 + exp(-(d$day - 30) / 6)) + sin(d$day) * 0.1
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls")
  b <- growth_boot(f, R = 20, seed = 2, engine = "nls")
  ci <- growth_boot_ci(b, source = "coefficients", parm = "mid")
  expect_equal(ci$parameter, "mid")
  expect_true(all(c("estimate", "lower", "upper", "bootstrap_se") %in% names(ci)))
  tr <- growth_boot_traits(b, traits = "t50")
  expect_equal(tr$parameter, "t50")
})

test_that("wild bootstrap options are explicitly stored", {
  d <- data.frame(day = seq(0, 80, by = 4))
  d$mass <- 120 / (1 + exp(-(d$day - 30) / 7)) + 0.02 * d$day
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls")
  b <- growth_boot(f, R = 20, method = "wild", wild_weights = "mammen", seed = 4, engine = "nls")
  expect_equal(b$wild_weights, "mammen")
})

test_that("selection stability returns frequencies summing to one when successful", {
  d <- data.frame(day = seq(0, 80, by = 4))
  d$mass <- 160 / (1 + exp(-(d$day - 35) / 7)) + cos(d$day) * 0.05
  s <- growth_selection_stability(d, c("logistic", "gompertz"),
                                  time = "day", response = "mass",
                                  R = 20, seed = 5, engine = "nls")
  expect_s3_class(s, "agri_growth_selection_stability")
  if (sum(s$replicates$success) > 0) {
    expect_equal(sum(s$frequencies$selection_frequency), 1, tolerance = 1e-12)
  }
})
