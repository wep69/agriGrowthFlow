test_that("grid FPCA returns unit scores and normalized variance", {
  d <- growth_example_data("bean_repeated")
  fp <- growth_fpca(d, time="day", response="height_cm", unit="plant_id", group="water_regime", npc=2)
  expect_s3_class(fp, "agri_growth_fpca")
  expect_equal(nrow(fp$scores_table), 32)
  expect_equal(fp$npc, 2)
  expect_true(all(diff(fp$pve_cumulative) >= 0))
  expect_true(fp$pve_cumulative[2] <= 1 + 1e-10)
})

test_that("functional alias matches grid engine structure", {
  d <- growth_example_data("bean_repeated")
  fp <- growth_functional(d, time="day", response="spad", unit="plant_id", npc=2)
  expect_s3_class(fp, "agri_growth_fpca")
  expect_true(all(c("FPC1","FPC2") %in% names(fp$scores_table)))
})

test_that("grid FPCA refuses non-overlapping unit support", {
  d <- data.frame(unit=rep(c("a","b"), each=4), time=c(0,1,2,3,10,11,12,13), y=1:8)
  expect_error(growth_fpca(d, time="time", response="y", unit="unit"), "common time interval")
})

test_that("irregular teaching data have persistent functional units", {
  d <- growth_example_data("soybean_irregular")
  expect_equal(length(unique(d$plant_id)), 48)
  expect_true(all(table(d$plant_id) >= 7))
  fp <- growth_fpca(d, time="day", response="height_cm", unit="plant_id", group="water_regime", npc=2)
  expect_equal(nrow(fp$scores_table), 48)
})
