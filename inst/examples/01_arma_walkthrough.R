# reach.postproc: complete functionality walkthrough
#
# This script contains two workflows:
#
# A. A fully reproducible mathematical example using synthetic data.
# B. An operational event workflow using series imported by reach.io and,
#    where required, converted by reach.rate.
#
# Package responsibilities:
#
# reach.io
#   Imports and standardises observed and simulated data.
#
# reach.rate
#   Converts between level and flow where required.
#
# reach.postproc
#   Aligns imported series, calculates model errors, assesses AR parameters,
#   applies AR and ARMA post-processing, calculates fixed lead-time series,
#   scores performance and creates diagnostic plots.
#
# The walkthrough does not install packages automatically. Install missing
# packages before running it.

# -----------------------------------------------------------------------------
# 0. Load packages and set common options
# -----------------------------------------------------------------------------

library(reach.postproc)
library(data.table)
library(ggplot2)

# Apply an accessible palette when afcolours is installed. The walkthrough
# remains runnable without it.
has_afcolours <- requireNamespace(
  "afcolours",
  quietly = TRUE
)

save_outputs <- FALSE
output_directory <- file.path(
  getwd(),
  "reach_postproc_outputs"
)

# -----------------------------------------------------------------------------
# WORKFLOW A: REPRODUCIBLE MATHEMATICAL EXAMPLE
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Create AR parameters
# -----------------------------------------------------------------------------

parameters <- default_ar_parameters()
print(parameters)

# The same parameter set can be supplied using standard AR notation. The
# constructor converts it to the Deltares convention used internally.
standard_parameters <- ar_parameters(
  coefficients = c(
    phi_1 = -1.765,
    phi_2 = 0.72625,
    phi_3 = 0.040656
  ),
  sign_convention = "Standard",
  label = "2024 defaults supplied in standard notation"
)

stopifnot(
  isTRUE(
    all.equal(
      standard_parameters@coefficients,
      parameters@coefficients
    )
  )
)

# Trailing inactive coefficients do not increase the model order. This is an
# AR(2) model despite the supplied third value.
second_order_parameters <- ar_parameters(
  coefficients = c(
    a_1 = 1.85,
    a_2 = -0.85,
    a_3 = 0
  ),
  order_tolerance = 1e-8,
  label = "Second-order example"
)

stopifnot(
  second_order_parameters@order == 2L
)

# -----------------------------------------------------------------------------
# 2. Inspect characteristic roots and time scales
# -----------------------------------------------------------------------------

root_information <- roots(
  parameters,
  time_step_minutes = 15
)

stopifnot(
  data.table::is.data.table(
    root_information@table
  )
)

print(
  root_information@table
)

# The table includes both exponential and effective decay times. Effective
# decay accounts for the faster initial reduction caused by oscillation.
root_information@table[
  ,
  .(
    display_order,
    root_real,
    root_imaginary,
    root_modulus,
    decay_time_steps,
    effective_decay_time_steps,
    oscillation_period_steps,
    is_growing,
    is_oscillating
  )
]

root_plot <- plot_ar(
  root_information
)

print(
  root_plot
)

# -----------------------------------------------------------------------------
# 3. Assess parameter quality
# -----------------------------------------------------------------------------

# This reproduces the policy in the previous assessment tool:
#
# - use effective decay time;
# - accept AR(2) and AR(3);
# - reject AR(1) unless it is explicitly permitted.
assessment_effective <- assess(
  parameters,
  decay_measure = "effective",
  permitted_orders = c(
    2L,
    3L
  )
)

print(
  assessment_effective
)

assessment_effective@tests[
  ,
  .(
    test_id,
    test,
    failed,
    affected_roots,
    criterion
  )
]

cat(
  assessment_effective@summary,
  "\n"
)

# The exponential interpretation remains available for comparison.
assessment_exponential <- assess(
  parameters,
  decay_measure = "exponential",
  permitted_orders = c(
    1L,
    2L,
    3L
  )
)

print(
  assessment_exponential
)

