test_that("partitioning reports closure instead of silently normalizing", {
  d <- growth_example_data("soybean_partition")
  g <- growth_data(d, time = "day", sampling = "destructive",
    experimental_unit = "plot_id", total_mass = "total_mass_g",
    leaf_mass = "leaf_mass_g", root_mass = "root_mass_g",
    stem_mass = "stem_mass_g", reproductive_mass = "reproductive_mass_g")
  p <- growth_partition(g)
  expect_true(all(abs(p$closure - 1) < 1e-5))
  expect_true(all(p$closure_ok))
})

test_that("allometry recovers an exact power-law exponent", {
  x <- 1:20
  d <- data.frame(x = x, y = 2 * x^1.5)
  fit <- growth_allometry(d, "x", "y")
  expect_equal(fit$summary$k, 1.5, tolerance = 1e-10)
  expect_equal(fit$summary$a, 2, tolerance = 1e-10)
})
