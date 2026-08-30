test_that("destructive replicates are aggregated within plot-date", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(
    d, time = "day", sampling = "destructive",
    experimental_unit = "plot_id", treatment = "nitrogen", block = "block",
    total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
    leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2"
  )
  idx <- growth_indices(g)
  expect_s3_class(idx, "agri_growth_indices")
  expect_equal(nrow(idx$aggregated), 4 * 3 * 6)
  expect_equal(nrow(idx$intervals), 4 * 3 * 5)
  expect_true(all(c("AGR", "RGR", "NAR", "CGR", "LAI1", "LAD") %in% names(idx$intervals)))
})

test_that("LAR decomposition is internally consistent", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(d, time = "day", sampling = "destructive",
    experimental_unit = "plot_id", total_mass = "total_mass_g",
    leaf_area = "leaf_area_m2", leaf_mass = "leaf_mass_g")
  idx <- growth_indices(g)
  z <- idx$intervals
  expect_equal(z$LAR1, z$SLA1 * z$LMR1, tolerance = 1e-10)
})
