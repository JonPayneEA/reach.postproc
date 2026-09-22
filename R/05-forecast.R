# Recurrence calculations and updated forecast construction.

S7::method(forecast_ar, ARParameterSet) <- function(x, ..., initial_errors, steps = 480L,
                                                     time_step_minutes = 15) {
  .assert_numeric_vector(initial_errors, "initial_errors")
  if (length(initial_errors) != x@order) {
    .stop_bad(sprintf("`initial_errors` must contain exactly %s values, newest first.", x@order))
  }
  .assert_whole_number(steps, "steps", 0L)
  if (length(time_step_minutes) != 1L || !is.numeric(time_step_minutes) ||
      is.na(time_step_minutes) || time_step_minutes <= 0) {
    .stop_bad("`time_step_minutes` must be one positive value.")
  }
  steps <- as.integer(steps)
  state <- as.numeric(initial_errors)
  values <- numeric(steps)
  if (steps > 0L) {
    for (step_index in seq_len(steps)) {
      next_error <- sum(x@coefficients * state)
      values[[step_index]] <- next_error
      state <- if (x@order == 1L) next_error else c(next_error, state[-x@order])
    }
  }
  series <- data.table::data.table(
    step = seq_len(steps),
    lead_time_minutes = seq_len(steps) * time_step_minutes,
    lead_time_hours = seq_len(steps) * time_step_minutes / 60,
    ar_error = values
  )
  ARForecast(
    parameters = x,
    initial_errors = as.numeric(initial_errors),
    series = series,
    time_step_minutes = as.numeric(time_step_minutes)
  )
}

apply_ar_update <- function(simulated, ar_error, lower_limit = NULL, time = NULL) {
  .assert_numeric_vector(simulated, "simulated", finite = FALSE)
  .assert_numeric_vector(ar_error, "ar_error", finite = FALSE)
  if (length(simulated) != length(ar_error)) {
    .stop_bad("`simulated` and `ar_error` must have equal lengths.")
  }
  if (is.null(time)) time <- seq_along(simulated)
  if (length(time) != length(simulated)) .stop_bad("`time` must match the series length.")
  unconstrained <- simulated + ar_error
  updated <- if (is.null(lower_limit)) unconstrained else {
    if (length(lower_limit) != 1L || !is.numeric(lower_limit) || is.na(lower_limit)) {
      .stop_bad("`lower_limit` must be `NULL` or one numeric value.")
    }
    pmax(unconstrained, lower_limit)
  }
  data.table::data.table(
    time = time,
    simulated = simulated,
    ar_error = ar_error,
    updated_unconstrained = unconstrained,
    updated = updated,
    was_limited = updated != unconstrained
  )
}

S7::method(decompose_ar, ARParameterSet) <- function(x, ..., initial_errors, steps = 480L,
                                                      time_step_minutes = 15) {
  .assert_numeric_vector(initial_errors, "initial_errors")
  if (length(initial_errors) != x@order) {
    .stop_bad(sprintf("`initial_errors` must contain exactly %s values, newest first.", x@order))
  }
  .assert_whole_number(steps, "steps", 0L)
  root_object <- roots(x, time_step_minutes = time_step_minutes)
  root_values <- root_object@values
  lags <- seq_len(x@order)
  root_matrix <- outer(-lags, root_values, function(time, root) root^time)
  if (kappa(root_matrix) > 1e12) {
    warning("Root decomposition is ill-conditioned because roots are repeated or nearly repeated.", call. = FALSE)
  }
  weights <- solve(root_matrix, as.complex(initial_errors))
  output <- data.table::rbindlist(lapply(seq_along(root_values), function(root_index) {
    step <- 0:as.integer(steps)
    contribution <- weights[[root_index]] * root_values[[root_index]]^step
    data.table::data.table(
      step = step,
      lead_time_minutes = step * time_step_minutes,
      lead_time_hours = step * time_step_minutes / 60,
      root_number = root_index,
      root_real = Re(root_values[[root_index]]),
      root_imaginary = Im(root_values[[root_index]]),
      weight_real = Re(weights[[root_index]]),
      weight_imaginary = Im(weights[[root_index]]),
      contribution_real = Re(contribution),
      contribution_imaginary = Im(contribution)
    )
  }))
  output[]
}