assessment_plot <- plot_ar(
  assessment_effective
)

print(
  assessment_plot
)

# Demonstrate a failing parameter set.
growing_parameters <- ar_parameters(
  coefficients = c(
    a_1 = 1.1
  ),
  label = "Growing first-order example"
)

# Permit AR(1) here so the failure demonstrates exponential growth rather than
# the model-order policy.
growing_assessment <- assess(
  growing_parameters,
  permitted_orders = c(
    1L,
    2L,
    3L
  )
)

print(
  growing_assessment
)

stopifnot(
  growing_assessment@result == "Fail"
)

# -----------------------------------------------------------------------------
# 4. Generate a single AR forecast
# -----------------------------------------------------------------------------

# Initial errors are ordered newest first:
#
# c(x[t - 1], x[t - 2], x[t - 3])
initial_errors <- c(
  0.15,
  0.12,
  0.10
)

ar_forecast <- forecast_ar(
  parameters,
  initial_errors = initial_errors,
  steps = 480L,
  time_step_minutes = 15
)

print(
  ar_forecast@series[1:12]
)

forecast_plot <- plot_ar(
  ar_forecast
)

print(
  forecast_plot
)

# -----------------------------------------------------------------------------
# 5. Apply the AR forecast and retain the unconstrained result
# -----------------------------------------------------------------------------

# This synthetic hydrograph exists only to demonstrate package behaviour.
lead_time_hours <- ar_forecast@series$lead_time_hours

simulated_forecast <- 0.75 + 1.5 * exp(
  -((lead_time_hours - 24) / 8)^2
)

updated_forecast <- apply_ar_update(
  simulated = simulated_forecast,
  ar_error = ar_forecast@series$ar_error,
  lower_limit = 0,
  time = lead_time_hours
)

print(
  updated_forecast[1:12]
)

# The constrained line can be zero while updated_unconstrained remains
# negative. The lower limit does not feed back into the AR recurrence.
updated_long <- data.table::melt(
  updated_forecast,
  id.vars = "time",
  measure.vars = c(
    "simulated",
    "updated_unconstrained",
    "updated"
  ),
  variable.name = "series",
  value.name = "value"
)

