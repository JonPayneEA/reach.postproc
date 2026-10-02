# ============================================================ #
# Tool:         Combined Event Triggered and Time Jumped AR
# Description:  Use TJ-AR to reconstruct a noise-resistant recent consecutive
#               error state, then continue with the standard ET-AR recurrence
#               and its one-way parameter switch.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-01
# Modified:     2026-10-02 - JP: added mandatory governance header block
# Tier:         2
# Inputs:       An et_ar_configuration, a complete recent error history and a
#               jump interval.
# Outputs:      An et_tj_ar_forecast object (an et_ar_forecast with TJ-AR
#               initialisation details attached).
# Dependencies: none beyond base R (built on forecast_tj_ar() and
#               forecast_et_ar()).
# ============================================================ #

#' Forecast combined Event Triggered and Time Jumped AR
#'
#' Use TJ-AR to infer a noise-resistant recent consecutive state, then continue
#' with the ET-AR recurrence and its one-way parameter switch.
#' @param configuration An ET-AR configuration.
#' @param error_history Complete recent error history supplied newest first.
#' @param jump Positive timestep separation used to select TJ-AR inputs.
#' @param simulated,time,lower_limit,time_step_minutes As in [forecast_et_ar()].
#' @returns An `et_ar_forecast` with TJ-AR initialisation details attached.
#' @examples
#' history <- seq(0.2, 0.05, length.out = 20)
#' config <- et_ar_configuration(
#'   default_et_ar_steady_parameters(), event_ar_parameters(48),
#'   logical_et_trigger(c(FALSE, FALSE, TRUE, rep(TRUE, 9)))
#' )
#' result <- forecast_et_tj_ar(config, history, jump = 5L, simulated = rep(1, 12))
#' @export
forecast_et_tj_ar <- function(configuration, error_history, jump = 1L, simulated, time = seq_along(simulated), lower_limit = NULL, time_step_minutes = 15) {
  p <- configuration$steady_parameters@order
  tj <- forecast_tj_ar(configuration$steady_parameters, error_history, jump = jump, steps = 1L, time_step_minutes = time_step_minutes)
  roots_values <- roots(configuration$steady_parameters)@values
  weights <- tj$weights$weight_real + 1i * tj$weights$weight_imaginary
  consecutive_times <- -seq_len(p)
  reconstructed <- Re(vapply(consecutive_times, function(tt) sum(weights * roots_values^tt), complex(1)))
  result <- forecast_et_ar(configuration, initial_errors = reconstructed, simulated = simulated, time = time, lower_limit = lower_limit, time_step_minutes = time_step_minutes)
  result$tj_initialisation <- list(jump = jump, selected_inputs = tj$selected_inputs, weights = tj$weights, reconstructed_consecutive_errors = reconstructed)
  class(result) <- c("et_tj_ar_forecast", class(result))
  result
}
