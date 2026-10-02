test_that("ar_parameters_from_timescales keeps Inf and 2 periods real and unpaired", {
  parameters <- ar_parameters_from_timescales(
    decay_times = c(96, 5.203171, 1 / 3),
    oscillation_periods = c(Inf, Inf, 2)
  )
  expect_equal(parameters@order, 3L)
  expect_true(all(abs(Im(roots(parameters)@values)) < 1e-6))
})

test_that("ar_parameters_from_timescales auto-pairs a genuinely complex root with its conjugate", {
  parameters <- ar_parameters_from_timescales(
    decay_times = 20,
    oscillation_periods = 8
  )
  # root_from_timescale() alone returns one root; the conjugate is added
  # automatically, so one requested timescale yields an AR(2) model.
  expect_equal(parameters@order, 2L)

  root_values <- roots(parameters)@values
  imaginary_parts <- sort(Im(root_values))
  expect_equal(length(root_values), 2L)
  expect_true(imaginary_parts[1] < -1e-6)
  expect_true(imaginary_parts[2] > 1e-6)
  expect_equal(imaginary_parts[1], -imaginary_parts[2], tolerance = 1e-8)
})

test_that("ar_parameters_from_timescales mixes real and complex-paired roots correctly", {
  # One real root (Inf) plus one genuinely complex pair (period 8) -> AR(3).
  parameters <- ar_parameters_from_timescales(
    decay_times = c(96, 20),
    oscillation_periods = c(Inf, 8)
  )
  expect_equal(parameters@order, 3L)

  root_values <- roots(parameters)@values
  n_real <- sum(abs(Im(root_values)) < 1e-6)
  n_complex <- sum(abs(Im(root_values)) >= 1e-6)
  expect_equal(n_real, 1L)
  expect_equal(n_complex, 2L)
})

test_that("plot_ar shows a nonzero imaginary component for a genuinely oscillating root", {
  parameters <- ar_parameters_from_timescales(
    decay_times = 20,
    oscillation_periods = 8
  )
  d <- root_table(roots(parameters))
  expect_true(any(abs(d$root_imaginary) > 1e-6))
  p <- plot_ar(roots(parameters), root_definition = "modal")
  built <- ggplot2::ggplot_build(p)
  point_layer <- which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  expect_true(any(abs(built$data[[point_layer]]$y) > 1e-6))
})
