# ============================================================ #
# Tool:         Event Triggered AR Forecast
# Description:  Run the ET-AR recurrence, switching once from steady to
#               event parameters when the configured trigger is met, and
#               retaining recurrence state across the switch.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-01
# Modified:     2026-10-02 - JP: added mandatory governance header block;
#               series now built with rbindlist() instead of rbind(); gave
#               et_ar_series() a runnable example.
# Tier:         2
# Inputs:       An et_ar_configuration, recent initial errors matching AR
#               order, and a simulated projection horizon.
# Outputs:      et_ar_forecast objects containing an auditable row-level
#               data.table.
# Dependencies: data.table.
# ============================================================ #

trigger_at_step <- function(trigger, step, previous_updated = NA_real_) {
  if (trigger$type %in% c("logical", "rainfall_accumulation", "cwi_adjusted_rainfall")) {
    if (step > nrow(trigger$data)) stop("Trigger series is shorter than the forecast.", call. = FALSE)
    return(isTRUE(trigger$data$triggered[step]))
  }
  if (trigger$type == "updated_threshold") {
    value <- if (step == 1L && !is.null(trigger$settings$initial_value)) trigger$settings$initial_value else previous_updated
    if (is.na(value)) return(FALSE)
    if (trigger$settings$direction == "above") return(value >= trigger$settings$threshold)
    return(value <= trigger$settings$threshold)
  }
  stop("Unsupported trigger type.", call. = FALSE)
}
trigger_evidence_at_step <- function(trigger, step, previous_updated = NA_real_) {
  if (trigger$type == "rainfall_accumulation" || trigger$type == "cwi_adjusted_rainfall") return(trigger$data$accumulated_rainfall[step])
  if (trigger$type == "logical") return(trigger$data$evidence[step])
  previous_updated
}

#' Forecast an Event Triggered AR update
#'
#' Begin with steady-condition parameters and switch once to event-condition
#' parameters when the configured trigger is met. The recurrence state is
#' retained across the switch, so the error series remains continuous.
#' @param configuration An object from [et_ar_configuration()].
#' @param initial_errors Recent observed-minus-simulated errors, newest first.
#'   Length must equal the shared AR order.
#' @param simulated Numeric simulated values for the full projection horizon.
#' @param time Optional timestamps or lead values matching `simulated`.
#' @param lower_limit Optional lower bound applied to displayed updates.
#' @param time_step_minutes Minutes represented by one step.
#' @returns An object of class `et_ar_forecast`. Use [et_ar_series()] to extract
#'   its auditable row-level table.
#' @examples
#' config <- et_ar_configuration(
#'   default_et_ar_steady_parameters(), event_ar_parameters(48),
#'   logical_et_trigger(c(FALSE, FALSE, TRUE, rep(TRUE, 9)))
#' )
#' result <- forecast_et_ar(
#'   config, initial_errors = c(0.2, 0.18, 0.16), simulated = rep(1, 12)
#' )
#' et_ar_series(result)
#' @export
forecast_et_ar <- function(configuration, initial_errors, simulated, time = seq_along(simulated), lower_limit = NULL, time_step_minutes = 15) {
  if (!inherits(configuration, "et_ar_configuration")) stop("Invalid ET-AR configuration.", call. = FALSE)
  p <- configuration$steady_parameters@order
  if (length(initial_errors) != p || anyNA(initial_errors)) stop("`initial_errors` must be complete and match AR order.", call. = FALSE)
  if (!is.numeric(simulated) || anyNA(simulated)) stop("`simulated` must be numeric and complete.", call. = FALSE)
  if (length(time) != length(simulated)) stop("`time` must match `simulated`.", call. = FALSE)
  state <- as.numeric(initial_errors); switched <- FALSE; switch_step <- NA_integer_
  output <- vector("list", length(simulated)); previous_updated <- NA_real_
  for (i in seq_along(simulated)) {
    trigger_now <- !switched && trigger_at_step(configuration$trigger, i, previous_updated)
    if (trigger_now) { switched <- TRUE; switch_step <- i }
    parameters <- if (switched) configuration$event_parameters else configuration$steady_parameters
    error <- sum(parameters@coefficients * state)
    unconstrained <- simulated[i] + error
    updated <- if (is.null(lower_limit)) unconstrained else max(lower_limit, unconstrained)
    output[[i]] <- data.table::data.table(
      step = i, time = time[i], lead_time_minutes = i * time_step_minutes,
      simulated = simulated[i], ar_error = error,
      updated_unconstrained = unconstrained, updated = updated,
      parameter_state = if (switched) "event" else "steady",
      trigger_type = configuration$trigger$type,
      trigger_evidence = trigger_evidence_at_step(configuration$trigger, i, previous_updated),
      triggered_this_step = trigger_now, switch_step = switch_step
    )
    state <- if (p == 1L) error else c(error, state[-p]); previous_updated <- updated
  }
  structure(list(configuration = configuration, initial_errors = initial_errors, series = data.table::rbindlist(output), switch_step = switch_step), class = "et_ar_forecast")
}

#' Extract an ET-AR forecast series
#' @param x An object returned by [forecast_et_ar()] or [forecast_et_tj_ar()].
#' @returns A copied `data.table` containing trigger evidence, parameter state,
#'   error projection and updated values.
#' @examples
#' config <- et_ar_configuration(
#'   default_et_ar_steady_parameters(), event_ar_parameters(48),
#'   logical_et_trigger(c(FALSE, FALSE, TRUE, rep(TRUE, 9)))
#' )
#' result <- forecast_et_ar(
#'   config, initial_errors = c(0.2, 0.18, 0.16), simulated = rep(1, 12)
#' )
#' et_ar_series(result)
#' @export
et_ar_series <- function(x) data.table::copy(x$series)
