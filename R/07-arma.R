# Full ARMA recurrence and impulse response.

forecast_arma <- function(parameters, initial_errors, residuals,
                          ma_parameters = numeric(), previous_residuals = numeric()) {
  if (!S7::S7_inherits(parameters, ARParameterSet)) {
    .stop_bad("`parameters` must be an ARParameterSet object.")
  }
  .assert_numeric_vector(initial_errors, "initial_errors")
  if (length(initial_errors) != parameters@order) {
    .stop_bad("`initial_errors` must match the AR order.")
  }
  if (!is.numeric(ma_parameters) || anyNA(ma_parameters)) {
    .stop_bad("`ma_parameters` must be a non-missing numeric vector.")
  }
  if (!is.numeric(residuals) || anyNA(residuals)) {
    .stop_bad("`residuals` must be a non-missing numeric vector.")
  }
  if (length(previous_residuals) != length(ma_parameters)) {
    .stop_bad("`previous_residuals` must contain one value per MA parameter.")
  }
  error_state <- as.numeric(initial_errors)
  residual_state <- as.numeric(previous_residuals)
  output <- vector("list", length(residuals))
  for (step_index in seq_along(residuals)) {
    ar_contribution <- sum(parameters@coefficients * error_state)
    ma_contribution <- if (length(ma_parameters)) sum(ma_parameters * residual_state) else 0
    innovation <- residuals[[step_index]]
    value <- ar_contribution + innovation + ma_contribution
    output[[step_index]] <- data.table::data.table(
      step = step_index - 1L,
      ar_contribution = ar_contribution,
      residual_contribution = innovation,
      ma_contribution = ma_contribution,
      arma_error = value
    )
    error_state <- if (parameters@order == 1L) value else c(value, error_state[-parameters@order])
    if (length(ma_parameters)) {
      residual_state <- if (length(ma_parameters) == 1L) innovation else c(innovation, residual_state[-length(ma_parameters)])
    }
  }
  data.table::rbindlist(output)
}

S7::method(response, ARParameterSet) <- function(x, ..., ma_parameters = numeric(), steps = 480L) {
  .assert_whole_number(steps, "steps", 1L)
  residuals <- numeric(as.integer(steps))
  residuals[[1L]] <- 1
  series <- forecast_arma(
    parameters = x,
    initial_errors = numeric(x@order),
    residuals = residuals,
    ma_parameters = ma_parameters,
    previous_residuals = numeric(length(ma_parameters))
  )
  ARMAResponse(
    parameters = x,
    ma_parameters = as.numeric(ma_parameters),
    series = series
  )
}
