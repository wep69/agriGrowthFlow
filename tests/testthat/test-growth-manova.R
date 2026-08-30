test_that("orthogonal coefficients are computed at persistent plot level", {
  d <- growth_example_data("maize_destructive")
  cf <- growth_curve_coefficients(d, time="day", response="total_mass_g", unit="plot_id", group="nitrogen", degree=2)
  expect_equal(nrow(cf), 12)
  expect_true(all(c("level","P1","P2") %in% names(cf)))
  expect_equal(length(unique(cf$group)), 3)
})

test_that("growth MANOVA returns multivariate and component analyses", {
  d <- growth_example_data("maize_destructive")
  mv <- growth_manova(d, time="day", response="total_mass_g", unit="plot_id", group="nitrogen", degree=2)
  expect_s3_class(mv, "agri_growth_manova")
  expect_s3_class(mv$fit, "manova")
  expect_equal(mv$test, "Pillai")
})

test_that("MANOVA coefficient layer refuses missing harvest grids", {
  d <- growth_example_data("maize_destructive")
  d <- d[!(d$plot_id == unique(d$plot_id)[1] & d$day == max(d$day)),]
  expect_error(growth_curve_coefficients(d, time="day", response="total_mass_g", unit="plot_id", group="nitrogen", degree=2), "same observed time grid")
})

test_that("log transformation is guarded", {
  d <- growth_example_data("maize_destructive")
  d$total_mass_g[1] <- 0
  expect_error(growth_curve_coefficients(d, time="day", response="total_mass_g", unit="plot_id", group="nitrogen", transform="log"), "strictly positive")
})
