test_that("one-day standard family reproduces the published default", {
  parameters <- standard_family_ar_parameters("1 day")
  expect_equal(unname(parameters@coefficients), c(1.765, -0.7262460, -0.04065607), tolerance = 1e-7)
})

test_that("infinite family reproduces the steady set", {
  parameters <- standard_family_ar_parameters("Infinite")
  expect_equal(unname(parameters@coefficients), c(1.765, -0.7244342, -0.04056586), tolerance = 1e-7)
  expect_true(is.infinite(attr(parameters, "principal_decay_steps")))
})

test_that("continuous family is calculated rather than interpolated", {
  parameters <- default_family_ar_parameters(9, units = "hours")
  roots_table <- root_table(roots(parameters, time_step_minutes = 15))
  principal <- max(roots_table$decay_time_hours[is.finite(roots_table$decay_time_hours)])
  expect_equal(principal, 9, tolerance = 1e-7)
})

test_that("standard catalogue contains all published choices", {
  table <- standard_family_ar_table()
  expect_equal(nrow(table), 11L)
  expect_equal(table$parameter_set[[1L]], "3 hours")
  expect_equal(table$parameter_set[[11L]], "Infinite")
})

test_that("days units match the equivalent hours call", {
  from_days <- default_family_ar_parameters(1, units = "days", time_step_minutes = 15)
  from_hours <- default_family_ar_parameters(24, units = "hours", time_step_minutes = 15)
  expect_equal(from_days@coefficients, from_hours@coefficients, tolerance = 1e-12)
})

test_that("default_family_ar_parameters rejects invalid principal_decay", {
  expect_error(default_family_ar_parameters(0), "positive")
  expect_error(default_family_ar_parameters(-5), "positive")
  expect_error(default_family_ar_parameters(NA_real_), "positive")
})

test_that("default_family_ar_parameters rejects invalid time_step_minutes", {
  expect_error(default_family_ar_parameters(9, units = "hours", time_step_minutes = 0), "positive")
  expect_error(default_family_ar_parameters(9, units = "hours", time_step_minutes = -15), "positive")
})

test_that("default_family_ar_parameters rejects a genuinely complex fast root", {
  # fast_period_steps other than Inf or 2 would be silently truncated by
  # Re() if this guard did not exist -- see the comment in
  # 14-default-parameter-family.R.
  expect_error(
    default_family_ar_parameters(9, units = "hours", fast_period_steps = 8),
    "Inf.*or.*2|constructs real roots"
  )
})

test_that("a principal decay too short to yield a valid middle root fails loudly", {
  # Below roughly 1.2 hours (at the default settings) the forced middle
  # root exceeds 1, which is not a valid member of this family.
  expect_error(
    default_family_ar_parameters(1, units = "steps"),
    "stable positive middle root"
  )
})

test_that("standard_family_ar_parameters forwards time_step_minutes to the calculation", {
  # Regression test: this previously hard-coded 15 minutes regardless of
  # what was passed, so a 60-minute model silently got 15-minute-timestep
  # coefficients.
  at_15 <- standard_family_ar_parameters("12 hours", time_step_minutes = 15)
  at_60 <- standard_family_ar_parameters("12 hours", time_step_minutes = 60)
  expect_false(isTRUE(all.equal(at_15@coefficients, at_60@coefficients)))
  expect_equal(attr(at_15, "principal_decay_steps"), 48)
  expect_equal(attr(at_60, "principal_decay_steps"), 12)
})

test_that("standard_family_ar_table forwards time_step_minutes to every row", {
  table_60 <- standard_family_ar_table(time_step_minutes = 60)
  expect_equal(
    table_60[parameter_set == "12 hours", principal_decay_steps],
    12
  )
})
