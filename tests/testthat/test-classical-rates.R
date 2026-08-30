test_that("classical scalar quantities match analytical results", {
  expect_equal(growth_agr(10, 20, 0, 5), 2)
  expect_equal(growth_rgr(10, 20, 0, 5), log(2) / 5)
  expect_equal(growth_lar(0.05, 10), 0.005)
  expect_equal(growth_sla(0.05, 2), 0.025)
  expect_equal(growth_lmr(2, 10), 0.2)
  expect_equal(growth_lai(0.05, 0.1), 0.5)
  expect_equal(growth_cgr(10, 20, 0, 5, ground_area = 0.5), 4)
})

test_that("NAR uses the analytical logarithmic-mean expression", {
  expected <- ((20 - 10) / 5) * ((log(0.08) - log(0.05)) / (0.08 - 0.05))
  expect_equal(growth_nar(10, 20, 0.05, 0.08, 0, 5), expected)
})

test_that("NAR has a stable equal-area limit", {
  expect_equal(growth_nar(10, 20, 0.05, 0.05, 0, 5), 2 / 0.05)
})

test_that("LAD uses trapezoidal integration", {
  expect_equal(growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10)), 9.25)
  z <- growth_lad(c(0.5, 1.0, 1.2), c(0, 5, 10), intervals = TRUE)
  expect_equal(sum(z$lad), 9.25)
})

test_that("invalid supports are blocked", {
  expect_error(growth_rgr(0, 1, 0, 1), "positive")
  expect_error(growth_nar(1, 2, 0, 1, 0, 1), "positive leaf")
  expect_error(growth_lai(1, 0), "positive ground")
})
