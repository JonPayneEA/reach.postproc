test_that("feh_time_to_peak reproduces the reference calculation", {
  tp <- feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003)
  expect_equal(tp, 2.085080, tolerance = 1e-5)
})

test_that("feh_time_to_peak defaults urbext to zero", {
  with_urbext_zero <- feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0)
  without_urbext <- feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5)
  expect_equal(with_urbext_zero, without_urbext)
})

test_that("feh_time_to_peak rejects non-positive descriptors", {
  expect_error(feh_time_to_peak(propwet = 0, dplbar = 6.46, dpsbar = 213.5), "positive finite")
  expect_error(feh_time_to_peak(propwet = 0.54, dplbar = -1, dpsbar = 213.5), "positive finite")
  expect_error(feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 0), "positive finite")
  expect_error(feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = -0.1), "non-negative finite")
})

test_that("feh_lag reproduces the reference calculation", {
  lag <- feh_lag(2.085080)
  expect_equal(lag, 2.480062, tolerance = 1e-5)
})

test_that("feh_lag composes directly with feh_time_to_peak", {
  tp <- feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003)
  lag <- feh_lag(tp)
  expect_equal(lag, 2.480062, tolerance = 1e-5)
})

test_that("feh_lag rejects a non-positive time_to_peak", {
  expect_error(feh_lag(0), "positive finite")
  expect_error(feh_lag(-1), "positive finite")
  expect_error(feh_lag(NA_real_), "positive finite")
})

test_that("feh_time_to_peak composes with response_time_steps_from_tp", {
  tp <- feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003)
  steps <- response_time_steps_from_tp(tp, time_step_minutes = 15)
  expect_equal(steps, tp * 60 / 15)
})
