# ============================================================ #
# Tool:         Single-Origin AR Update
# Description:  Project one continuous AR update forward from a single
#               forecast origin to the end of an aligned series, and plot
#               it against the observed and simulated hydrograph.
# Flode Module: reach.hydro (candidate; not yet promoted)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-05
# Modified:     2026-10-05 - JP: first draft, ported from a team member's
#               standalone visualisation script. That script pulled its own
#               series directly from the WISKI API via riskyData -- out of
#               scope here, since reach.postproc starts from prepared series
#               and leaves data ingestion to reach.io (see README "Scope").
#               This covers only the part downstream of that pull: given an
#               aligned observed/simulated series, project one AR update
#               forward from a chosen origin and visualise it.
#               This is deliberately not the same thing as fixed_lead_ar():
#               fixed_lead_ar() reconstructs, retrospectively, what the
#               update would have said at every timestep had a forecast
#               always been issued a fixed lead time earlier -- it is a
#               skill-scoring tool. This function issues exactly one
#               forecast, from exactly one origin, and lets it run forward
#               to the end of the series -- closer to what an operational
#               forecaster actually sees at a single point in time.
# Tier:         1 (experimental; new, not yet operationally reviewed)
# Inputs:       An AR parameter set, an aligned observed/simulated series,
#               and a single forecast origin (a row index or a date-time).
# Outputs:      A date-indexed data.table covering the whole series, with
#               the AR update filled in from the origin onward and NA
#               before it; and a ggplot2 comparison of observed, simulated
#               and updated values.
# Dependencies: data.table, ggplot2.
# ============================================================ #

#' Project a single AR update forward from one forecast origin
#'
#' Seed the AR recurrence from the real errors immediately before a chosen
#' origin, then project it forward continuously to the end of the supplied
#' series -- one forecast, issued once, rather than a retrospective,
#' every-timestep reconstruction. Compare with [fixed_lead_ar()], which
#' answers a different question (see Details).
#'
#' @details This is not a replacement for [fixed_lead_ar()]. `fixed_lead_ar()`
#'   reconstructs what a fixed-lead update would have said at *every*
#'   timestep, for scoring. `single_origin_ar_update()` issues exactly
#'   *one* forecast, at exactly *one* origin, and lets the AR recurrence run
#'   forward uninterrupted to the end of the data -- closer to what an
#'   operational forecaster actually sees: one update, right now, projected
#'   as far forward as the series goes. Rows before the origin are returned
#'   with `NA` in the update columns; nothing is retrospectively
#'   reconstructed for them.
#'
#' @param parameters An AR parameter object.
#' @param data An aligned-series result from [align_forecast_series()], or a
#'   table with `date_time`, `observed` and `simulated` columns.
#' @param origin The forecast origin: either a single `POSIXct` matching one
#'   row of `data`'s `date_time` column, or a single positive integer row
#'   index. This is the first row the projection fills in; the `order`
#'   rows immediately before it supply the seed errors (observed minus
#'   simulated), newest first, exactly as `initial_errors` is supplied
#'   elsewhere in this package.
#' @param lower_limit Optional scalar lower bound applied to the displayed
#'   update, as in [apply_ar_update()].
#' @param time_step_minutes Minutes represented by one model timestep.
#'
#' @returns A `data.table` with one row per row of `data`: `date_time`,
#'   `observed`, `simulated`, `ar_error`, `updated_unconstrained` and
#'   `updated`. The last three are `NA` before `origin`. Carries
#'   `origin_index`, `origin_date_time` and `initial_errors` as attributes
#'   (provenance for this call's own output only, as elsewhere in this
#'   package -- they do not survive the table being reconstructed
#'   elsewhere).
#'
#' @seealso [fixed_lead_ar()] for retrospective, every-timestep scoring,
#'   [forecast_ar()], [apply_ar_update()], [plot_single_origin_update()]
#'
#' @examples
#' time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:40 * 900
#' simulation <- 0.8 + sin(0:40 / 12)
#' observation <- simulation + c(rep(0.1, 20), rep(0.05, 21))
#'
#' aligned <- align_forecast_series(
#'   data.frame(date_time = time, value = observation),
#'   data.frame(date_time = time, value = simulation),
#'   interval_minutes = 15
#' )
#'
#' result <- single_origin_ar_update(
#'   default_ar_parameters(), aligned, origin = 21L
#' )
#' tail(result)
#' @export
single_origin_ar_update <- function(parameters,
                                     data,
                                     origin,
                                     lower_limit = NULL,
                                     time_step_minutes = 15) {
  d <- if (S7::S7_inherits(data, AlignedForecastSeries)) {
    data.table::copy(data@series)
  } else {
    as_dt_copy(data)
  }
  if (!all(c("date_time", "observed", "simulated") %in% names(d))) {
    stop_bad_argument("`data` must contain date_time, observed and simulated columns.")
  }

  origin_index <- if (inherits(origin, "POSIXct")) {
    matched <- which(d$date_time == origin)
    if (length(matched) != 1L) {
      stop_bad_argument("`origin` must match exactly one row of `data`'s date_time column.")
    }
    matched
  } else if (is.numeric(origin) && length(origin) == 1L) {
    idx <- as.integer(origin)
    if (is.na(idx) || idx < 1L || idx > nrow(d)) {
      stop_bad_argument("`origin` row index is out of range for `data`.")
    }
    idx
  } else {
    stop_bad_argument("`origin` must be one POSIXct date-time or one row index.")
  }

  # The seed needs `order` real rows strictly before the origin -- the same
  # requirement forecast_ar()'s initial_errors always carries, just derived
  # here from the aligned series instead of being typed in by hand.
  if (origin_index <= parameters@order) {
    stop_bad_argument(sprintf(
      "`origin` is row %d, leaving fewer than the %d prior rows the AR order %d seed needs.",
      origin_index, parameters@order, parameters@order
    ))
  }

  errors <- d$observed - d$simulated
  seed_index <- (origin_index - 1L):(origin_index - parameters@order) # newest first
  initial_errors <- errors[seed_index]
  if (anyNA(initial_errors)) {
    stop_bad_argument(
      "The errors immediately before `origin` contain missing values; cannot seed the AR recurrence."
    )
  }

  tail_rows <- origin_index:nrow(d)
  projection <- forecast_ar(
    parameters,
    initial_errors = initial_errors,
    steps = length(tail_rows),
    time_step_minutes = time_step_minutes
  )
  applied <- apply_ar_update(
    simulated = d$simulated[tail_rows],
    ar_error = projection@series$ar_error,
    lower_limit = lower_limit,
    time = d$date_time[tail_rows]
  )

  result <- data.table::data.table(
    date_time = d$date_time,
    observed = d$observed,
    simulated = d$simulated,
    ar_error = NA_real_,
    updated_unconstrained = NA_real_,
    updated = NA_real_
  )
  result[
    tail_rows,
    c("ar_error", "updated_unconstrained", "updated") := list(
      applied$ar_error, applied$updated_unconstrained, applied$updated
    )
  ]

  attr(result, "origin_index") <- origin_index
  attr(result, "origin_date_time") <- d$date_time[origin_index]
  attr(result, "initial_errors") <- initial_errors
  result
}

