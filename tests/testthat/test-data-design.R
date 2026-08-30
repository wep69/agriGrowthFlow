test_that("destructive teaching data validate with a stable plot", {
  d <- growth_example_data("maize_destructive")
  g <- growth_data(
    d, time = "day", sampling = "destructive",
    experimental_unit = "plot_id", treatment = "nitrogen", block = "block",
    total_mass = "total_mass_g", leaf_area = "leaf_area_m2",
    leaf_mass = "leaf_mass_g", ground_area = "ground_area_m2"
  )
  v <- growth_validate(g)
  expect_false(any(v$issues$code == "destructive_without_stable_unit"))
  expect_equal(v$n_times, 6)
})

test_that("repeated sampling without a subject is blocked", {
  d <- data.frame(day = c(1, 2, 1, 2), y = 1:4)
  g <- growth_data(d, time = "day", sampling = "repeated")
  v <- growth_validate(g)
  expect_true(any(v$issues$code == "repeated_without_subject"))
  expect_equal(v$status, "error")
})

test_that("RCBD design requires a block", {
  d <- data.frame(id = rep(letters[1:2], each = 2), day = rep(1:2, 2), trt = rep(c("A", "B"), each = 2))
  g <- growth_data(d, time = "day", sampling = "repeated", plant = "id", experimental_unit = "id", treatment = "trt")
  des <- growth_design(g, design = "rcbd")
  v <- growth_validate(des)
  expect_true(any(v$issues$code == "rcbd_without_block"))
})

test_that("serial destructive data require a unit that persists across harvests", {
  d <- data.frame(
    plot = paste0("p", 1:6),
    day = c(10, 20, 30, 10, 20, 30),
    trt = rep(c("A", "B"), each = 3),
    mass = c(2, 4, 8, 2.5, 5, 9)
  )
  g <- growth_data(
    d, time = "day", sampling = "destructive",
    experimental_unit = "plot", treatment = "trt", total_mass = "mass"
  )
  v <- growth_validate(g)
  expect_true(any(v$issues$code == "no_stable_unit_across_harvests"))
  expect_equal(v$status, "error")
  expect_error(growth_indices(g), "error-level validation issues")
})
