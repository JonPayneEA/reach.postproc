# ============================================================ #
# Tool:         Event Triggered AR Configuration
# Description:  Pair steady- and event-condition AR parameter sets with a
#               trigger definition, and construct the EA default steady and
#               response-time-derived event parameter sets.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-01
# Modified:     2026-10-02 - JP: added mandatory governance header block
# Tier:         2
# Inputs:       Two AR parameter sets of equal order and an et_ar_trigger
#               object.
# Outputs:      An et_ar_configuration object consumed by forecast_et_ar()
#               and forecast_et_tj_ar().
# Dependencies: none beyond base R (uses ar_parameters_from_timescales()
#               from 03-parameters.R).
# ============================================================ #

#' Construct an Event Triggered AR configuration
#'
#' Pair the steady-condition and event-condition AR parameter sets with one
#' trigger definition. Forecasts begin with `steady_parameters` and switch once
#' to `event_parameters` when the trigger first becomes true. They do not switch
#' back within the same forecast.
#'
#' @param steady_parameters An AR parameter set created by [ar_parameters()] or
#'   [ar_parameters_from_timescales()]. It should have a long principal decay
#'   time suitable for slowly changing errors under steady conditions.
#' @param event_parameters An AR parameter set with the same AR order as
#'   `steady_parameters`. Its principal decay time should reflect the catchment
#'   response time under event conditions.
#' @param trigger A trigger object created by [logical_et_trigger()],
#'   [rainfall_accumulation_trigger()], [updated_threshold_trigger()] or
#'   [cwi_adjusted_rainfall_trigger()].
#' @param label A short character description retained in the result metadata.
#' @param metadata A named list containing identifiers and provenance, such as
#'   site, model version, response-time source, calibration date and reviewer.
#'
#' @returns An object of class `et_ar_configuration`.
#'
#' @examples
#' steady <- ar_parameters_from_timescales(
#'   decay_times = c(Inf, 5.203171, 1 / 3),
#'   oscillation_periods = c(Inf, Inf, 2)
#' )
#' event <- ar_parameters_from_timescales(
#'   decay_times = c(48, 5.203171, 1 / 3),
#'   oscillation_periods = c(Inf, Inf, 2)
#' )
#' trigger <- logical_et_trigger(c(FALSE, FALSE, TRUE, TRUE))
#' config <- et_ar_configuration(steady, event, trigger)
#' @export
et_ar_configuration <- function(
    steady_parameters,
    event_parameters,
    trigger,
    label = "ET-AR configuration",
    metadata = list()
) {
  if (!inherits(trigger, "et_ar_trigger")) {
    stop("`trigger` must be created by an ET-AR trigger constructor.", call. = FALSE)
  }
  if (steady_parameters@order != event_parameters@order) {
    stop("Steady and event parameter sets must have the same AR order.", call. = FALSE)
  }
  structure(
    list(
      steady_parameters = steady_parameters,
      event_parameters = event_parameters,
      trigger = trigger,
      label = as.character(label)[1L],
      metadata = metadata
    ),
    class = "et_ar_configuration"
  )
}

#' Default steady-condition parameters for ET-AR
#'
#' Construct the Part 2 steady-condition AR(3) parameters with an infinite
#' principal decay time and the established middle and fast root behaviour.
#'
#' @param label Description attached to the parameter set.
#' @returns An AR parameter object.
#' @examples
#' steady <- default_et_ar_steady_parameters()
#' root_table(roots(steady))
#' @export
default_et_ar_steady_parameters <- function(
    label = "ET-AR steady parameters: infinite principal decay"
) {
  ar_parameters(
    coefficients = c(1.765, -0.7244342, -0.04056586),
    sign_convention = "Deltares",
    label = label
  )
}

#' Construct ET-AR event parameters from catchment response time
#'
#' Retain the standard middle and fast roots while setting the principal decay
#' time from a catchment response estimate.
#'
#' @param response_time_steps Positive response time in model timesteps. For a
#'   15-minute model, 48 steps represent 12 hours.
#' @param middle_decay_steps Decay time of the intermediate positive root.
#' @param fast_decay_steps Decay time of the rapid negative root.
#' @param label Description attached to the result.
#' @returns An AR(3) parameter object.
#' @examples
#' event <- event_ar_parameters(response_time_steps = 48)
#' root_table(roots(event, time_step_minutes = 15))
#' @export
event_ar_parameters <- function(
    response_time_steps,
    middle_decay_steps = 5.203171,
    fast_decay_steps = 1 / 3,
    label = "ET-AR event parameters"
) {
  if (length(response_time_steps) != 1L || !is.finite(response_time_steps) ||
      response_time_steps <= 0) {
    stop("`response_time_steps` must be one positive finite value.", call. = FALSE)
  }
  ar_parameters_from_timescales(
    decay_times = c(response_time_steps, middle_decay_steps, fast_decay_steps),
    oscillation_periods = c(Inf, Inf, 2),
    label = label
  )
}
