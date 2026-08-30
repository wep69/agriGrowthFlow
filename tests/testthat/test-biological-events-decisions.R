test_that("multiphase logistic components remain ordered and positive", {
  d <- growth_example_data("coffee_diphasic")
  d <- subset(d, treatment == "control")
  f <- growth_diphasic(d, time = "day", response = "biomass_g", n_start = 3, seed = 11)
  expect_s3_class(f, "agri_growth_multiphase")
  expect_true(all(f$components$asym > 0))
  expect_true(all(f$components$scale > 0))
  expect_true(all(diff(f$components$mid) > 0))
})

test_that("exploratory changepoint detects a strong known slope break", {
  d <- data.frame(time = 0:20)
  d$y <- ifelse(d$time <= 10, 2 + d$time, 12 + 3 * (d$time - 10))
  cp <- growth_changepoint(d, time = "time", response = "y", min_segment = 3)
  expect_s3_class(cp, "agri_growth_changepoint")
  expect_equal(cp$breakpoint, 10, tolerance = 1)
  expect_true(cp$slope_after > cp$slope_before)
})

test_that("known events create centered time without changing original response", {
  d <- growth_example_data("bean_defoliation")
  e <- growth_event(d, time = "day", response = "total_mass_g", event_time = 21, unit = "plant_id")
  expect_s3_class(e, "agri_growth_event")
  expect_equal(e$data$.event_centered_time, d$day - 21)
  expect_equal(e$data$total_mass_g, d$total_mass_g)
})

test_that("iterative defoliation analysis returns finite biological parameters", {
  d <- growth_example_data("bean_defoliation")
  id <- unique(d$plant_id[d$treatment == "defoliated"])[1]
  z <- subset(d, plant_id == id)
  f <- growth_defoliation(z, time="day", total_mass="total_mass_g", leaf_mass="leaf_mass_g", leaf_area="leaf_area_m2",
                          total_loss="total_loss_g", leaf_mass_loss="leaf_mass_loss_g", leaf_area_loss="leaf_area_loss_m2", step=.5)
  expect_s3_class(f, "agri_growth_defoliation")
  expect_true(all(is.finite(f$parameters$NAR)))
  expect_true(all(f$parameters$flam > 0 & f$parameters$flam < 1))
  expect_true(all(f$parameters$gamma > 0))
})

test_that("compensation summaries retain the control reference", {
  d <- growth_example_data("bean_defoliation")
  z <- growth_compensation(d, group="treatment", control="control", response="total_mass_g", time="day", unit="plant_id", metric="final")
  expect_true(all(c("compensation_ratio","difference_from_control") %in% names(z)))
  expect_equal(z$compensation_ratio[z$group == "control"], 1, tolerance = 1e-10)
})

test_that("reciprocal density model has the expected direction", {
  d <- growth_example_data("maize_density")
  f <- growth_density(d, density="density_plants_m2", plant_mass="plant_mass_g")
  expect_s3_class(f, "agri_growth_density")
  expect_gt(unname(coef(f$fit)[["density"]]), 0)
})

test_that("neighborhood index is finite and self is excluded", {
  d <- data.frame(id=c("a","b"), x=c(0,1), y=c(0,0), size=c(10,20))
  z <- growth_neighbor(d, id="id", x="x", y="y", size="size", radius=2)
  expect_equal(z$n_neighbors, c(1L,1L))
  expect_equal(z$competition_index, c(2, .5), tolerance = 1e-12)
})

test_that("zero inter-plant competition preserves monotone logistic-like growth", {
  z <- growth_competition(c(1,2), times=0:5, r=c(.3,.4), K=c(20,25), competition_matrix=matrix(0,2,2), dt=.05)
  expect_s3_class(z, "agri_growth_competition")
  byp <- split(z$trajectory$size, z$trajectory$plant)
  expect_true(all(vapply(byp, function(x) all(diff(x) > 0), logical(1))))
})

test_that("fractional threshold for logistic agrees with t50", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == "C1")
  f <- growth_fit(d, "logistic", time="day", response="biomass_g")
  z <- growth_threshold(f, .5, type="fraction")
  tt <- growth_time_to(f, fraction=.5)
  expect_true(nrow(z) >= 1)
  expect_equal(z$time[1], tt$time[1], tolerance = .2)
})

test_that("response plateau criterion matches a fractional threshold", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == "C1")
  f <- growth_fit(d, "logistic", time="day", response="biomass_g")
  p <- growth_plateau_time(f, criterion="response", response_fraction=.9)
  z <- growth_threshold(f, .9, type="fraction")
  expect_equal(p$plateau_time, min(z$time), tolerance = .2)
})

test_that("harvest optimizer stays inside the requested interval", {
  d <- growth_example_data("sunflower_sigmoid")
  d <- subset(d, cultivar == "C1")
  f <- growth_fit(d, "logistic", time="day", response="biomass_g")
  h <- growth_harvest_opt(f, price=1, cost_per_time=.2, interval=c(10,70), n=501)
  expect_s3_class(h, "agri_growth_harvest")
  expect_gte(h$optimum_time, 10)
  expect_lte(h$optimum_time, 70)
})

test_that("observation schedules have requested size and boundaries", {
  z <- growth_schedule(time_range=c(0,100), n=7, method="equal")
  expect_equal(nrow(z), 7)
  expect_equal(z$time[c(1,7)], c(0,100))
})

test_that("design simulation has unit by time rows", {
  z <- growth_design_sim("logistic", c(asym=100,mid=30,scale=8), times=seq(0,60,10), n_unit=6, sigma=0, seed=1)
  expect_equal(nrow(z), 6 * 7)
  expect_equal(length(unique(z$unit)), 6)
  expect_equal(z$response, z$expected)
})

test_that("trait-level power increases with larger effect under fixed seed", {
  p1 <- growth_power(effect=2, trait_sd=8, n_unit=20, n_sim=500, seed=123)
  p2 <- growth_power(effect=8, trait_sd=8, n_unit=20, n_sim=500, seed=123)
  expect_s3_class(p1, "agri_growth_power")
  expect_gt(p2$power, p1$power)
})

test_that("general multiphase wrapper and stability search are callable", {
  d <- growth_example_data("coffee_diphasic")
  d <- subset(d, treatment == "control")
  f <- growth_multiphase(d, time="day", response="biomass_g", n_phases=2, n_start=2, seed=99)
  expect_s3_class(f, "agri_growth_multiphase")
  st <- growth_stability(f, n=501)
  expect_true(is.data.frame(st))
  expect_true(all(c("stability_time","response") %in% names(st)))
})
