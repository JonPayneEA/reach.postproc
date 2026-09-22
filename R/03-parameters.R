# Parameter constructors and coefficient/root conversions.

ar_parameters <- function(..., coefficients = NULL, label = "AR parameter set") {
  dots <- unlist(list(...), recursive = TRUE, use.names = TRUE)
  if (!is.null(coefficients) && length(dots)) {
    .stop_bad("Supply parameters through `...` or `coefficients`, not both.")
  }
  values <- if (is.null(coefficients)) dots else coefficients
  .assert_numeric_vector(values, "coefficients")
  if (is.null(names(values)) || any(names(values) == "")) {
    names(values) <- paste0("a_", seq_along(values))
  }
  ARParameterSet(
    coefficients = as.numeric(values) |> stats::setNames(names(values)),
    order = as.integer(length(values)),
    label = as.character(label)
  )
}

default_ar_parameters <- function() {
  ar_parameters(
    coefficients = c(a_1 = 1.765, a_2 = -0.72625, a_3 = -0.040656),
    label = "2024 EA default"
  )
}

root_from_timescale <- function(decay_time, oscillation_period = Inf) {
  if (length(decay_time) != 1L || !is.numeric(decay_time) || is.na(decay_time) ||
      decay_time == 0) {
    .stop_bad("`decay_time` must be one non-zero numeric value.")
  }
  if (length(oscillation_period) != 1L || !is.numeric(oscillation_period) ||
      is.na(oscillation_period) || oscillation_period < 2) {
    .stop_bad("`oscillation_period` must be at least 2 or `Inf`.")
  }
  magnitude <- exp(-1 / decay_time)
  if (is.infinite(oscillation_period)) return(as.complex(magnitude))
  magnitude * exp(1i * 2 * pi / oscillation_period)
}

roots_to_parameters <- function(root_values, label = "Derived from roots", tolerance = 1e-10) {
  if ((!is.numeric(root_values) && !is.complex(root_values)) ||
      length(root_values) < 1L || anyNA(root_values)) {
    .stop_bad("`root_values` must contain non-missing numeric or complex values.")
  }
  polynomial <- as.complex(1)
  for (root_value in root_values) {
    polynomial <- .multiply_polynomials(polynomial, c(1, -root_value))
  }
  coefficients <- -polynomial[-1L]
  if (any(abs(Im(coefficients)) > tolerance)) {
    .stop_bad("The roots do not produce real AR parameters. Supply complex roots as conjugate pairs.")
  }
  values <- Re(coefficients)
  names(values) <- paste0("a_", seq_along(values))
  ar_parameters(coefficients = values, label = label)
}

ar_parameters_from_timescales <- function(decay_times, oscillation_periods = rep(Inf, length(decay_times)),
                                           label = "Derived from timescales", tolerance = 1e-10) {
  .assert_numeric_vector(decay_times, "decay_times", finite = FALSE)
  .assert_numeric_vector(oscillation_periods, "oscillation_periods", finite = FALSE)
  if (length(decay_times) != length(oscillation_periods)) {
    .stop_bad("`decay_times` and `oscillation_periods` must have equal lengths.")
  }
  root_values <- mapply(
    root_from_timescale,
    decay_time = decay_times,
    oscillation_period = oscillation_periods,
    SIMPLIFY = TRUE
  )
  roots_to_parameters(root_values, label = label, tolerance = tolerance)
}

calculate_model_error <- function(observed, simulated) {
  .assert_numeric_vector(observed, "observed", finite = FALSE)
  .assert_numeric_vector(simulated, "simulated", finite = FALSE)
  if (length(observed) != length(simulated)) {
    .stop_bad("`observed` and `simulated` must have equal lengths.")
  }
  observed - simulated
}
