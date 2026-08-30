test_that("smoothing spline fits grouped population trajectories", {
  d <- growth_example_data("bean_repeated")
  s <- growth_smooth(d, time="day", response="height_cm", group="water_regime", method="smooth_spline")
  expect_s3_class(s, "agri_growth_smooth_collection")
  expect_length(s$fits, 2)
  p <- growth_smooth_predict(s, n=25)
  expect_equal(length(unique(p$group)), 2)
  expect_equal(nrow(p), 50)
})

test_that("smooth-spline derivative recovers a linear trend", {
  d <- expand.grid(unit = paste0("u",1:8), time = 0:10)
  d$y <- 3 + 2*d$time
  s <- growth_smooth(d, time="time", response="y", method="smooth_spline")
  der <- growth_derivative(s, order=1, time=2:8)
  expect_equal(der$derivative, rep(2,7), tolerance=1e-5)
})

test_that("acceleration of a linear trend is approximately zero", {
  d <- expand.grid(unit = paste0("u",1:6), time = 0:10)
  d$y <- 5 + 1.5*d$time
  s <- growth_smooth(d, time="time", response="y")
  a <- growth_acceleration(s, time=2:8)
  expect_lt(max(abs(a$derivative)), 1e-4)
})

test_that("smooth traits return interpretable columns", {
  d <- growth_example_data("bean_repeated")
  s <- growth_smooth(d, time="day", response="projected_leaf_area_m2", group="water_regime")
  tr <- growth_smooth_traits(s, n=100)
  expect_true(all(c("maximum_growth_rate","time_maximum_growth_rate","n_inflections") %in% names(tr)))
  expect_equal(nrow(tr), 2)
})
