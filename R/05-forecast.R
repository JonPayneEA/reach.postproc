# AR forecasting and decomposition -------------------------------------------

S7::method(forecast_ar, ARParameterSet) <- function(
    x,
    ...,
    initial_errors,
    steps = 480L,
    time_step_minutes = 15
) {
  validate_numeric_vector(initial_errors, "initial_errors")
  steps <- validate_whole_number(steps, "steps")
  validate_positive_scalar(time_step_minutes, "time_step_minutes")

  if (length(initial_errors) != x@order) {
    stop_bad_argument(
      "`initial_errors` must match the AR order and be ordered newest first."
    )
  }

  state <- initial_errors
  forecast_values <- numeric(steps)

  if (steps > 0L) {
    for (step_index in seq_len(steps)) {
      next_error <- sum(
        x@coefficients * state
      )

      forecast_values[[step_index]] <- next_error

      # Shift the state so the newly calculated error becomes the most recent
      # value for the next recurrence step.
      state <- if (x@order == 1L) {
        next_error
      } else {
        c(next_error, state[-x@order])
      }
    }
  }

  series <- data.table::data.table(
    step = seq_len(steps),
    lead_time_minutes = seq_len(steps) * time_step_minutes,
    lead_time_hours = seq_len(steps) * time_step_minutes / 60,
    ar_error = forecast_values
  )

  ARForecast(
    parameters = x,
    initial_errors = initial_errors,
    series = series,
    time_step_minutes = as.numeric(time_step_minutes)
  )
}

#' Apply AR errors to a simulated series
#'
#' @param simulated Numeric simulated values.
#' @param ar_error Numeric projected errors of equal length.
#' @param lower_limit Optional lower bound applied to the updated series.
#' @param time Optional time or lead vector.
#'
#' @return A `data.table` containing constrained and unconstrained updates.
#'
#' @export
apply_ar_update <- function(
    simulated,
    ar_error,
    lower_limit = NULL,
    time = seq_along(simulated)
) {
  if (length(simulated) != length(ar_error)) {
    stop_bad_argument(
      "`simulated` and `ar_error` must have equal lengths."
    )
  }

  updated_unconstrained <- simulated + ar_error
  updated <- if (is.null(lower_limit)) {
    updated_unconstrained
  } else {
    pmax(updated_unconstrained, lower_limit)
  }

  data.table::data.table(
    time = time,
    simulated = simulated,
    ar_error = ar_error,
    updated_unconstrained = updated_unconstrained,
    updated = updated,
    was_limited = !is.na(updated) &
      !is.na(updated_unconstrained) &
      updated != updated_unconstrained
  )
}

S7::method(decompose_ar, ARParameterSet) <- function(
    x,
    ...,
    initial_errors,
    steps = 480L,
    time_step_minutes = 15
) {
  if (length(initial_errors) != x@order) {
    stop_bad_argument(
      "`initial_errors` must match the AR order."
    )
  }

  root_values <- roots(x)@values
  known_times <- -seq_len(x@order)

  root_matrix <- outer(
    X = known_times,
    Y = root_values,
    FUN = function(time, root) {
      root^time
    }
  )

  if (kappa(root_matrix) > 1e12) {
    warning(
      "Root decomposition is ill-conditioned.",
      call. = FALSE
    )
  }

  weights <- solve(
    root_matrix,
    as.complex(initial_errors)
  )

  data.table::rbindlist(
    lapply(
      seq_along(root_values),
      function(root_index) {
        step <- 0:steps
        contribution <- weights[[root_index]] *
          root_values[[root_index]]^step

        data.table::data.table(
          step = step,
          lead_time_hours = step * time_step_minutes / 60,
          root_number = root_index,
          weight_real = Re(weights[[root_index]]),
          weight_imaginary = Im(weights[[root_index]]),
          contribution_real = Re(contribution),
          contribution_imaginary = Im(contribution)
        )
      }
    )
  )
}

