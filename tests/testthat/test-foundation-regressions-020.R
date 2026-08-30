test_that("ambiguous vector recycling is rejected", {
  expect_error(growth_agr(1:2, 2:4, 0, 1), "Ambiguous vector recycling")
  expect_error(growth_lar(1:2, 1:3), "Ambiguous vector recycling")
})

test_that("scalar recycling remains available", {
  expect_equal(growth_agr(c(1, 2), c(2, 4), 0, 1), c(1, 2))
  expect_equal(growth_lar(c(1, 2), 4), c(0.25, 0.5))
})

test_that("partition print method exists", {
  d <- growth_example_data("soybean_partition")
  p <- growth_partition(d, total_mass = "total_mass_g",
                        components = c("leaf_mass_g", "root_mass_g", "stem_mass_g", "reproductive_mass_g"))
  expect_s3_class(p, "agri_growth_partition")
  expect_invisible(print(p))
})
