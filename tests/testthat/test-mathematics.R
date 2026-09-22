test_that("the documented defaults produce the expected roots", {
  result <- roots(default_ar_parameters())@table
  expect_equal(sort(result$root_real), sort(c(-0.04979, 0.8252, 0.9896)), tolerance = 5e-4)
})

test_that("the documented defaults pass assessment", {
  result <- assess(default_ar_parameters())
  expect_true(result@passed)
  expect_identical(result@result, "Pass")
})

test_that("a growing AR(1) model fails", {
  result <- assess(ar_parameters(coefficients = c(a_1 = 1.1)))
  expect_false(result@passed)
  expect_true(result@tests[test_id == "a", failed])
})

test_that("recurrence and root decomposition agree", {
  parameters <- default_ar_parameters()
  initial <- c(0.20, 0.15, 0.10)
  recurrence <- forecast_ar(parameters, initial_errors = initial, steps = 100L)@series
  decomposition <- decompose_ar(parameters, initial_errors = initial, steps = 100L)
  total <- decomposition[step > 0, .(from_roots = sum(contribution_real)), by = step]
  expect_equal(recurrence$ar_error, total$from_roots, tolerance = 1e-9)
})

test_that("roots round-trip to parameters", {
  expected <- default_ar_parameters()
  actual <- roots_to_parameters(roots(expected)@values)
  expect_equal(actual@coefficients, expected@coefficients, tolerance = 1e-10)
})

test_that("all tabular outputs use data.table", {
  parameters <- default_ar_parameters()
  expect_true(data.table::is.data.table(roots(parameters)@table))
  expect_true(data.table::is.data.table(assess(parameters)@tests))
  expect_true(data.table::is.data.table(
    forecast_ar(parameters, initial_errors = c(0.2, 0.15, 0.1), steps = 10L)@series
  ))
})
