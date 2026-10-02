# ============================================================ #
# Tool:         Event-Pooled AR Fitting
# Description:  Fit AR coefficients directly from a set of event windows,
#               via weighted least squares across all of them at once,
#               with event boundaries respected by construction.
# Flode Module: reach.hydro (candidate; not yet promoted)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-02
# Modified:     2026-10-02 - JP: first draft. This is a deliberate, narrow
#               exception to this package's standing design: everywhere
#               else, reach.postproc has no AR estimator of its own and
#               consumes coefficients fitted externally (by PT). PT fits
#               across a model's full residual record, with no way to
#               restrict to events, so normal- and low-flow behaviour
#               (including periods a hydraulic model's own minimum-flow
#               floor has corrupted -- see
#               setting-parameters-for-a-new-model.Rmd) contributes to the
#               calibration of an AR model meant to correct flood events
#               specifically. This function exists only to cover that one
#               gap: fitting an AR model from event windows alone,
#               transparently, inside the package whose maths is meant to
#               be reviewable. It is not a general replacement for PT.
# Tier:         1 (experimental; new, not yet operationally reviewed)
# Inputs:       A list of per-event residual series (numeric, chronological
#               oldest-first, one vector per event) and an AR order.
# Outputs:      An ARParameterSet (Deltares convention), with per-event
#               fit diagnostics attached so the fit's own assumptions can
#               be checked, not just trusted.
# Dependencies: data.table, stats.
# ============================================================ #

