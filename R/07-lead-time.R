# Fixed lead-time AR post-processing.
# Data import belongs to reach.io. Rating transformations belong to reach.rate.

#' Validate a regular time step
#'
#' @param time Ordered date-time vector.
#' @param interval_minutes Expected interval in minutes.
#' @param tolerance_seconds Accepted absolute timing difference in seconds.
#'
#' @return One-row diagnostic `data.table`.
#'
#' @export
validate_regular_time_step <- function(
    time,
    interval_minutes,
    tolerance_seconds = 1
) {
  if (length(time) < 2L) .stop_bad("`time` must contain at least two values.")
  seconds <- as.numeric(diff(time), units = "secs")
  expected <- interval_minutes * 60
  irregular <- which(abs(seconds - expected) > tolerance_seconds)
  data.table::data.table(
    regular = length(irregular) == 0L,
    expected_seconds = expected,
    minimum_seconds = min(seconds),
    maximum_seconds = max(seconds),
    irregular_intervals = list(irregular)
  )
}

#' Align observed and simulated event series
#'
#' @param observed Observed data coercible to a `data.table`.
#' @param simulated Simulated data coercible to a `data.table`.
#' @param observed_time_column,simulated_time_column Time-column names.
#' @param observed_value_column,simulated_value_column Value-column names.
#' @param join Join type: `"inner"` or `"full"`.
#' @param duplicate_action How duplicate timestamps are handled.
#' @param interval_minutes Optional expected interval for diagnostics.
#' @param timezone Timezone applied during standardisation.
#'
#' @return Aligned `data.table` with an `alignment_diagnostics` attribute.
#'
#' @export
align_forecast_series <- function(observed, simulated,
                                  observed_time_column = "date_time",
                                  observed_value_column = "value",
                                  simulated_time_column = "date_time",
                                  simulated_value_column = "value",
                                  join = c("inner", "full"),
                                  duplicate_action = c("error", "mean", "first"),
                                  interval_minutes = NULL,
                                  timezone = "UTC") {
  join <- match.arg(join)
  duplicate_action <- match.arg(duplicate_action)
  obs <- as_data_table_copy(observed)
  sim <- as_data_table_copy(simulated)
  required_obs <- c(observed_time_column, observed_value_column)
  required_sim <- c(simulated_time_column, simulated_value_column)
  if (any(!required_obs %in% names(obs))) .stop_bad("Observed data lack required columns.")
  if (any(!required_sim %in% names(sim))) .stop_bad("Simulated data lack required columns.")
  obs <- obs[, .(date_time = get(observed_time_column), observed = get(observed_value_column))]
  sim <- sim[, .(date_time = get(simulated_time_column), simulated = get(simulated_value_column))]
  obs[, date_time := as.POSIXct(date_time, tz = timezone)]
  sim[, date_time := as.POSIXct(date_time, tz = timezone)]
  duplicate_rows <- function(x) x[duplicated(date_time) | duplicated(date_time, fromLast = TRUE)]
  obs_dup <- duplicate_rows(obs); sim_dup <- duplicate_rows(sim)
  if (duplicate_action == "error" && (nrow(obs_dup) || nrow(sim_dup))) {
    .stop_bad("Duplicate timestamps were found. Resolve them or select another `duplicate_action`.")
  }
  collapse_duplicates <- function(x, value_name) {
    if (duplicate_action == "mean") {
      return(
        x[
          ,
          stats::setNames(
            list(
              mean(
                get(value_name),
                na.rm = TRUE
              )
            ),
            value_name
          ),
          by = date_time
        ]
      )
    }

    if (duplicate_action == "first") {
      return(
        x[
          ,
          .SD[1L],
          by = date_time
        ]
      )
    }

    x
  }
  obs <- collapse_duplicates(
    x = obs,
    value_name = "observed"
  )

  sim <- collapse_duplicates(
    x = sim,
    value_name = "simulated"
  )
  data.table::setkey(obs, date_time); data.table::setkey(sim, date_time)
  out <- merge(obs, sim, by = "date_time", all = join == "full", sort = TRUE)
  out[, error := observed - simulated]
  diagnostics <- data.table::data.table(
    observed_rows = nrow(obs), simulated_rows = nrow(sim), aligned_rows = nrow(out),
    observed_without_simulation = out[!is.na(observed) & is.na(simulated), .N],
    simulation_without_observation = out[is.na(observed) & !is.na(simulated), .N],
    missing_observed = out[is.na(observed), .N], missing_simulated = out[is.na(simulated), .N]
  )
  if (!is.null(interval_minutes)) {
    regularity <- validate_regular_time_step(out$date_time, interval_minutes)
    diagnostics[, `:=`(regular_time_step = regularity$regular,
                       irregular_interval_count = length(regularity$irregular_intervals[[1L]]))]
  }
  attr(out, "alignment_diagnostics") <- diagnostics
  out[]
}

