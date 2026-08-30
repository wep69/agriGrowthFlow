test_that("growth_mixed preserves repeated plant hierarchy", {
  skip_if_not_installed("nlme")
  d <- growth_example_data("bean_repeated")
  m <- growth_mixed(d, time = "day", response = "height_cm", unit = "plant_id",
                    group = "water_regime", block = "block", degree = 2, random_degree = 1)
  expect_s3_class(m, "agri_growth_mixed")
  expect_equal(nlevels(m$data$.unit), 32)
  expect_equal(m$degree, 2)
  expect_true(all(is.finite(nlme::fixef(m$fit))))
})

test_that("destructive mixed analysis aggregates subsamples at plot-time", {
  skip_if_not_installed("nlme")
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time="day", sampling="destructive", experimental_unit="plot_id",
                   treatment="nitrogen", block="block", total_mass="total_mass_g")
  m <- growth_mixed(g, degree=2, random_degree=0)
  expect_equal(nrow(m$data), 72)
  expect_match(m$aggregation, "144 -> 72")
})

test_that("discrete AR1 rejects noninteger time", {
  skip_if_not_installed("nlme")
  d <- growth_example_data("bean_repeated")
  d$day <- d$day + 0.25
  expect_error(growth_mixed(d, time="day", response="height_cm", unit="plant_id", correlation="ar1"), "integer-valued")
})

test_that("mixed diagnostics are unit-aware", {
  skip_if_not_installed("nlme")
  d <- growth_example_data("bean_repeated")
  m <- growth_mixed(d, time="day", response="spad", unit="plant_id", degree=1)
  z <- growth_mixed_diagnose(m)
  expect_s3_class(z, "agri_growth_mixed_diagnostics")
  expect_equal(z$n_units, 32)
  expect_true(is.finite(z$residual_sd))
})
