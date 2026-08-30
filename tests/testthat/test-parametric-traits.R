test_that("analytic logistic traits are coherent", {
  d <- data.frame(day = seq(0, 80, by = 5))
  d$mass <- 200 / (1 + exp(-(d$day - 35) / 8))
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls",
                  start = c(asym = 190, mid = 34, scale = 7))
  tr <- growth_traits(f)
  expect_equal(tr$inflection_time, 35, tolerance = 1e-5)
  expect_equal(tr$inflection_response, 100, tolerance = 1e-4)
  expect_equal(tr$maximum_absolute_rate, 200 / 32, tolerance = 1e-4)
  expect_equal(tr$t50, 35, tolerance = 1e-5)
  expect_true(is.finite(tr$auc_observed_support))
})

test_that("grouped traits always return a data frame with group", {
  d <- growth_example_data("sunflower_sigmoid")
  f <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
                  group = "cultivar", engine = "nls")
  tr <- growth_traits(f)
  expect_true(is.data.frame(tr))
  expect_true("group" %in% names(tr))
  expect_true(all(c("maximum_absolute_rate", "auc_observed_support", "support_min", "support_max") %in% names(tr)))
})

test_that("expolinear does not fabricate asymptote fractions", {
  d <- growth_example_data("wheat_expolinear")
  d <- subset(d, nitrogen == unique(d$nitrogen)[1])
  f <- growth_fit(d, "expolinear", time = "day", response = "biomass_g_m2", engine = "nls")
  expect_error(growth_time_to(f, fraction = 0.5), "undefined")
  expect_true(is.finite(growth_time_to(f, target = 300)$time))
  expect_equal(growth_maxrate(f)$maximum_absolute_rate, coef(f)[["cm"]])
})

test_that("zero-target conventions are explicit", {
  d <- data.frame(day = seq(0, 80, by = 5))
  d$mass <- 200 / (1 + exp(-(d$day - 35) / 8))
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls",
                  start = c(asym = 190, mid = 34, scale = 7))
  expect_equal(growth_time_to(f, target = 0)$time, -Inf)
})

test_that("confidence and prediction interval ordering is coherent", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  f <- growth_fit(d, "logistic", time = "day", response = "biomass_g", engine = "nls")
  pc <- growth_predict(f, time = c(25, 40, 55), interval = "confidence")
  pp <- growth_predict(f, time = c(25, 40, 55), interval = "prediction")
  expect_true(all(pc$lower <= pc$fit & pc$fit <= pc$upper))
  expect_true(all(pp$lower <= pp$fit & pp$fit <= pp$upper))
  expect_true(all((pp$upper - pp$lower) >= (pc$upper - pc$lower)))
})

test_that("same-observation comparison yields normalized weights", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  s <- growth_fit(d, c("logistic", "gompertz"), time = "day", response = "biomass_g", engine = "nls")
  ctab <- growth_compare(s)
  expect_equal(sum(ctab$akaike_weight, na.rm = TRUE), 1, tolerance = 1e-10)
})
