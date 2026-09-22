# Full ARMA recurrence and response -------------------------------------------

#' Forecast a deterministic ARMA error series
#'
#' @param parameters AR component as an `ARParameterSet`.
#' @param initial_errors Initial AR state ordered newest first.
#' @param residuals Residual innovation at each forecast step.
#' @param ma_parameters MA coefficients ordered from `b_1` to `b_q`.
#' @param previous_residuals Initial MA state ordered newest first.
#'
#' @return A `data.table` containing AR, residual, MA and total contributions.
#'
#' @export
forecast_arma <- function(
    parameters,
    initial_errors,
    residuals,
    ma_parameters = numeric(),
    previous_residuals = numeric()
) {
  if (length(initial_errors) != parameters@order) {
    stop_bad_argument("`initial_errors` must match the AR order.")
  }

  if (length(previous_residuals) != length(ma_parameters)) {
    stop_bad_argument(
      "`previous_residuals` must match the number of MA parameters."
    )
  }

  error_state <- initial_errors
  residual_state <- previous_residuals
  output <- vector("list", length(residuals))

  for (step_index in seq_along(residuals)) {
    ar_contribution <- sum(
      parameters@coefficients * error_state
    )

    ma_contribution <- if (length(ma_parameters) > 0L) {
      sum(ma_parameters * residual_state)
    } else {
      0
    }

    innovation <- residuals[[step_index]]
    arma_error <- ar_contribution + ma_contribution + innovation

    output[[step_index]] <- data.table::data.table(
      step = step_index - 1L,
      ar_contribution = ar_contribution,
      residual_contribution = innovation,
      ma_contribution = ma_contribution,
      arma_error = arma_error
    )

    error_state <- if (parameters@order == 1L) {
      arma_error
    } else {
      c(arma_error, error_state[-parameters@order])
    }

    if (length(ma_parameters) > 0L) {
      residual_state <- if (length(ma_parameters) == 1L) {
        innovation
      } else {
        c(innovation, residual_state[-length(residual_state)])
      }
    }
  }

  data.table::rbindlist(output)
}

S7::method(response, ARParameterSet) <- function(
    x,
    ...,
    ma_parameters = numeric(),
    steps = 480L
) {
  steps <- validate_whole_number(steps, "steps", minimum = 1L)
  ma_order <- detect_ma_order(ma_parameters)

  active_ma_parameters <- if (ma_order > 0L) {
    ma_parameters[seq_len(ma_order)]
  } else {
    numeric()
  }

  residuals <- numeric(steps)
  residuals[[1L]] <- 1

  series <- forecast_arma(
    parameters = x,
    initial_errors = numeric(x@order),
    residuals = residuals,
    ma_parameters = active_ma_parameters,
    previous_residuals = numeric(length(active_ma_parameters))
  )

  ARMAResponse(
    parameters = x,
    ma_parameters = active_ma_parameters,
    series = series
  )
}

#' Compare AR, MA and ARMA response components
#'
#' @param parameters AR component as an `ARParameterSet`.
#' @param ma_parameters Numeric MA coefficients.
#' @param steps Number of response steps.
#' @param order_tolerance Tolerance used to trim trailing MA terms.
#'
#' @return Long-format `data.table` with `AR`, `MA` and `ARMA` components.
#'
#' @export
response_components <- function(
    parameters,
    ma_parameters = numeric(),
    steps = 480L,
    order_tolerance = 1e-8
) {
  ma_order <- detect_ma_order(
    coefficients = ma_parameters,
    tolerance = order_tolerance
  )

  active_ma_parameters <- if (ma_order > 0L) {
    ma_parameters[seq_len(ma_order)]
  } else {
    numeric()
  }

  ar_component <- response(
    parameters,
    steps = steps
  )@series[
    ,
    .(
      step,
      response = arma_error,
      component = "AR"
    )
  ]

  ma_component <- data.table::data.table(
    step = 0:(steps - 1L),
    response = 0,
    component = "MA"
  )

  ma_component[1L, response := 1]

  if (ma_order > 0L) {
    ma_component[
      2:(ma_order + 1L),
      response := active_ma_parameters
    ]
  }

  arma_component <- response(
    parameters,
    ma_parameters = active_ma_parameters,
    steps = steps
  )@series[
    ,
    .(
      step,
      response = arma_error,
      component = "ARMA"
    )
  ]

  data.table::rbindlist(
    list(
      ar_component,
      ma_component,
      arma_component
    )
  )
}
