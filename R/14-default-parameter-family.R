# ============================================================ #
# Tool:         Default Parameter Family Construction
# Description:  Construct the continuous analytical family of default AR(3)
#               parameter sets from a single principal decay timescale, and
#               expose the published standard points on that family.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-10-02
# Modified:     2026-10-02 - JP: added mandatory governance header block;
#               validated fast_period_steps (Re() was silently truncating
#               any genuinely complex request to an incorrect real value);
#               added time_step_minutes pass-through to
#               standard_family_ar_parameters() and standard_family_ar_table()
#               (previously hard-coded to 15 minutes regardless of the
#               caller's actual model timestep); added explanatory comments
#               throughout (see NEWS.md).
# Tier:         2
# Inputs:       A principal decay timescale (steps, hours or days) and the
#               model timestep; or a named standard-family label.
# Outputs:      An AR(3) parameter object (Deltares convention) with
#               provenance attributes, or a data.table catalogue of the
#               published standard set.
# Dependencies: data.table.
# ============================================================ #

#' Construct a default-family AR parameter set
#'
#' Create a third-order autoregressive parameter set from one interpretable
#' timescale: the principal decay time. The function implements the analytical
#' construction used to produce the published family of default parameter sets.
#'
#' @description
#' `default_family_ar_parameters()` calculates a continuous member of the
#' default parameter family. It does not interpolate AR coefficients between
#' rows in the published table.
#'
#' The modeller selects a principal decay time from catchment evidence, such as
#' response time, FEH lag, event analysis or a broad rapid, medium or slow
#' classification. The function then derives the characteristic roots and AR
#' coefficients deterministically.
#'
#' @details
#' A third-order AR model has three characteristic roots. Within this default
#' family:
#'
#' * the principal positive root is set from the requested decay time;
#' * the rapid negative root retains a decay time of one-third of a timestep
#'   and an oscillation period of two timesteps;
#' * the first AR coefficient is held at `1.765`;
#' * the remaining positive root is solved from the sum of the three roots.
#'
#' For principal decay time \eqn{\tau_1}, the principal modal root is
#'
#' \deqn{z_1 = \exp(-1 / \tau_1).}
#'
#' Infinite principal decay gives \eqn{z_1 = 1}. The fast root is
#'
#' \deqn{z_3 = \exp(-1 / \tau_3)\exp(2\pi i / T_3),}
#'
#' with \eqn{\tau_3 = 1/3} and \eqn{T_3 = 2} by default. Because
#' \eqn{a_1 = z_1 + z_2 + z_3}, the middle root is
#'
#' \deqn{z_2 = a_1 - z_1 - z_3.}
#'
#' The three roots are converted to Deltares AR coefficients. The published
#' default table contains selected standard points from this continuous family.
#' It supports recognition, governance and verification; it is not used for
#' interpolation.
#'
#' Coefficients should be stored at full double precision. Where coefficients
#' are transferred manually, retain at least five significant figures.
#'
#' @param principal_decay One positive number giving the desired principal
#'   decay time. Use `Inf` for a non-decaying principal root.
#' @param units Unit used by `principal_decay`: `"steps"`, `"hours"` or
#'   `"days"`.
#' @param time_step_minutes Duration of one model timestep in minutes. Current
#'   IMFS AR models normally use 15-minute timesteps.
#' @param first_coefficient Fixed first AR coefficient. The published default
#'   family uses `1.765`.
#' @param fast_decay_steps Decay time of the rapid oscillating root in model
#'   timesteps. The published family uses `1 / 3`.
#' @param fast_period_steps Oscillation period of the rapid root in timesteps.
#'   The published family uses `2`, which gives a negative real root.
#' @param label Optional description attached to the returned parameter set.
#'
#' @returns An AR parameter object in Deltares convention. Attributes record
#'   the requested principal decay, solved middle decay and modal roots.
#'
#' @seealso [standard_family_ar_parameters()], [roots()],
#'   [roots_to_parameters()], [ar_parameters_from_timescales()]
#'
#' @examples
#' nine_hour <- default_family_ar_parameters(
#'   principal_decay = 9,
#'   units = "hours"
#' )
#'
#' nine_hour@coefficients
#' root_table(roots(nine_hour, time_step_minutes = 15))
#'
#' one_day <- default_family_ar_parameters(
#'   principal_decay = 1,
#'   units = "days"
#' )
#'
#' steady <- default_family_ar_parameters(
#'   principal_decay = Inf,
#'   units = "steps"
#' )
#'
#' @export
default_family_ar_parameters <- function(
    principal_decay,
    units = c("steps", "hours", "days"),
    time_step_minutes = 15,
    first_coefficient = 1.765,
    fast_decay_steps = 1 / 3,
    fast_period_steps = 2,
    label = NULL
) {
  units <- match.arg(units)

  if (length(principal_decay) != 1L || is.na(principal_decay) ||
      principal_decay <= 0) {
    stop("`principal_decay` must be one positive value or `Inf`.", call. = FALSE)
  }
  if (length(time_step_minutes) != 1L || !is.finite(time_step_minutes) ||
      time_step_minutes <= 0) {
    stop("`time_step_minutes` must be one positive finite value.", call. = FALSE)
  }
  # This family only constructs three *real* roots: the fast root is taken
  # via Re(root_from_timescale(...)) below, which is only mathematically
  # correct when that call itself returns a real number. Inf and 2 are the
  # only oscillation periods root_from_timescale() returns as real (see
  # 03-parameters.R); any other value is genuinely complex, and Re() would
  # silently discard the imaginary half rather than error, producing a
  # subtly wrong (incomplete) fast root with no indication anything was
  # lost. Reject that case explicitly instead.
  if (!(is.infinite(fast_period_steps) || isTRUE(all.equal(fast_period_steps, 2)))) {
    stop(
      paste0(
        "`fast_period_steps` must be `Inf` or `2`: this family only ",
        "constructs real roots, and any other period would be genuinely ",
        "complex and silently truncated."
      ),
      call. = FALSE
    )
  }

  principal_decay_steps <- switch(
    units,
    steps = principal_decay,
    hours = principal_decay * 60 / time_step_minutes,
    days = principal_decay * 24 * 60 / time_step_minutes
  )

  principal_root <- if (is.infinite(principal_decay_steps)) {
    1
  } else {
    exp(-1 / principal_decay_steps)
  }

  # Safe to take Re() here: the guard above already rejected any
  # fast_period_steps that would make this genuinely complex.
  fast_root <- Re(root_from_timescale(
    decay_time = fast_decay_steps,
    oscillation_period = fast_period_steps
  ))

  # a_1 = z1 + z2 + z3 is fixed at `first_coefficient`, and z1 (principal)
  # and z3 (fast) are both now known, so z2 is forced: z2 = a_1 - z1 - z3.
  # That only describes a valid member of this family when z2 comes out as
  # a stable, non-oscillating positive root (0 < z2 < 1); a very short
  # principal decay pushes z1 towards 0 and forces z2 above 1 (see
  # developer-mathematics.Rmd's worked derivation). There is therefore an
  # implicit shortest principal decay this family can represent -- around
  # 1.2 hours at the default 1.765/1/3/2 settings, scaling with
  # time_step_minutes -- below which there is no valid member and this
  # fails loudly rather than returning an unstable or meaningless result.
  middle_root <- first_coefficient - principal_root - fast_root

  if (!is.finite(middle_root) || middle_root <= 0 || middle_root >= 1) {
    stop(
      paste0(
        "The requested decay does not produce a stable positive middle root. ",
        "Calculated middle root: ", format(middle_root, digits = 10), "."
      ),
      call. = FALSE
    )
  }

  middle_decay_steps <- -1 / log(middle_root)
  modal_roots <- c(
    principal = principal_root,
    middle = middle_root,
    fast = fast_root
  )

  if (is.null(label)) {
    decay_label <- if (is.infinite(principal_decay)) {
      "infinite"
    } else {
      paste(format(principal_decay, trim = TRUE), units)
    }
    label <- paste0("Default-family AR: principal decay ", decay_label)
  }

  # tolerance is tighter here (1e-12) than roots_to_parameters()'s own
  # default (1e-10) or the package-wide order_tolerance default (1e-8).
  # All three modal_roots values are already plain real numbers (fast_root
  # was stripped of its negligible residual imaginary part above), so the
  # conjugate-pair check this tolerance also gates has nothing genuine to
  # reject; a tight tolerance here instead avoids the opposite risk, of a
  # legitimately small-but-nonzero coefficient being mistaken for an
  # inactive trailing one and silently dropped, reducing the AR order below
  # the 3 this family is meant to produce.
  parameters <- roots_to_parameters(
    root_values = modal_roots,
    label = label,
    tolerance = 1e-12
  )

  # These attributes are provenance for this call's own output, not part of
  # the ARParameterSet contract: nothing else in the package reads or
  # preserves them, so they will not survive being passed through a
  # function that reconstructs a new ARParameterSet (convert_sign_convention(),
  # for instance). Treat them as informational for this object only, and
  # recompute from `parameters@coefficients` after any such transformation.
  attr(parameters, "principal_decay_steps") <- principal_decay_steps
  attr(parameters, "principal_decay_hours") <-
    principal_decay_steps * time_step_minutes / 60
  attr(parameters, "middle_decay_steps") <- middle_decay_steps
  attr(parameters, "fast_decay_steps") <- fast_decay_steps
  attr(parameters, "fast_period_steps") <- fast_period_steps
  attr(parameters, "modal_roots") <- modal_roots
  parameters
}