#' Fit AR coefficients by pooling weighted least squares across events
#'
#' Estimate AR coefficients directly from a set of event windows, rather
#' than from a model's full continuous residual record. Each event
#' contributes its own lagged regression rows; no row is ever built from
#' values spanning two different events, so events can be any length,
#' from any dates, with gaps of any size between them -- unlike naively
#' concatenating events into one long series, which would invent a false
#' "this timestep immediately preceded that one" relationship at every
#' event boundary and corrupt exactly the autocorrelation structure being
#' estimated.
#'
#' @section Why this exists: Performance Testing (PT) fits AR coefficients
#'   from a model's full residual record, with no way to restrict that fit
#'   to events. For a package whose correction is meant to matter during
#'   floods, letting ordinary and low-flow behaviour shape the fit is a
#'   real cost, compounded by anything a hydraulic model's own minimum-flow
#'   floor has corrupted in that record (see
#'   `vignette("setting-parameters-for-a-new-model")`). This function is a
#'   narrow, deliberate exception to reach.postproc otherwise having no AR
#'   estimator of its own: it exists specifically to let event-only
#'   calibration happen transparently, inside a package whose mathematics
#'   is meant to be reviewed, rather than by working around PT's
#'   limitation from the outside.
#'
#' @section Choosing a weighting scheme: `"variance"` (the default) weights
#'   each event's rows by `1 / (n_rows * variance)`, so an event's
#'   influence on the fit depends on neither how long it is nor how large
#'   its own errors happen to be -- every event ends up contributing
#'   equally. `"equal_event"` weights only by `1 / n_rows`, equalising each
#'   event's vote by row count alone; this sounds like it should prevent
#'   one event from dominating, but does not protect against a single
#'   much-larger-magnitude event pulling the fit toward itself, since
#'   squared residuals amplify a scale difference faster than a row-count
#'   weight can cancel it out. `"none"` applies no weighting at all: every
#'   row counts equally regardless of which event it came from, so long or
#'   large events dominate by construction. Checked numerically before
#'   this function was written: a single tenfold-larger, atypical event
#'   among otherwise-similar events pulled an unweighted fit almost
#'   entirely onto its own (wrong, for the other 19) coefficients, and
#'   `"equal_event"` weighting barely helped; only `"variance"` kept the
#'   fit close to the coefficients the typical events actually shared.
#'
#' @param events A named or unnamed list of numeric vectors, one per
#'   event. Each vector is that event's residual (observed-minus-simulated)
#'   series in chronological order, oldest first -- the opposite of
#'   `initial_errors` elsewhere in this package, which is always supplied
#'   newest first for seeding a live recurrence. This function is fitting
#'   from history, not projecting from a forecast origin, so it reads
#'   history the way it naturally occurs. Each event must be complete
#'   (no `NA`) and longer than `order`.
#' @param order Positive whole number AR order to fit. Default `3L`,
#'   matching this package's usual default order; `assess()`'s
#'   `permitted_orders` still governs what counts as acceptable once
#'   fitted, exactly as for every other construction path.
#' @param weighting One of `"variance"` (default), `"equal_event"` or
#'   `"none"`. See the Details above.
#' @param label Description attached to the returned parameter set.
#'
#' @returns An AR parameter object in Deltares convention, exactly like
#'   every other construction path in this package, so it composes
#'   directly with [roots()], [assess()], [forecast_ar()] and the fixed
#'   lead-time functions. Carries fit diagnostics as attributes:
#'   `fit_weighting`, `fit_total_rows`, `fit_n_events`, `fit_residual_se`
#'   and `fit_per_event` (a `data.table` of each event's row count,
#'   variance and realised weight share, so a fit dominated by one event
#'   is visible rather than silently trusted). As with
#'   [default_family_ar_parameters()]'s attributes, these are provenance
#'   for this call's own output, not part of the `ARParameterSet`
#'   contract -- they will not survive the object being reconstructed
#'   elsewhere in the package. Recompute from `parameters@coefficients`
#'   after any such transformation.
#'
#' @seealso [ar_parameters()], [assess()], [fixed_lead_ar()],
#'   `vignette("setting-parameters-for-a-new-model")`,
#'   `vignette("event-pooled-ar-fitting")`
#'
#' @examples
#' set.seed(1)
#' simulate_event <- function(n, a1 = 1.2, a2 = -0.45) {
#'   x <- numeric(n + 20)
#'   for (t in 3:(n + 20)) {
#'     x[t] <- a1 * x[t - 1] + a2 * x[t - 2] + rnorm(1)
#'   }
#'   x[-(1:20)]
#' }
#' events <- list(
#'   flood_2019 = simulate_event(40),
#'   flood_2020 = simulate_event(25),
#'   flood_2021 = simulate_event(60)
#' )
#' fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")
#' fitted@coefficients
#' attr(fitted, "fit_per_event")
#' @export
fit_ar_from_events <- function(events,
                                order = 3L,
                                weighting = c("variance", "equal_event", "none"),
                                label = "Event-pooled AR fit") {
  weighting <- match.arg(weighting)

  if (!is.list(events) || !length(events)) {
    stop(
      "`events` must be a non-empty list of numeric residual vectors, one per event.",
      call. = FALSE
    )
  }
  order <- as.integer(order)
  if (length(order) != 1L || is.na(order) || order < 1L) {
    stop("`order` must be one positive whole number.", call. = FALSE)
  }

  event_labels <- names(events)
  if (is.null(event_labels)) event_labels <- rep("", length(events))
  blank <- event_labels == ""
  event_labels[blank] <- paste0("event_", which(blank))

  invalid <- vapply(
    events,
    function(e) !is.numeric(e) || anyNA(e) || length(e) <= order,
    logical(1)
  )
  if (any(invalid)) {
    stop(
      paste0(
        "Every event must be a complete numeric vector longer than `order` ",
        "(need at least order + 1 points to form one regression row). ",
        "Too short or invalid: ", paste(event_labels[invalid], collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  # Each event builds its own lagged design matrix in isolation. This is
  # the whole point: no regression row is ever built from values spanning
  # two events, so there is no false boundary-adjacency to guard against,
  # unlike concatenating events into one series first.
  rows <- lapply(events, function(e) {
    n <- length(e)
    y <- e[(order + 1L):n]
    x <- sapply(seq_len(order), function(k) e[(order - k + 1L):(n - k)])
    if (order == 1L) x <- matrix(x, ncol = 1L)
    list(x = x, y = y, n_rows = length(y), variance = stats::var(e))
  })

  if (weighting == "variance" &&
      any(vapply(rows, function(r) r$variance <= 0, logical(1)))) {
    stop(
      paste0(
        "`weighting = \"variance\"` divides by each event's own variance; ",
        "an event with (near) zero variance (a flat residual series) ",
        "cannot be weighted this way. Use weighting = \"equal_event\" or ",
        "\"none\", or exclude that event."
      ),
      call. = FALSE
    )
  }

  # Per-row weight within each event, by scheme -- see @section Choosing a
  # weighting scheme above for why "variance" is the default.
  raw_weight <- switch(
    weighting,
    variance    = vapply(rows, function(r) 1 / (r$n_rows * r$variance), numeric(1)),
    equal_event = vapply(rows, function(r) 1 / r$n_rows, numeric(1)),
    none        = vapply(rows, function(r) 1, numeric(1))
  )

  x_all <- do.call(rbind, lapply(rows, `[[`, "x"))
  y_all <- unlist(lapply(rows, `[[`, "y"))
  w_all <- unlist(mapply(
    function(r, w) rep(w, r$n_rows),
    rows, raw_weight,
    SIMPLIFY = FALSE
  ))

  # lm.wfit(), not lm(): no automatic intercept, matching the AR recurrence
  # having no constant term, and direct matrix input rather than building
  # a formula programmatically for an arbitrary order.
  fit <- stats::lm.wfit(x = x_all, y = y_all, w = w_all)
  coefficients <- unname(fit$coefficients)
  names(coefficients) <- paste0("a_", seq_len(order))

  total_weight <- vapply(
    seq_along(rows),
    function(i) rows[[i]]$n_rows * raw_weight[i],
    numeric(1)
  )
  per_event <- data.table::data.table(
    event         = event_labels,
    n_timesteps   = vapply(events, length, integer(1)),
    n_rows        = vapply(rows, `[[`, integer(1), "n_rows"),
    variance      = vapply(rows, `[[`, numeric(1), "variance"),
    weight_share  = total_weight / sum(total_weight)
  )

  # Fitted directly as phi_t = a_1*e_{t-1} + ... + a_p*e_{t-p}, the same
  # additive, positively-signed form the Deltares recurrence already uses
  # -- so the raw regression coefficients ARE the Deltares a_1..a_p
  # coefficients, with no sign conversion needed.
  parameters <- ar_parameters(coefficients, sign_convention = "Deltares", label = label)

  attr(parameters, "fit_weighting")    <- weighting
  attr(parameters, "fit_total_rows")   <- nrow(x_all)
  attr(parameters, "fit_n_events")     <- length(events)
  attr(parameters, "fit_residual_se")  <- sqrt(sum(w_all * fit$residuals^2) / (nrow(x_all) - order))
  attr(parameters, "fit_per_event")    <- per_event

  parameters
}
