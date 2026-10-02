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
