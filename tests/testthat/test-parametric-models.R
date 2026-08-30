test_that("model registry contains the eight 0.2.0 models", {
  m <- growth_models()
  expect_equal(nrow(m), 8)
  expect_true(all(c("logistic", "gompertz", "richards", "chapman_richards",
                    "weibull", "von_bertalanffy", "beta_growth", "expolinear") %in% m$model))
})

test_that("canonical nonlinear equations satisfy known identities", {
  expect_equal(agriGrowthFlow:::.agf_logistic(30, 100, 30, 5), 50)
  expect_equal(agriGrowthFlow:::.agf_gompertz(30, 100, 30, 5), 100 / exp(1))
  t <- seq(0, 60, length.out = 20)
  expect_equal(
    agriGrowthFlow:::.agf_richards(t, 100, 30, 5, 1),
    agriGrowthFlow:::.agf_logistic(t, 100, 30, 5),
    tolerance = 1e-12
  )
})

test_that("corrected beta growth has correct endpoints", {
  w <- agriGrowthFlow:::.agf_beta_internal(c(0, 80), wmax = 200, tm = 45, gap = 35)
  expect_equal(w, c(0, 200), tolerance = 1e-12)
})

test_that("expolinear finite-difference slope approaches cm", {
  f <- function(t) agriGrowthFlow:::.agf_expolinear(t, cm = 12, rm = 0.1, tb = 30)
  slope <- (f(250.1) - f(249.9)) / 0.2
  expect_equal(slope, 12, tolerance = 1e-6)
})

test_that("noiseless logistic data recover generating parameters", {
  d <- data.frame(day = seq(0, 80, by = 5))
  d$mass <- 200 / (1 + exp(-(d$day - 35) / 8))
  f <- growth_fit(d, "logistic", time = "day", response = "mass", engine = "nls",
                  start = c(asym = 190, mid = 34, scale = 7))
  expect_equal(unname(coef(f)), c(200, 35, 8), tolerance = 1e-5)
})

test_that("grouped fits return one fit per group", {
  d <- growth_example_data("sunflower_sigmoid")
  f <- growth_fit(d, "logistic", time = "day", response = "biomass_g",
                  group = "cultivar", engine = "nls")
  expect_s3_class(f, "agri_growth_fit_collection")
  expect_equal(length(f$fits), length(unique(d$cultivar)))
})

test_that("destructive subsamples aggregate within stable plot and time", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == unique(d$cultivar)[1])
  g <- growth_data(d, time = "day", sampling = "destructive",
                   experimental_unit = "plot_id", total_mass = "biomass_g")
  f <- suppressWarnings(growth_fit(g, "logistic", engine = "nls"))
  expect_equal(nrow(f$data), length(unique(d$plot_id)) * length(unique(d$day)))
})