#' Plot a single-origin AR update against observed and simulated series
#'
#' Overlay observed, simulated and updated values on one time axis, with a
#' marker at the forecast origin.
#'
#' @param x A result from [single_origin_ar_update()].
#' @param include_ar_error Logical. If `TRUE`, also draw the raw AR
#'   correction (`ar_error`) as a dotted line. Default `FALSE`: the
#'   correction is usually a much smaller magnitude than `observed`,
#'   `simulated` and `updated`, and crowds the same axis badly.
#'
#' @returns A `ggplot` object.
#'
#' @seealso [single_origin_ar_update()]
#'
#' @examples
#' time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:40 * 900
#' simulation <- 0.8 + sin(0:40 / 12)
#' observation <- simulation + c(rep(0.1, 20), rep(0.05, 21))
#' aligned <- align_forecast_series(
#'   data.frame(date_time = time, value = observation),
#'   data.frame(date_time = time, value = simulation),
#'   interval_minutes = 15
#' )
#' result <- single_origin_ar_update(default_ar_parameters(), aligned, origin = 21L)
#' plot_single_origin_update(result)
#' @export
plot_single_origin_update <- function(x, include_ar_error = FALSE) {
  required_columns <- c("date_time", "observed", "simulated", "updated")
  if (!data.table::is.data.table(x) || !all(required_columns %in% names(x))) {
    stop_bad_argument("`x` must be the result of single_origin_ar_update().")
  }

  long <- data.table::melt(
    x[, required_columns, with = FALSE],
    id.vars = "date_time", variable.name = "series", value.name = "value"
  )
  p <- ggplot2::ggplot(long, ggplot2::aes(date_time, value, colour = series)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Date", y = "Value", colour = NULL)

  origin_date_time <- attr(x, "origin_date_time")
  if (!is.null(origin_date_time)) {
    p <- p + ggplot2::geom_vline(
      xintercept = origin_date_time, linetype = "dashed", colour = "grey40"
    )
  }
  if (include_ar_error) {
    p <- p + ggplot2::geom_line(
      data = x, ggplot2::aes(date_time, ar_error),
      colour = "grey50", linetype = "dotted", inherit.aes = FALSE
    )
  }
  p
}
