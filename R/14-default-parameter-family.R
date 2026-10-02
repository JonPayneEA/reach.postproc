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

  fast_root <- Re(root_from_timescale(
    decay_time = fast_decay_steps,
    oscillation_period = fast_period_steps
  ))

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

  parameters <- roots_to_parameters(
    root_values = modal_roots,
    label = label,
    tolerance = 1e-12
  )

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
)) {
  principal_decay <- match.arg(principal_decay)
  hours <- c(
    "3 hours" = 3, "6 hours" = 6, "12 hours" = 12,
    "1 day" = 24, "2 days" = 48, "4 days" = 96,
    "8 days" = 192, "16 days" = 384, "32 days" = 768,
    "64 days" = 1536, "Infinite" = Inf
  )
  default_family_ar_parameters(
    principal_decay = unname(hours[[principal_decay]]),
    units = "hours",
    label = paste0("Standard default-family AR: ", principal_decay)
  )
}

#' List the published standard default-family AR parameter sets
#'
#' Calculate a reference table of the standard parameter sets. The table is a
#' catalogue for recognition, assurance and verification. The coefficients are
#' calculated directly rather than interpolated between rows.
#'
#' @returns A `data.table` with the standard label, principal decay, three AR
#'   coefficients and the three root timescales.
#'
#' @examples
#' standard_family_ar_table()
#'
#' @export
standard_family_ar_table <- function() {
  labels <- c(
    "3 hours", "6 hours", "12 hours", "1 day", "2 days", "4 days",
    "8 days", "16 days", "32 days", "64 days", "Infinite"
  )
  data.table::rbindlist(lapply(labels, function(label) {
    parameters <- standard_family_ar_parameters(label)
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