#' Align an AR forecast with a complete time axis
#'
#' @param forecast An `ARForecast`.
#' @param time Complete time vector.
#' @param forecast_time Index or timestamp identifying the first forecast row.
#' @param include_initialisation Include the input-error sequence in the result.
#'
#' @return A `data.table` containing history, initialisation and forecast rows.
#'
#' @export
align_ar_forecast <- function(
    forecast,
    time,
    forecast_time,
    include_initialisation = TRUE
) {
  if (!S7::S7_inherits(forecast, ARForecast)) {
    stop_bad_argument("`forecast` must be an ARForecast.")
  }

  forecast_index <- if (
    is.numeric(forecast_time) &&
      length(forecast_time) == 1L
  ) {
    as.integer(forecast_time)
  } else {
    match(forecast_time, time)
  }

  if (
    is.na(forecast_index) ||
      forecast_index <= forecast@parameters@order
  ) {
    stop_bad_argument(
      "`forecast_time` is invalid or leaves insufficient initialisation data."
    )
  }

  result <- data.table::data.table(
    time = time,
    ar_error = NA_real_,
    period_type = "history"
  )

  initial_indices <- seq.int(
    forecast_index - forecast@parameters@order,
    forecast_index - 1L
  )

  if (include_initialisation) {
    result[
      initial_indices,
      `:=`(
        ar_error = rev(forecast@initial_errors),
        period_type = "initialisation"
      )
    ]
  }

  forecast_indices <- seq.int(
    forecast_index,
    min(
      length(time),
      forecast_index + nrow(forecast@series) - 1L
    )
  )

  result[
    forecast_indices,
    `:=`(
      ar_error = forecast@series$ar_error[seq_along(forecast_indices)],
      period_type = "forecast"
    )
  ]

  result[]
}

#' Apply an AR update within a complete event series
#'
#' @param parameters An `ARParameterSet`.
#' @param data Input data coercible to a `data.table`.
#' @param time_column Name of the time column.
#' @param simulated_column Name of the simulated-value column.
#' @param forecast_time Index or timestamp for the forecast start.
#' @param initial_errors Input errors ordered newest first.
#' @param lower_limit Optional lower bound.
#' @param time_step_minutes Duration represented by one model step.
#'
#' @return A `data.table` containing aligned simulated, AR and updated values.
#'
#' @export
update_forecast_series <- function(
    parameters,
    data,
    time_column = "date_time",
    simulated_column = "simulated",
    forecast_time,
    initial_errors,
    lower_limit = NULL,
    time_step_minutes = 15
) {
  input <- as_data_table_copy(data)
  required_columns <- c(time_column, simulated_column)

  if (any(!required_columns %in% names(input))) {
    stop_bad_argument("The input lacks required columns.")
  }

  forecast_index <- if (
    is.numeric(forecast_time) &&
      length(forecast_time) == 1L
  ) {
    as.integer(forecast_time)
  } else {
    match(forecast_time, input[[time_column]])
  }

  projected <- forecast_ar(
    parameters,
    initial_errors = initial_errors,
    steps = nrow(input) - forecast_index + 1L,
    time_step_minutes = time_step_minutes
  )

  aligned <- align_ar_forecast(
    forecast = projected,
    time = input[[time_column]],
    forecast_time = forecast_index
  )

  result <- data.table::data.table(
    date_time = input[[time_column]],
    simulated = input[[simulated_column]],
    ar_error = aligned$ar_error,
    period_type = aligned$period_type
  )

  result[
    ,
    updated_unconstrained := simulated + ar_error
  ]

  result[
    ,
    updated := if (is.null(lower_limit)) {
      updated_unconstrained
    } else {
      pmax(updated_unconstrained, lower_limit)
    }
  ]

  result[
    ,
    was_limited := !is.na(updated) &
      !is.na(updated_unconstrained) &
      updated != updated_unconstrained
  ]

  result[]
}
