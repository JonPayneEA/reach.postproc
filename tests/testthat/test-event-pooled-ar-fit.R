simulate_ar_event <- function(n, a1, a2, sd = 1, burn_in = 50) {
  x <- numeric(n + burn_in)
  for (t in 3:length(x)) {
    x[t] <- a1 * x[t - 1] + a2 * x[t - 2] + stats::rnorm(1, sd = sd)
  }
  x[-(1:burn_in)]
}

test_that("fit_ar_from_events recovers coefficients shared across typical events", {
  set.seed(1)
  events <- replicate(
    12,
    simulate_ar_event(n = 60, a1 = 1.2, a2 = -0.45, sd = 1),
    simplify = FALSE
  )
  fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")
  expect_equal(unname(fitted@coefficients), c(1.2, -0.45), tolerance = 0.15)
})

test_that("variance weighting resists domination by one atypical, high-variance event", {
  # Mirrors the stress test that justified making "variance" the default
  # weighting scheme (see @section Choosing a weighting scheme): a single
  # much-larger-magnitude event should not be allowed to pull the fit onto
  # its own coefficients at the expense of the typical events. "none" has
  # no such protection by construction.
  set.seed(2)
  typical <- replicate(
    15,
    simulate_ar_event(n = 40, a1 = 1.2, a2 = -0.45, sd = 1),
    simplify = FALSE
  )
  atypical <- simulate_ar_event(n = 400, a1 = 0.3, a2 = 0.1, sd = 12)
  events <- c(typical, list(atypical = atypical))

  unweighted <- fit_ar_from_events(events, order = 2, weighting = "none")
  variance_weighted <- fit_ar_from_events(events, order = 2, weighting = "variance")

  distance_unweighted <- abs(unweighted@coefficients[["a_1"]] - 1.2)
  distance_weighted <- abs(variance_weighted@coefficients[["a_1"]] - 1.2)
  expect_true(distance_weighted < distance_unweighted)
})

test_that("fit_ar_from_events rejects a non-list or empty events argument", {
  expect_error(fit_ar_from_events(1:10), "non-empty list")
  expect_error(fit_ar_from_events(list()), "non-empty list")
})

test_that("fit_ar_from_events rejects an invalid order", {
  events <- list(a = rnorm(20), b = rnorm(20))
  expect_error(fit_ar_from_events(events, order = 0), "positive whole number")
  expect_error(fit_ar_from_events(events, order = c(1, 2)), "positive whole number")
  expect_error(fit_ar_from_events(events, order = NA), "positive whole number")
})

test_that("fit_ar_from_events rejects events that are too short, non-numeric or incomplete", {
  too_short <- list(a = rnorm(20), short = c(1, 2))
  expect_error(fit_ar_from_events(too_short, order = 3), "Too short or invalid.*short")

  with_na <- list(a = rnorm(20), has_na = c(rnorm(10), NA, rnorm(9)))
  expect_error(fit_ar_from_events(with_na, order = 2), "Too short or invalid.*has_na")

  not_numeric <- list(a = rnorm(20), text = letters[1:20])
  expect_error(fit_ar_from_events(not_numeric, order = 2), "Too short or invalid.*text")
})

test_that("variance weighting rejects a flat (zero-variance) event", {
  events <- list(a = rnorm(20), flat = rep(1, 20))
  expect_error(
    fit_ar_from_events(events, order = 2, weighting = "variance"),
    "zero variance"
  )
  # equal_event and none don't divide by variance, so a flat event is fine.
  expect_true(inherits(
    fit_ar_from_events(events, order = 2, weighting = "equal_event"),
    "ARParameterSet"
  ))
})

test_that("blank or missing event names are filled in deterministically", {
  events <- list(rnorm(20), named_event = rnorm(20), rnorm(20))
  fitted <- fit_ar_from_events(events, order = 2)
  per_event <- attr(fitted, "fit_per_event")
  expect_equal(per_event$event, c("event_1", "named_event", "event_3"))
})

test_that("fit_per_event diagnostics are complete and weight shares sum to one", {
  set.seed(3)
  events <- list(
    short_event = simulate_ar_event(30, 1.2, -0.45),
    long_event = simulate_ar_event(80, 1.2, -0.45)
  )
  fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")
  per_event <- attr(fitted, "fit_per_event")

  expect_equal(nrow(per_event), 2L)
  expect_setequal(
    names(per_event),
    c("event", "n_timesteps", "n_rows", "variance", "weight_share")
  )
  expect_equal(per_event$n_timesteps, c(30L, 80L))
  expect_equal(per_event$n_rows, c(28L, 78L))
  expect_equal(sum(per_event$weight_share), 1, tolerance = 1e-9)

  expect_equal(attr(fitted, "fit_weighting"), "variance")
  expect_equal(attr(fitted, "fit_n_events"), 2L)
  expect_equal(attr(fitted, "fit_total_rows"), sum(per_event$n_rows))
  expect_true(attr(fitted, "fit_residual_se") >= 0)
})

test_that("fit_ar_from_events output composes with roots() and assess()", {
  set.seed(4)
  events <- replicate(
    10,
    simulate_ar_event(n = 50, a1 = 1.2, a2 = -0.45),
    simplify = FALSE
  )
  fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")

  root_information <- roots(fitted, time_step_minutes = 15)
  expect_true(inherits(root_information, "CharacteristicRoots"))

  assessment <- assess(fitted, permitted_orders = c(2L, 3L))
  expect_true(is.logical(assessment@passed))
})
