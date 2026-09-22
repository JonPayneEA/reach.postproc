# Root interpretation and parameter assessment -------------------------------

#' Calculate the effective decay time of an oscillating root
#'
#' Finds the first time at which an oscillating exponential reaches `exp(-1)`.
#'
#' @param decay_time Positive exponential decay time in model steps.
#' @param oscillation_period Oscillation period in model steps, or `Inf`.
#'
#' @return Effective decay time in model steps.
#'
#' @export
effective_decay_time <- function(
    decay_time,
    oscillation_period
) {
  validate_positive_scalar(decay_time, "decay_time")

  if (
    length(oscillation_period) != 1L ||
      !is.numeric(oscillation_period) ||
      is.na(oscillation_period) ||
      oscillation_period < 2
  ) {
    stop_bad_argument(
      "`oscillation_period` must be at least 2 or `Inf`."
    )
  }

  if (is.infinite(oscillation_period)) {
    return(decay_time)
  }

  objective <- function(time) {
    exp(-time / decay_time) *
      cos(2 * pi * time / oscillation_period) -
      exp(-1)
  }

  stats::uniroot(
    f = objective,
    interval = c(
      0,
      min(decay_time, oscillation_period / 4)
    )
  )$root
}

S7::method(roots, ARParameterSet) <- function(
    x,
    ...,
    time_step_minutes = 15,
    tolerance = sqrt(.Machine$double.eps)
) {
  validate_positive_scalar(time_step_minutes, "time_step_minutes")
  validate_non_negative_scalar(tolerance, "tolerance")

  # polyroot() expects coefficients from the constant term upwards.
  polynomial_coefficients <- c(
    -rev(x@coefficients),
    1
  )

  root_values <- polyroot(polynomial_coefficients)
  root_modulus <- Mod(root_values)
  root_angle <- Arg(root_values)
  raw_decay_time <- -1 / log(root_modulus)
  growing <- root_modulus > 1 + tolerance

  effectively_real <- abs(Im(root_values)) <= tolerance
  oscillation_period <- rep(NA_real_, length(root_values))

  oscillation_period[
    effectively_real & Re(root_values) >= 0
  ] <- Inf

  oscillation_period[
    effectively_real & Re(root_values) < 0
  ] <- 2

  complex_rows <- !effectively_real
  oscillation_period[complex_rows] <- 2 * pi /
    abs(root_angle[complex_rows])

  effective_time <- mapply(
    FUN = function(decay_time, period, is_growing) {
      if (is_growing) {
        return(Inf)
      }

      effective_decay_time(
        decay_time = decay_time,
        oscillation_period = period
      )
    },
    decay_time = raw_decay_time,
    period = oscillation_period,
    is_growing = growing
  )

  display_decay_time <- raw_decay_time
  display_decay_time[growing | is.infinite(display_decay_time)] <- Inf

  root_table <- data.table::data.table(
    root_id = seq_along(root_values),
    root_real = Re(root_values),
    root_imaginary = Im(root_values),
    root_modulus = root_modulus,
    decay_time_steps = display_decay_time,
    effective_decay_time_steps = effective_time,
    decay_time_hours = display_decay_time * time_step_minutes / 60,
    effective_decay_time_hours = effective_time * time_step_minutes / 60,
    oscillation_period_steps = oscillation_period,
    oscillation_period_hours = oscillation_period * time_step_minutes / 60,
    is_growing = growing,
    is_oscillating = is.finite(oscillation_period)
  )

  data.table::setorder(
    root_table,
    -decay_time_steps
  )

  data.table::set(
    x = root_table,
    j = "display_order",
    value = seq_len(nrow(root_table))
  )

  CharacteristicRoots(
    parameters = x,
    values = as.complex(root_values),
    table = root_table,
    time_step_minutes = as.numeric(time_step_minutes)
  )
}

S7::method(assess, ARParameterSet) <- function(
    x,
    ...,
    maximum_decay_time = 240,
    minimum_useful_decay_time = 8,
    rapid_decay_exception = 1,
    oscillation_ratio = -2 * log(0.1),
    decay_measure = c("effective", "exponential"),
    permitted_orders = c(2L, 3L),
    time_step_minutes = 15
) {
  decay_measure <- match.arg(decay_measure)

  root_result <- roots(
    x,
    time_step_minutes = time_step_minutes
  )

  root_table <- root_result@table
  decay_column <- if (decay_measure == "effective") {
    "effective_decay_time_steps"
  } else {
    "decay_time_steps"
  }

  decay_values <- root_table[[decay_column]]

  # Use explicit vectors rather than data.table column lookup here. This keeps
  # the assessment method stable when files are sourced during development and
  # the package namespace has not yet been rebuilt by roxygen2.
  growing_rows <- root_table$is_growing

  slow_rows <- !root_table$is_growing &
    decay_values >= maximum_decay_time

  oscillating_rows <- root_table$is_oscillating &
    root_table$decay_time_steps >= rapid_decay_exception &
    root_table$oscillation_period_steps <
      oscillation_ratio * root_table$decay_time_steps

  growing_roots <- root_table$display_order[
    growing_rows
  ]

  slow_roots <- root_table$display_order[
    slow_rows
  ]

  all_roots_fast <- all(
    !root_table$is_growing &
      decay_values < minimum_useful_decay_time
  )

  oscillating_roots <- root_table$display_order[
    oscillating_rows
  ]

  affected_roots <- list(
    integer(),
    growing_roots,
    slow_roots,
    if (all_roots_fast) root_table$display_order else integer(),
    oscillating_roots
  )

  failed <- c(
    !(x@order %in% permitted_orders),
    length(growing_roots) > 0L,
    length(slow_roots) > 0L,
    all_roots_fast,
    length(oscillating_roots) > 0L
  )

  tests <- data.table::data.table(
    test_id = c("order", "a", "b", "c", "d"),
    test = c(
      "Permitted AR order",
      "Exponential growth",
      "Excessive decay time",
      "All roots decay too quickly",
      "Unacceptable oscillation"
    ),
    failed = failed,
    affected_roots = affected_roots,
    criterion = c(
      paste("Order in", paste(permitted_orders, collapse = ", ")),
      "Any root modulus exceeds one",
      paste(decay_measure, "decay time reaches the maximum"),
      paste("All", decay_measure, "decay times are below the minimum"),
      "Oscillation period is too short relative to decay time"
    )
  )

  summary <- if (any(failed)) {
    paste(
      "Fail:",
      paste(
        tests$test[tests$failed],
        collapse = "; "
      )
    )
  } else if (any(root_table$is_oscillating)) {
    "Pass. Oscillations are present but meet the accepted criterion."
  } else {
    "Pass. All roots meet the accepted limits and none oscillate."
  }

  ARAssessment(
    parameters = x,
    passed = !any(failed),
    result = if (any(failed)) "Fail" else "Pass",
    summary = summary,
    tests = tests,
    roots = root_result
  )
}
