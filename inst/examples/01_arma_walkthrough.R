# reach.postproc: complete functionality walkthrough
#
# This script covers parameter construction, roots, quality assessment,
# recurrence forecasts, root decomposition, updated forecasts, parameter
# creation from timescales, effective decay, full ARMA recurrence, response
# functions and ggplot2 output.

library(reach.postproc)
library(data.table)
library(ggplot2)

# 1. Create the documented 2024 default parameter set -----------------------
parameters <- default_ar_parameters()
print(parameters)

# Equivalent explicit construction. Coefficients retain full precision.
parameters_explicit <- ar_parameters(
  coefficients = c(
    a_1 = 1.765,
    a_2 = -0.72625,
    a_3 = -0.040656
  ),
  label = "2024 EA default, explicit construction"
)

# 2. Calculate and inspect characteristic roots ------------------------------
root_information <- roots(
  parameters,
  time_step_minutes = 15
)

# Every tabular result is a data.table.
stopifnot(is.data.table(root_information@table))
print(root_information@table)

# Standard data.table filtering is available.
root_information@table[decay_time_steps > 8]
root_information@table[is_oscillating == TRUE]

# Plot roots against the unit circle.
root_plot <- plot_ar(root_information)
print(root_plot)

# 3. Assess the parameter set -------------------------------------------------
assessment <- assess(parameters)
print(assessment)

# Inspect only failed tests. The documented defaults should return no rows.
assessment@tests[failed == TRUE]

assessment_plot <- plot_ar(assessment)
print(assessment_plot)

# 4. Calculate observed-minus-simulated model errors -------------------------
observed <- c(1.20, 1.30, 1.50)
simulated <- c(1.00, 1.10, 1.20)
model_error <- calculate_model_error(observed, simulated)
print(model_error)

# 5. Forecast the AR error recurrence ----------------------------------------
# Initial errors are supplied newest first:
# c(x[t - 1], x[t - 2], x[t - 3]).
initial_errors <- c(0.20, 0.15, 0.10)

ar_forecast <- forecast_ar(
  parameters,
  initial_errors = initial_errors,
  steps = 480L,
  time_step_minutes = 15
)

stopifnot(is.data.table(ar_forecast@series))
print(ar_forecast@series[1:12])

forecast_plot <- plot_ar(ar_forecast)
print(forecast_plot)

# 6. Apply the error forecast to a simulated hydrograph ----------------------
# This synthetic hydrograph exists only to demonstrate package behaviour.
# It is not an observed or calibrated flood event.
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

stopifnot(is.data.table(updated_forecast))
print(updated_forecast[1:12])

updated_plot_data <- data.table::melt(
  updated_forecast,
  id.vars = "time",
  measure.vars = c("simulated", "updated_unconstrained", "updated"),
  variable.name = "series",
  value.name = "value"
)

updated_plot <- ggplot(
  updated_plot_data,
  aes(x = time, y = value, colour = series)
) +
  geom_line(linewidth = 0.8) +
  labs(
    x = "Lead time, hours",
    y = "Example level or flow",
    colour = "Series",
    title = "AR-updated forecast and zero cut-off"
  ) +
  theme_minimal()

print(updated_plot)

# 7. Decompose the forecast into root contributions --------------------------
root_contributions <- decompose_ar(
  parameters,
  initial_errors = initial_errors,
  steps = 480L,
  time_step_minutes = 15
)

stopifnot(is.data.table(root_contributions))
print(root_contributions[1:12])

# Sum the modes and compare them with the recurrence forecast.
reconstructed <- root_contributions[
  step > 0,
  .(ar_error_from_roots = sum(contribution_real)),
  by = .(step, lead_time_hours)
]

comparison <- merge(
  ar_forecast@series,
  reconstructed,
  by = c("step", "lead_time_hours")
)
comparison[, absolute_difference := abs(ar_error - ar_error_from_roots)]
stopifnot(max(comparison$absolute_difference) < 1e-10)