updated_plot <- ggplot(
  updated_long,
  aes(
    x = time,
    y = value,
    colour = series
  )
) +
  geom_hline(
    yintercept = 0,
    colour = "grey70"
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  labs(
    title = "AR-updated forecast and lower cut-off",
    x = "Lead time, hours",
    y = "Example level or flow",
    colour = NULL
  ) +
  theme_minimal()

print(
  updated_plot
)

# -----------------------------------------------------------------------------
# 6. Decompose the forecast into characteristic-root contributions
# -----------------------------------------------------------------------------

root_contributions <- decompose_ar(
  parameters,
  initial_errors = initial_errors,
  steps = 480L,
  time_step_minutes = 15
)

reconstructed_forecast <- root_contributions[
  step > 0,
  .(
    ar_error_from_roots = sum(
      contribution_real
    )
  ),
  by = .(
    step,
    lead_time_hours
  )
]

recurrence_comparison <- merge(
  ar_forecast@series,
  reconstructed_forecast,
  by = c(
    "step",
    "lead_time_hours"
  )
)

recurrence_comparison[
  ,
  absolute_difference := abs(
    ar_error - ar_error_from_roots
  )
]

stopifnot(
  max(
    recurrence_comparison$absolute_difference
  ) < 1e-9
)

root_contribution_plot <- ggplot(
  root_contributions,
  aes(
    x = lead_time_hours,
    y = contribution_real,
    colour = factor(
      root_number
    )
  )
) +
  geom_hline(
    yintercept = 0,
    colour = "grey70"
  ) +
  geom_line(
    linewidth = 0.8
  ) +
  labs(
    title = "Characteristic-root contributions",
    x = "Lead time, hours",
    y = "Contribution to AR error",
    colour = "Root"
  ) +
  theme_minimal()

print(
  root_contribution_plot
)

# -----------------------------------------------------------------------------
# 7. Construct parameters from time scales
# -----------------------------------------------------------------------------

parameters_from_timescales <- ar_parameters_from_timescales(
  decay_times = c(
    96,
    5.203171,
    1 / 3
  ),
  oscillation_periods = c(
    Inf,
    Inf,
    2
  ),
  label = "One-day principal decay"
)

print(
  parameters_from_timescales
)

print(
  roots(
    parameters_from_timescales
  )@table
)

# -----------------------------------------------------------------------------
# 8. Solve parameters from mixed constraints
# -----------------------------------------------------------------------------

# This reproduces the earlier workflow where two roots are supplied and a_1 is
# fixed. The package solves a_2 and a_3 from the characteristic equations.
mixed_parameters <- solve_ar_parameters(
  order = 3L,
  decay_times = c(
    12,
    1 / 3
  ),
  oscillation_periods = c(
    Inf,
    2
  ),
  coefficients = c(
    a_1 = 1.765,
    a_2 = NA,
    a_3 = NA
  ),
  label = "Two roots with fixed a_1"
)

print(
  mixed_parameters
)

mixed_solution_diagnostics <- attr(
  mixed_parameters,
  "solution_diagnostics"
)

print(
  mixed_solution_diagnostics
)

# The diagnostics report rank, condition number and equation residual. A high
# condition number means small changes in the constraints may cause large
# changes in the solved coefficients.

# -----------------------------------------------------------------------------
# 9. Calculate AR, MA and ARMA response functions
# -----------------------------------------------------------------------------

ma_parameters <- c(
  b_1 = -0.5,
  b_2 = -0.25,
  b_3 = -0.125,
  b_4 = 0
)

response_data <- response_components(
  parameters,
  ma_parameters = ma_parameters,
  steps = 100L
)

print(
  response_data[1:15]
)

response_plot <- ggplot(
  response_data,
  aes(
    x = step,
    y = response,
    colour = component
  )
) +
  geom_hline(
    yintercept = 0,
    colour = "grey70"
  ) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "AR, MA and ARMA response components",
    x = "Time step from impulse",
    y = "Response to unit impulse",
    colour = NULL
  ) +
  theme_minimal()

if (has_afcolours) {
  response_plot <- response_plot +
    scale_colour_manual(
      values = afcolours::af_colours(
        "categorical"
      )[c(
        2,
        1,
        4
      )]
    )
}

print(
  response_plot
)

# Run a deterministic ARMA recurrence with an explicit residual impulse.
residuals <- numeric(
  100L
)

residuals[[51L]] <- -0.03

arma_series <- forecast_arma(
  parameters = parameters,
  initial_errors = c(
    0,
    0,
    0
  ),
  residuals = residuals,
  ma_parameters = c(
    -0.5,
    -0.25,
    -0.125
  ),
  previous_residuals = c(
    0,
    0,
    0
  )
)

print(
  arma_series[48:56]
)

# -----------------------------------------------------------------------------
# WORKFLOW B: OPERATIONAL EVENT PERFORMANCE
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 10. Prepare imported event data
# -----------------------------------------------------------------------------

# Operational route:
#
# observed <- reach.io::<observed import function>(...)
# simulated <- reach.io::<simulation import function>(...)
#
# Do not invent reach.io calls here. Use the functions and standard output
# schema provided by the installed version of reach.io.
#
# If a level-flow conversion is required, apply reach.rate before alignment:
#
# observed <- reach.rate::<conversion function>(...)
# simulated <- reach.rate::<conversion function>(...)
#
# Both series passed to align_forecast_series() must represent the same
# quantity and use the same units.

# The synthetic series below make this walkthrough fully reproducible without
# local files, API access or package-specific import configuration.
event_start <- as.POSIXct(
  "2024-11-23 00:00:00",
  tz = "UTC"
)

event_time <- seq(
  event_start,
  by = "15 min",
  length.out = 289L
)

simulation_values <- 0.55 +
  1.35 * exp(
    -((seq_along(event_time) - 145) / 34)^2
  )

