# ============================================================ #
# Tool:         Event Triggered AR Trigger Constructors
# Description:  Build logical, rainfall-accumulation, updated-threshold and
#               CWI-adjusted trigger objects, and evaluate trigger state at a
#               given forecast step.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-01
# Modified:     2026-10-02 - JP: added mandatory governance header block;
#               trigger tables now built as data.table, not data.frame.
# Tier:         2
# Inputs:       Logical series, rainfall depths, accumulation windows and
#               thresholds, or updated level/flow values.
# Outputs:      et_ar_trigger objects carrying a data.table of per-step
#               trigger evidence.
# Dependencies: data.table, utils.
# ============================================================ #

new_et_trigger <- function(type, data, settings = list()) {
  structure(list(type = type, data = data, settings = settings), class = "et_ar_trigger")
}

#' Construct an ET-AR trigger from a logical series
#'
#' Use a pre-calculated logical series when trigger evidence is prepared by an
#' external workflow. The first `TRUE` value causes the permanent parameter
#' switch.
#' @param triggered Logical vector with one value per projected timestep.
#' @param evidence Optional numeric or character vector retained for audit.
#' @param label Description of the external trigger calculation.
#' @returns An `et_ar_trigger` object.
#' @examples
#' trigger <- logical_et_trigger(c(FALSE, FALSE, TRUE, TRUE))
#' @export
logical_et_trigger <- function(triggered, evidence = NULL, label = "Supplied trigger") {
  if (!is.logical(triggered) || anyNA(triggered)) {
    stop("`triggered` must be a logical vector without missing values.", call. = FALSE)
  }
  if (!is.null(evidence) && length(evidence) != length(triggered)) {
    stop("`evidence` must have the same length as `triggered`.", call. = FALSE)
  }
  new_et_trigger(
    "logical",
    data.table::data.table(
      triggered = triggered,
      evidence = if (is.null(evidence)) rep(NA, length(triggered)) else evidence
    ),
    list(label = label)
  )
}

rolling_sum_right <- function(x, window_steps, history = numeric()) {
  all_x <- c(history, x); n_history <- length(history); out <- numeric(length(x))
  for (i in seq_along(x)) {
    end <- n_history + i; start <- max(1L, end - window_steps + 1L)
    out[i] <- sum(all_x[start:end], na.rm = FALSE)
  }
  out
}

#' Construct a rainfall-accumulation ET-AR trigger
#'
#' Switch when accumulated catchment rainfall over a moving window reaches or
#' exceeds a threshold. The window should be related to catchment response time.
#' @param rainfall Numeric forecast rainfall depth per model timestep.
#' @param window_steps Positive whole number of timesteps in the accumulation.
#' @param threshold Non-negative accumulated rainfall threshold in the same depth
#'   units as `rainfall`.
#' @param prior_rainfall Optional rainfall immediately before the forecast,
#'   supplied oldest to newest. Up to `window_steps - 1` values are relevant.
#' @param inclusive If `TRUE`, equality triggers the switch; otherwise the
#'   accumulated rainfall must exceed the threshold.
#' @param time_step_minutes Minutes per rainfall timestep, retained as metadata.
#' @returns An `et_ar_trigger` containing rainfall, accumulation and trigger state.
#' @examples
#' trigger <- rainfall_accumulation_trigger(
#'   rainfall = c(0, 1, 2, 3, 0), window_steps = 3L, threshold = 5
#' )
#' trigger$data
#' @export
rainfall_accumulation_trigger <- function(
    rainfall, window_steps, threshold, prior_rainfall = numeric(),
    inclusive = TRUE, time_step_minutes = 15
) {
  if (!is.numeric(rainfall) || anyNA(rainfall) || any(rainfall < 0)) stop("`rainfall` must be non-negative and complete.", call. = FALSE)
  window_steps <- as.integer(window_steps)
  if (length(window_steps) != 1L || is.na(window_steps) || window_steps < 1L) stop("`window_steps` must be a positive whole number.", call. = FALSE)
  if (length(threshold) != 1L || !is.finite(threshold) || threshold < 0) stop("`threshold` must be non-negative.", call. = FALSE)
  accumulation <- rolling_sum_right(rainfall, window_steps, utils::tail(prior_rainfall, window_steps - 1L))
  triggered <- if (inclusive) accumulation >= threshold else accumulation > threshold
  new_et_trigger(
    "rainfall_accumulation",
    data.table::data.table(
      step = seq_along(rainfall),
      rainfall = rainfall,
      accumulated_rainfall = accumulation,
      threshold = threshold,
      triggered = triggered
    ),
    list(window_steps = window_steps, inclusive = inclusive, time_step_minutes = time_step_minutes)
  )
}