root_contribution_plot <- ggplot(
  root_contributions,
  aes(
    x = lead_time_hours,
    y = contribution_real,
    colour = factor(root_number)
  )
) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line(linewidth = 0.7) +
  labs(
    x = "Lead time, hours",
    y = "Contribution to AR error",
    colour = "Root",
    title = "Characteristic-root contributions"
  ) +
  theme_minimal()

print(root_contribution_plot)

# 8. Construct parameters from roots -----------------------------------------
root_values <- c(
  root_from_timescale(decay_time = 95.79, oscillation_period = Inf),
  root_from_timescale(decay_time = 5.204, oscillation_period = Inf),
  root_from_timescale(decay_time = 1 / 3, oscillation_period = 2)
)

parameters_from_roots <- roots_to_parameters(
  root_values,
  label = "Approximate 2024 defaults reconstructed from roots"
)
print(parameters_from_roots)

# 9. Construct parameters directly from timescales ---------------------------
# Complex roots must be supplied as conjugate pairs. A negative real root has
# period 2 and does not require a separate conjugate.
parameters_from_timescales <- ar_parameters_from_timescales(
  decay_times = c(96, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2),
  label = "One-day principal decay"
)
print(parameters_from_timescales)
print(roots(parameters_from_timescales)@table)

# Example containing a complex-conjugate pair.
complex_root <- root_from_timescale(
  decay_time = 10,
  oscillation_period = 20
)

oscillating_parameters <- roots_to_parameters(
  c(complex_root, Conj(complex_root), root_from_timescale(96, Inf)),
  label = "Complex-pair demonstration"
)
print(oscillating_parameters)

# 10. Calculate effective decay time -----------------------------------------
effective_tau <- effective_decay_time(
  decay_time = 10,
  oscillation_period = 20
)
print(effective_tau)

# 11. Demonstrate failing parameter sets -------------------------------------
growing_parameters <- ar_parameters(
  coefficients = c(a_1 = 1.1),
  label = "Growing AR(1) example"
)

growing_assessment <- assess(growing_parameters)
print(growing_assessment)
stopifnot(growing_assessment@result == "Fail")

# 12. Calculate a pure AR unit response --------------------------------------
ar_response <- response(
  parameters,
  steps = 200L
)
print(ar_response@series[1:12])
print(plot_ar(ar_response))

# 13. Calculate a full ARMA unit response ------------------------------------
arma_response <- response(
  parameters,
  ma_parameters = c(
    b_1 = -0.5,
    b_2 = -0.25,
    b_3 = -0.125
  ),
  steps = 200L
)
print(arma_response@series[1:12])
print(plot_ar(arma_response))

# 14. Run a full ARMA recurrence with explicit residuals ---------------------
# Supplying residuals makes the calculation deterministic and testable.
residuals <- numeric(100L)
residuals[[51L]] <- -0.03

arma_forecast <- forecast_arma(
  parameters = parameters,
  initial_errors = c(0, 0, 0),
  residuals = residuals,
  ma_parameters = c(-0.5, -0.25, -0.125),
  previous_residuals = c(0, 0, 0)
)

stopifnot(is.data.table(arma_forecast))
print(arma_forecast[48:56])

arma_forecast_plot <- ggplot(
  arma_forecast,
  aes(x = step, y = arma_error)
) +
  geom_vline(xintercept = 50, linetype = "dashed") +
  geom_line(colour = "#005EA5", linewidth = 0.8) +
  labs(
    x = "Time step",
    y = "ARMA error",
    title = "Response to an explicit residual impulse"
  ) +
  theme_minimal()

print(arma_forecast_plot)

# 15. End-to-end summary ------------------------------------------------------
summary_tables <- list(
  roots = root_information@table,
  tests = assessment@tests,
  forecast = ar_forecast@series,
  decomposition = root_contributions,
  updated = updated_forecast,
  response = arma_response@series
)

print(names(summary_tables))
cat("Walkthrough completed successfully.\n")