.fixed_lead_recurrence <- function(
    parameters,
    errors,
    target_index,
    lead_steps
) {
  origin <- target_index - lead_steps
  input_indices <- origin - seq.int(0L, parameters@order - 1L)
  if (min(input_indices) < 1L || anyNA(errors[input_indices])) return(NA_real_)
  projected <- forecast_ar(parameters, initial_errors = errors[input_indices], steps = lead_steps)
  projected@series$ar_error[[lead_steps]]
}

.fixed_lead_roots <- function(parameters, errors, target_index, lead_steps,
                              condition_limit = 1e12) {
  origin <- target_index - lead_steps
  input_indices <- origin - seq.int(0L, parameters@order - 1L)
  if (min(input_indices) < 1L || anyNA(errors[input_indices])) return(NA_real_)
  z <- roots(parameters)@values
  known_times <- -seq.int(0L, parameters@order - 1L)
  matrix_z <- outer(known_times, z, function(time, root) root^time)
  if (kappa(matrix_z) > condition_limit) {
    warning("Root projection is ill-conditioned; recurrence should be preferred.", call. = FALSE)
  }
  weights <- solve(matrix_z, as.complex(errors[input_indices]))
  Re(sum(weights * z^lead_steps))
}

#' Calculate fixed lead-time AR-updated series
#'
#' @param parameters An `ARParameterSet`.
#' @param data Aligned event data.
#' @param time_column,observed_column,simulated_column Input column names.
#' @param lead_times_minutes Positive lead times divisible by the model step.
#' @param time_step_minutes Duration represented by one model step.
#' @param lower_limit Optional lower bound applied to updated values.
#' @param method Production recurrence or root-based verification.
#' @param measure,site_name Optional metadata.
#'
#' @return An `ARLeadTimeResult`.
#'
#' @export
fixed_lead_ar <- function(parameters, data,
                          time_column = "date_time",
                          observed_column = "observed",
                          simulated_column = "simulated",
                          lead_times_minutes = c(30, 60, 90),
                          time_step_minutes = 15,
                          lower_limit = NULL,
                          method = c("recurrence", "roots"),
                          measure = NA_character_,
                          site_name = NA_character_) {
  if (!S7::S7_inherits(parameters, ARParameterSet)) .stop_bad("`parameters` must be an ARParameterSet.")
  method <- match.arg(method)
  d <- as_data_table_copy(data)
  needed <- c(time_column, observed_column, simulated_column)
  if (any(!needed %in% names(d))) .stop_bad("Lead-time input lacks required columns.")
  if (any(!is.finite(lead_times_minutes)) || any(lead_times_minutes <= 0) ||
      any(lead_times_minutes %% time_step_minutes != 0)) {
    .stop_bad("Every lead time must be positive and exactly divisible by `time_step_minutes`.")
  }
  time <- d[[time_column]]; observed <- d[[observed_column]]; simulated <- d[[simulated_column]]
  errors <- observed - simulated
  lead_steps <- as.integer(lead_times_minutes / time_step_minutes)
  result <- data.table::rbindlist(lapply(seq_along(lead_steps), function(j) {
    correction <- vapply(seq_along(time), function(i) {
      if (i <= lead_steps[[j]] + parameters@order - 1L) return(NA_real_)
      if (method == "recurrence") .fixed_lead_recurrence(parameters, errors, i, lead_steps[[j]])
      else .fixed_lead_roots(parameters, errors, i, lead_steps[[j]])
    }, numeric(1))
    updated_unconstrained <- simulated + correction
    updated <- if (is.null(lower_limit)) updated_unconstrained else pmax(updated_unconstrained, lower_limit)
    data.table::data.table(
      date_time = time, lead_time_minutes = lead_times_minutes[[j]],
      lead_time_steps = lead_steps[[j]], observed = observed, simulated = simulated,
      initialisation_time = data.table::shift(time, lead_steps[[j]]),
      ar_error = correction, updated_unconstrained = updated_unconstrained,
      updated = updated, was_limited = !is.na(updated) & updated != updated_unconstrained,
      calculation_method = method
    )
  }))
  ARLeadTimeResult(parameters = parameters, series = result,
                   lead_times_minutes = as.numeric(lead_times_minutes),
                   time_step_minutes = as.numeric(time_step_minutes),
                   metadata = list(measure = measure, site_name = site_name))
}