# Add a slow bias and a short timing-sensitive feature to the observation.
observed_values <- simulation_values +
  0.12 +
  0.08 * sin(
    seq_along(event_time) / 12
  ) +
  0.12 * exp(
    -((seq_along(event_time) - 112) / 10)^2
  )

observed_series <- data.table(
  date_time = event_time,
  value = observed_values
)

simulated_series <- data.table(
  date_time = event_time,
  value = simulation_values
)

measure <- "level"
units <- "m"
site_name <- "Example site"

# -----------------------------------------------------------------------------
# 11. Align observed and simulated series
# -----------------------------------------------------------------------------

aligned_event <- align_forecast_series(
  observed = observed_series,
  simulated = simulated_series,
  observed_time_column = "date_time",
  observed_value_column = "value",
  simulated_time_column = "date_time",
  simulated_value_column = "value",
  join = "inner",
  duplicate_action = "error",
  interval_minutes = 15,
  timezone = "UTC"
)

alignment_diagnostics <- attr(
  aligned_event,
  "alignment_diagnostics"
)

print(
  alignment_diagnostics
)

# Diagnostics should be examined before post-processing. This example stops if
# the aligned event does not have a regular 15-minute timestep.
if (!isTRUE(
  alignment_diagnostics$regular_time_step
)) {
  stop(
    "The aligned event does not have a regular 15-minute timestep.",
    call. = FALSE
  )
}

if (
  alignment_diagnostics$observed_without_simulation > 0L ||
    alignment_diagnostics$simulation_without_observation > 0L
) {
  warning(
    "The aligned event contains unmatched observed or simulated timestamps.",
    call. = FALSE
  )
}

if (
  alignment_diagnostics$missing_observed > 0L ||
    alignment_diagnostics$missing_simulated > 0L
) {
  warning(
    "The aligned event contains missing observed or simulated values.",
    call. = FALSE
  )
}

print(
  aligned_event[1:12]
)

# The error uses the package convention:
#
# observed - simulated
stopifnot(
  isTRUE(
    all.equal(
      aligned_event$error,
      aligned_event$observed - aligned_event$simulated
    )
  )
)

# -----------------------------------------------------------------------------
# 12. Calculate fixed lead-time AR-updated series
# -----------------------------------------------------------------------------

lead_times_minutes <- c(
  30,
  60,
  90
)

lead_time_results <- fixed_lead_ar(
  parameters = parameters,
  data = aligned_event,
  time_column = "date_time",
  observed_column = "observed",
  simulated_column = "simulated",
  lead_times_minutes = lead_times_minutes,
  time_step_minutes = 15,
  lower_limit = 0,
  method = "recurrence",
  measure = measure,
  site_name = site_name
)

print(
  lead_time_results
)

# Interpretation of a 60-minute result:
#
# 1. Move four 15-minute steps backwards from the target time.
# 2. Take the error sequence available at that forecast origin.
# 3. Initialise the AR recurrence from those errors.
# 4. Advance the recurrence by four steps.
# 5. Add the projected error to the simulation at the target time.

lead_time_results@series[
  lead_time_minutes == 60,
  .(
    date_time,
    initialisation_time,
    observed,
    simulated,
    ar_error,
    updated_unconstrained,
    updated,
    was_limited
  )
][1:12]

# -----------------------------------------------------------------------------
# 13. Score fixed lead-time performance
# -----------------------------------------------------------------------------

lead_time_scores <- score_lead_times(
  lead_time_results
)

print(
  lead_time_scores
)

scoring_example <- lead_time_scores[
  ,
  .(
    lead_time_minutes,
    n,
    mae_simulated,
    mae_updated,
    improvement_mae,
    rmse_simulated,
    rmse_updated,
    improvement_rmse,
    bias_simulated,
    bias_updated
  )
]

print(
  scoring_example
)

# Interpretation:
#
# Positive improvement_mae or improvement_rmse
#   AR updating reduced the forecast error.
#
# Zero improvement
#   AR updating made no difference under that metric.
#
# Negative improvement
#   AR updating worsened the forecast error.
#
# Bias retains direction. A value closer to zero is preferable, but comparing
# signed bias alone can conceal offsetting positive and negative errors.

