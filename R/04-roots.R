# Characteristic-root calculations and descriptions.

S7::method(roots, ARParameterSet) <- function(x, ..., time_step_minutes = 15,
                                               tolerance = sqrt(.Machine$double.eps)) {
  if (length(time_step_minutes) != 1L || !is.numeric(time_step_minutes) ||
      is.na(time_step_minutes) || !is.finite(time_step_minutes) || time_step_minutes <= 0) {
    .stop_bad("`time_step_minutes` must be one positive finite value.")
  }
  polynomial_coefficients <- c(-rev(x@coefficients), 1)
  values <- polyroot(polynomial_coefficients)
  modulus <- Mod(values)
  angle <- Arg(values)
  decay <- -1 / log(modulus)
  effectively_real <- abs(Im(values)) <= tolerance
  positive_real <- effectively_real & Re(values) >= 0
  negative_real <- effectively_real & Re(values) < 0
  period <- rep(NA_real_, length(values))
  period[positive_real] <- Inf
  period[negative_real] <- 2
  period[!effectively_real] <- 2 * pi / abs(angle[!effectively_real])
  table <- data.table::data.table(
    root_number = seq_along(values),
    root_real = Re(values),
    root_imaginary = Im(values),
    root_modulus = modulus,
    decay_time_steps = decay,
    decay_time_hours = decay * time_step_minutes / 60,
    oscillation_period_steps = period,
    oscillation_period_hours = period * time_step_minutes / 60,
    is_growing = modulus > 1 + tolerance,
    is_oscillating = is.finite(period)
  )
  data.table::setorder(table, -decay_time_steps)
  table[, root_number := seq_len(.N)]
  CharacteristicRoots(
    parameters = x,
    values = as.complex(values),
    table = table,
    time_step_minutes = as.numeric(time_step_minutes)
  )
}

effective_decay_time <- function(decay_time, oscillation_period) {
  if (length(decay_time) != 1L || !is.numeric(decay_time) || is.na(decay_time) ||
      !is.finite(decay_time) || decay_time <= 0) {
    .stop_bad("`decay_time` must be one positive finite value.")
  }
  if (length(oscillation_period) != 1L || !is.numeric(oscillation_period) ||
      is.na(oscillation_period) || oscillation_period < 2) {
    .stop_bad("`oscillation_period` must be at least 2 or `Inf`.")
  }
  if (is.infinite(oscillation_period)) return(decay_time)
  objective <- function(time) {
    exp(-time / decay_time) * cos(2 * pi * time / oscillation_period) - exp(-1)
  }
  upper <- min(decay_time, oscillation_period / 4)
  stats::uniroot(objective, c(0, upper))$root
}