#' Score fixed lead-time forecasts
#'
#' @param x An `ARLeadTimeResult` or compatible table.
#'
#' @return `data.table` containing MAE, RMSE, bias and improvements by lead.
#'
#' @export
score_lead_times <- function(x) {
  series <- if (S7::S7_inherits(x, ARLeadTimeResult)) {
    data.table::copy(x@series)
  } else {
    as_data_table_copy(x)
  }
  required <- c("lead_time_minutes", "observed", "simulated", "updated")
  if (any(!required %in% names(series))) .stop_bad("Lead-time result lacks scoring columns.")
  series[stats::complete.cases(observed, simulated, updated), .(
    n = .N,
    mae_simulated = mean(abs(simulated - observed)),
    mae_updated = mean(abs(updated - observed)),
    rmse_simulated = sqrt(mean((simulated - observed)^2)),
    rmse_updated = sqrt(mean((updated - observed)^2)),
    bias_simulated = mean(simulated - observed),
    bias_updated = mean(updated - observed)
  ), by = lead_time_minutes][, `:=`(
    improvement_mae = mae_simulated - mae_updated,
    improvement_rmse = rmse_simulated - rmse_updated
  )][]
}

#' Prepare long-format lead-time plot data
#'
#' @param x An `ARLeadTimeResult`.
#' @param common_period_only Restrict data to the common valid period.
#'
#' @return Long-format `data.table`.
#'
#' @export
lead_time_plot_data <- function(
    x,
    common_period_only = TRUE
) {
  if (!S7::S7_inherits(x, ARLeadTimeResult)) .stop_bad("`x` must be an ARLeadTimeResult.")
  d <- data.table::copy(x@series)
  if (common_period_only) {
    valid_start <- d[!is.na(updated), max(min(date_time), na.rm = TRUE), by = lead_time_minutes]$V1
    d <- d[date_time >= valid_start]
  }
  base <- unique(d[, .(date_time, observed, simulated)])
  base_long <- data.table::melt(base, id.vars = "date_time", variable.name = "series", value.name = "value")
  leads <- d[, .(date_time, series = paste0("t-", lead_time_minutes), value = updated)]
  data.table::rbindlist(list(base_long, leads), use.names = TRUE)
}

#' Plot fixed lead-time results
#'
#' @param x An `ARLeadTimeResult`.
#' @param thresholds Optional table with `value` and `name` columns.
#' @param common_period_only Restrict the plot to the common valid period.
#' @param colours Optional colour vector.
#' @param site_name,measure Optional labels overriding stored metadata.
#'
#' @return A `ggplot` object.
#'
#' @export
plot_lead_times <- function(x, thresholds = NULL, common_period_only = TRUE,
                            colours = NULL, site_name = NULL, measure = NULL) {
  plot_data <- lead_time_plot_data(x, common_period_only)
  lead_labels <- paste0("t-", sort(unique(x@lead_times_minutes)))
  plot_data[, series := factor(series, levels = c("observed", "simulated", lead_labels))]
  if (is.null(site_name)) site_name <- x@metadata$site_name
  if (is.null(measure)) measure <- x@metadata$measure
  if (is.null(colours)) colours <- c("black", "#D4351C", "#00703C", "#F47738", "#4C2C92", "#1D70B8", "#FFDD00")
  colours <- rep(colours, length.out = length(levels(plot_data$series)))
  title <- paste0("AR lead-time plot", if (!is.na(site_name)) paste0(" at ", site_name) else "")
  y_label <- if (identical(measure, "level")) {
    "Level (m)"
  } else if (identical(measure, "flow")) {
    "Flow (m3/s)"
  } else {
    "Value"
  }
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(date_time, value, colour = series)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_colour_manual(values = colours, drop = FALSE) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = title, x = "Date", y = y_label, colour = NULL) +
    ggplot2::theme(legend.position = "bottom")
  if (!is.null(thresholds)) {
    th <- as_data_table_copy(thresholds)
    if (any(!c("value", "name") %in% names(th))) .stop_bad("Thresholds require `value` and `name` columns.")
    p <- p + ggplot2::geom_hline(data = th, ggplot2::aes(yintercept = value),
                                 colour = "darkred", linetype = "dashed", linewidth = 0.5)
  }
  p
}
