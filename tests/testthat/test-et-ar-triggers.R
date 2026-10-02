test_that("rainfall accumulation trigger uses moving window", {
  x <- rainfall_accumulation_trigger(c(0,1,2,3,0), 3L, 5)
  expect_equal(x$data$accumulated_rainfall, c(0,1,3,6,5))
  expect_equal(x$data$triggered, c(FALSE,FALSE,FALSE,TRUE,TRUE))
})
test_that("CWI scaling follows Part 2 piecewise rule", {
  expect_equal(cwi_rainfall_factor(c(120,125,145,165,170)), c(1,1,.5,0,0))
})
test_that("trigger constructors return data.table objects, not data.frame", {
  expect_true(data.table::is.data.table(logical_et_trigger(c(FALSE, TRUE))$data))
  expect_true(data.table::is.data.table(rainfall_accumulation_trigger(c(0, 1, 2), 2L, 1)$data))
  expect_true(data.table::is.data.table(updated_threshold_trigger(1.0)$data))
})
test_that("CWI-adjusted trigger rescales the rainfall threshold and updates triggered flags", {
  rainfall <- c(0, 1, 2, 3, 0)
  trigger <- cwi_adjusted_rainfall_trigger(
    rainfall, cwi = 165, dry_threshold = 5, window_steps = 3L
  )
  expect_true(data.table::is.data.table(trigger$data))
  expect_equal(trigger$data$cwi, rep(165, length(rainfall)))
  expect_equal(trigger$data$threshold, rep(0, length(rainfall)))
  expect_true(all(trigger$data$triggered))
})
test_that("CWI-adjusted trigger leaves the dry-condition threshold untouched at CWI 125", {
  rainfall <- c(0, 1, 2, 3, 0)
  trigger <- cwi_adjusted_rainfall_trigger(
    rainfall, cwi = 125, dry_threshold = 5, window_steps = 3L
  )
  expect_equal(trigger$data$threshold, rep(5, length(rainfall)))
  expect_equal(trigger$data$triggered, trigger$data$accumulated_rainfall >= 5)
})