#' Construct an updated-level or updated-flow ET-AR trigger
#'
#' Define a threshold that is evaluated within [forecast_et_ar()]. The forecast
#' switches when the previous updated value crosses the threshold. At the first
#' forecast step, `initial_value` is used when supplied.
#' @param threshold Scalar level or flow threshold in forecast units.
#' @param direction `"above"` or `"below"`.
#' @param initial_value Optional observed value at the forecast origin.
#' @param quantity Label such as `"level"` or `"flow"`.
#' @returns An `et_ar_trigger` object.
#' @examples
#' trigger <- updated_threshold_trigger(1.2, initial_value = 0.9, quantity = "level")
#' @export
updated_threshold_trigger <- function(threshold, direction = c("above", "below"), initial_value = NULL, quantity = "value") {
  direction <- match.arg(direction)
  if (length(threshold) != 1L || !is.finite(threshold)) stop("`threshold` must be finite.", call. = FALSE)
  if (!is.null(initial_value) && (length(initial_value) != 1L || !is.finite(initial_value))) stop("`initial_value` must be NULL or finite.", call. = FALSE)
  new_et_trigger("updated_threshold", data.table::data.table(), list(threshold = threshold, direction = direction, initial_value = initial_value, quantity = quantity))
}

#' Calculate the Part 2 CWI rainfall-threshold factor
#' @param cwi Numeric Catchment Wetness Index values.
#' @returns Numeric factors: one at or below 125, linearly declining to zero at
#'   165, and zero at or above 165.
#' @examples
#' cwi_rainfall_factor(c(120, 125, 145, 165, 170))
#' @export
cwi_rainfall_factor <- function(cwi) {
  if (!is.numeric(cwi) || anyNA(cwi)) stop("`cwi` must be numeric and complete.", call. = FALSE)
  ifelse(cwi <= 125, 1, ifelse(cwi >= 165, 0, (165 - cwi) / 40))
}

#' Construct a CWI-adjusted rainfall trigger
#'
#' Apply the experimental Part 2 wetness scaling to a dry-condition rainfall
#' threshold before comparing it with rolling rainfall accumulation.
#' @param rainfall,window_steps,prior_rainfall,time_step_minutes As documented by
#'   [rainfall_accumulation_trigger()].
#' @param cwi One CWI value or one value per forecast timestep.
#' @param dry_threshold Accumulated rainfall threshold at CWI 125 or below.
#' @returns An experimental `et_ar_trigger` with time-varying thresholds.
#' @examples
#' trigger <- cwi_adjusted_rainfall_trigger(
#'   rainfall = c(0, 1, 2, 3), cwi = 145,
#'   dry_threshold = 8, window_steps = 3L
#' )
#' trigger$data
#' @export
cwi_adjusted_rainfall_trigger <- function(rainfall, cwi, dry_threshold, window_steps, prior_rainfall = numeric(), time_step_minutes = 15) {
  if (length(cwi) == 1L) cwi <- rep(cwi, length(rainfall))
  if (length(cwi) != length(rainfall)) stop("`cwi` must have length one or match `rainfall`.", call. = FALSE)
  base <- rainfall_accumulation_trigger(rainfall, window_steps, dry_threshold, prior_rainfall, TRUE, time_step_minutes)
  cwi_threshold <- dry_threshold * cwi_rainfall_factor(cwi)
  base$type <- "cwi_adjusted_rainfall"
  # `..` forces these to resolve as the local variables above, not as the
  # pre-existing `threshold` column rainfall_accumulation_trigger() already
  # wrote (the dry-condition threshold, which this call replaces).
  base$data[, `:=`(
    cwi = ..cwi,
    threshold = ..cwi_threshold,
    triggered = accumulated_rainfall >= ..cwi_threshold
  )]
  base$settings$dry_threshold <- dry_threshold
  base
}