#' Return a published standard default-family AR parameter set
#'
#' Select one of the named standard parameter sets from the published default
#' family. Use this function where operational standardisation is more important
#' than matching a bespoke catchment timescale exactly.
#'
#' @param principal_decay Standard principal decay label. Accepted values are
#'   `"3 hours"`, `"6 hours"`, `"12 hours"`, `"1 day"`, `"2 days"`,
#'   `"4 days"`, `"8 days"`, `"16 days"`, `"32 days"`, `"64 days"` and
#'   `"Infinite"`.
#' @param time_step_minutes Duration of one model timestep in minutes. The
#'   labels above are fixed durations (for example "12 hours"), but how many
#'   model steps that represents, and therefore the resulting AR
#'   coefficients, depends on this value. Must match the timestep of the
#'   model the parameters will actually run in; it is not just metadata.
#'
#' @returns An AR parameter object calculated from the analytical default-family
#'   construction at the selected standard timescale.
#'
#' @examples
#' parameters <- standard_family_ar_parameters("12 hours")
#' parameters@coefficients
#' root_table(roots(parameters))
#'
#' @export
standard_family_ar_parameters <- function(principal_decay = c(
    "3 hours", "6 hours", "12 hours", "1 day", "2 days", "4 days",
    "8 days", "16 days", "32 days", "64 days", "Infinite"
), time_step_minutes = 15) {
  principal_decay <- match.arg(principal_decay)
  hours <- c(
    "3 hours" = 3, "6 hours" = 6, "12 hours" = 12,
    "1 day" = 24, "2 days" = 48, "4 days" = 96,
    "8 days" = 192, "16 days" = 384, "32 days" = 768,
    "64 days" = 1536, "Infinite" = Inf
  )
  # The "1 day" and "Infinite" entries are a deliberate built-in consistency
  # check, not a coincidence: they reproduce default_ar_parameters()'s
  # c(1.765, -0.72625, -0.040656) and default_et_ar_steady_parameters()'s
  # c(1.765, -0.7244342, -0.04056586) to within the rounding those were
  # originally published at. If a future change to this family ever stops
  # reproducing those two independently-established references, that is a
  # regression -- see test-default-family-ar.R.
  default_family_ar_parameters(
    principal_decay = unname(hours[[principal_decay]]),
    units = "hours",
    time_step_minutes = time_step_minutes,
    label = paste0("Standard default-family AR: ", principal_decay)
  )
}