lead_time_scores[
  ,
  performance_result := fifelse(
    improvement_rmse > 0,
    "AR improved RMSE",
    fifelse(
      improvement_rmse < 0,
      "AR worsened RMSE",
      "No RMSE change"
    )
  )
]

print(
  lead_time_scores[
    ,
    .(
      lead_time_minutes,
      performance_result
    )
  ]
)

# -----------------------------------------------------------------------------
# 14. Plot fixed lead-time results and thresholds
# -----------------------------------------------------------------------------

thresholds <- data.table(
  value = c(
    0.60,
    1.25
  ),
  name = c(
    "Lower example threshold",
    "Upper example threshold"
  )
)

lead_time_plot <- plot_lead_times(
  lead_time_results,
  thresholds = thresholds,
  common_period_only = TRUE,
  site_name = site_name,
  measure = measure
)

print(
  lead_time_plot
)

# Preserve the complete result for analysis. common_period_only affects only
# plot preparation and does not truncate lead_time_results@series.
stopifnot(
  nrow(
    lead_time_results@series
  ) == length(event_time) * length(lead_times_minutes)
)

# -----------------------------------------------------------------------------
# 15. Verify recurrence against characteristic-root projection
# -----------------------------------------------------------------------------

lead_time_results_roots <- fixed_lead_ar(
  parameters = parameters,
  data = aligned_event,
  lead_times_minutes = lead_times_minutes,
  time_step_minutes = 15,
  lower_limit = 0,
  method = "roots",
  measure = measure,
  site_name = site_name
)

lead_method_comparison <- merge(
  lead_time_results@series[
    ,
    .(
      date_time,
      lead_time_minutes,
      recurrence_updated = updated
    )
  ],
  lead_time_results_roots@series[
    ,
    .(
      date_time,
      lead_time_minutes,
      roots_updated = updated
    )
  ],
  by = c(
    "date_time",
    "lead_time_minutes"
  )
)

lead_method_comparison[
  ,
  absolute_difference := abs(
    recurrence_updated - roots_updated
  )
]

method_diagnostics <- lead_method_comparison[
  ,
  .(
    comparable_values = sum(
      !is.na(absolute_difference)
    ),
    maximum_absolute_difference = max(
      absolute_difference,
      na.rm = TRUE
    ),
    mean_absolute_difference = mean(
      absolute_difference,
      na.rm = TRUE
    )
  ),
  by = lead_time_minutes
]

print(
  method_diagnostics
)

stopifnot(
  method_diagnostics[
    ,
    max(
      maximum_absolute_difference
    )
  ] < 1e-8
)

# The recurrence is the operational implementation. The root calculation is an
# independently formulated verification route.

# -----------------------------------------------------------------------------
# 16. Save outputs explicitly
# -----------------------------------------------------------------------------

# reach.postproc returns objects and does not write files automatically.
if (save_outputs) {
  dir.create(
    output_directory,
    recursive = TRUE,
    showWarnings = FALSE
  )

  data.table::fwrite(
    alignment_diagnostics,
    file.path(
      output_directory,
      "alignment_diagnostics.csv"
    )
  )

  data.table::fwrite(
    lead_time_results@series,
    file.path(
      output_directory,
      "lead_time_series.csv"
    )
  )

  data.table::fwrite(
    lead_time_scores,
    file.path(
      output_directory,
      "lead_time_scores.csv"
    )
  )

  data.table::fwrite(
    method_diagnostics,
    file.path(
      output_directory,
      "recurrence_root_diagnostics.csv"
    )
  )

  ggplot2::ggsave(
    filename = file.path(
      output_directory,
      "lead_time_plot.png"
    ),
    plot = lead_time_plot,
    width = 300,
    height = 150,
    units = "mm",
    dpi = 300,
    bg = "white"
  )
}

cat(
  "reach.postproc walkthrough completed successfully.\n"
)
