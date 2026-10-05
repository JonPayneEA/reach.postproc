# ============================================================ #
# Tool:         FEH Catchment Response Timescales
# Description:  Estimate FEH time-to-peak and lag from catchment descriptors,
#               for use as a defensible principal-decay or time-to-peak
#               estimate elsewhere in the package, rather than a guess.
# Flode Module: reach.hydro (candidate; not yet promoted)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-05
# Modified:     2026-10-05 - JP: first draft, ported from a team member's
#               standalone analysis script. response_time_steps_from_tp()'s
#               own documentation has flagged, since it was written, that it
#               "belongs in reach.hydro once that module has a proper FEH or
#               unit-hydrograph time-to-peak calculation to draw on" -- this
#               is that calculation. It does not change
#               response_time_steps_from_tp() or event_ar_parameters(); it
#               only gives their time_to_peak argument a defensible source
#               instead of a guess. The time-to-peak/AR-decay-time
#               approximation those functions make is unchanged and remains
#               exactly as provisional as before.
# Tier:         2
# Inputs:       FEH catchment descriptors (PROPWET, DPLBAR, DPSBAR, URBEXT).
# Outputs:      Time-to-peak and lag, in hours.
# Dependencies: none beyond base R.
# ============================================================ #

#' Estimate FEH time-to-peak from catchment descriptors
#'
#' Calculate the FEH (Flood Estimation Handbook) rainfall-runoff model's
#' time-to-peak from standard catchment descriptors. This is a plain
#' implementation of the published FEH regression equation; it does not
#' fit or recalibrate anything, and it does not know which descriptor
#' source (FEH webservice, CD-ROM, or a bespoke catchment analysis) the
#' values came from -- that provenance is the caller's responsibility to
#' record.
#'
#' @section Relationship to this package's AR functions: `reach.postproc`
#'   has no time-to-peak calculation of its own; [response_time_steps_from_tp()]
#'   takes a time-to-peak as given and converts it to model timesteps,
#'   deliberately leaving the question of *where that number comes from* to
#'   the caller. This function is one defensible answer to that question,
#'   for a catchment with FEH descriptors available. It does not make
#'   [response_time_steps_from_tp()]'s own time-to-peak/AR-decay-time
#'   approximation any less of an approximation -- see that function's
#'   documentation -- it only replaces a guessed input with a traceable,
#'   standard one.
#'
#' @param propwet Catchment PROPWET descriptor (proportion of time soil is
#'   wet), a positive proportion.
#' @param dplbar Catchment DPLBAR descriptor (mean drainage path length, km),
#'   positive.
#' @param dpsbar Catchment DPSBAR descriptor (mean drainage path slope,
#'   m/km), positive.
#' @param urbext Catchment URBEXT descriptor (urban extent fraction).
#'   Default `0` (no urbanisation adjustment).
#'
#' @returns One positive numeric time-to-peak, in hours.
#'
#' @seealso [feh_lag()], [response_time_steps_from_tp()]
#'
#' @examples
#' feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003)
#' @export
feh_time_to_peak <- function(propwet, dplbar, dpsbar, urbext = 0) {
  for (value in list(propwet = propwet, dplbar = dplbar, dpsbar = dpsbar)) {
    if (length(value) != 1L || !is.finite(value) || value <= 0) {
      stop("`propwet`, `dplbar` and `dpsbar` must each be one positive finite value.", call. = FALSE)
    }
  }
  if (length(urbext) != 1L || !is.finite(urbext) || urbext < 0) {
    stop("`urbext` must be one non-negative finite value.", call. = FALSE)
  }
  1.563 * propwet^(-1.09) * dplbar^0.60 * dpsbar^(-0.28) * (1 + urbext)^(-3.34)
}

#' Estimate FEH lag from time-to-peak
#'
#' Convert an FEH time-to-peak into the corresponding FEH lag, via the
#' published regression relationship between the two.
#'
#' @param time_to_peak Positive numeric time-to-peak, in hours (as returned
#'   by [feh_time_to_peak()]).
#'
#' @returns One positive numeric lag, in hours.
#'
#' @seealso [feh_time_to_peak()]
#'
#' @examples
#' feh_lag(2.085080)
#' @export
feh_lag <- function(time_to_peak) {
  if (length(time_to_peak) != 1L || !is.finite(time_to_peak) || time_to_peak <= 0) {
    stop("`time_to_peak` must be one positive finite value.", call. = FALSE)
  }
  (time_to_peak / 0.879)^(1 / 0.951)
}