#' List the published standard default-family AR parameter sets
#'
#' Calculate a reference table of the standard parameter sets. The table is a
#' catalogue for recognition, assurance and verification. The coefficients are
#' calculated directly rather than interpolated between rows.
#'
#' @param time_step_minutes Duration of one model timestep in minutes, passed
#'   through to [standard_family_ar_parameters()] for every row.
#'
#' @returns A `data.table` with the standard label, principal decay, three AR
#'   coefficients and the three root timescales.
#'
#' @examples
#' standard_family_ar_table()
#'
#' @export
standard_family_ar_table <- function(time_step_minutes = 15) {
  labels <- c(
    "3 hours", "6 hours", "12 hours", "1 day", "2 days", "4 days",
    "8 days", "16 days", "32 days", "64 days", "Infinite"
  )
  data.table::rbindlist(lapply(labels, function(label) {
    parameters <- standard_family_ar_parameters(label, time_step_minutes = time_step_minutes)
    data.table::data.table(
      parameter_set = label,
      principal_decay_steps = attr(parameters, "principal_decay_steps"),
      principal_decay_hours = attr(parameters, "principal_decay_hours"),
      a_1 = unname(parameters@coefficients[[1L]]),
      a_2 = unname(parameters@coefficients[[2L]]),
      a_3 = unname(parameters@coefficients[[3L]]),
      fast_decay_steps = attr(parameters, "fast_decay_steps"),
      fast_period_steps = attr(parameters, "fast_period_steps"),
      middle_decay_steps = attr(parameters, "middle_decay_steps")
    )
  }))
}
