## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 9,
  fig.height = 5.5,
  warning = FALSE,
  message = FALSE
)

library(reach.postproc)
library(data.table)
library(ggplot2)

render_mermaid <- function(diagram) {
  escaped_diagram <- htmltools::htmlEscape(
    diagram
  )

  knitr::asis_output(
    paste0(
      '<pre class="mermaid">',
      escaped_diagram,
      '</pre>'
    )
  )
}

## ----task-flow, echo=FALSE----------------------------------------------------
render_mermaid("
flowchart TD
    A{What do you need to do?}
    B[Assess parameters]
    C[Project one error series]
    D[Evaluate an event archive]
    E[assess and roots]
    F[forecast_ar and apply_ar_update]
    G[align_forecast_series]
    H[fixed_lead_ar]
    I[score_lead_times and plot_lead_times]

    A --> B --> E
    A --> C --> F
    A --> D --> G --> H --> I
")

## ----workflow-parameters------------------------------------------------------
parameters <- default_ar_parameters()
parameters@coefficients

## ----workflow-deltares--------------------------------------------------------
deltares <- ar_parameters(
  coefficients = c(
    a_1 = 1.765,
    a_2 = -0.72625,
    a_3 = -0.040656
  ),
  sign_convention = "Deltares",
  label = "2024 defaults"
)

## ----workflow-standard--------------------------------------------------------
standard <- ar_parameters(
  coefficients = c(
    phi_1 = -1.765,
    phi_2 = 0.72625,
    phi_3 = 0.040656
  ),
  sign_convention = "Standard"
)

all.equal(deltares@coefficients, standard@coefficients)

## ----workflow-roots-----------------------------------------------------------
root_information <- roots(parameters, time_step_minutes = 15)
root_table(root_information)
plot_ar(root_information, root_definition = "modal")

## ----workflow-assessment------------------------------------------------------
assessment <- assess(parameters)
assessment@summary
assessment_table(assessment)

## ----workflow-forecast--------------------------------------------------------
error_forecast <- forecast_ar(
  parameters,
  initial_errors = c(0.15, 0.12, 0.10),
  steps = 96L,
  time_step_minutes = 15
)

forecast_series(error_forecast)
plot_ar(error_forecast)

## ----workflow-update----------------------------------------------------------
simulated <- 0.8 + 1.2 * exp(
  -((forecast_series(error_forecast)$lead_time_hours - 12) / 4)^2
)

updated <- apply_ar_update(
  simulated = simulated,
  ar_error = forecast_series(error_forecast)$ar_error,
  lower_limit = 0,
  time = forecast_series(error_forecast)$lead_time_hours
)

updated

## ----workflow-decomposition---------------------------------------------------
components <- decompose_ar(
  parameters,
  initial_errors = c(0.15, 0.12, 0.10),
  steps = 96L,
  time_step_minutes = 15
)

ggplot(components, aes(lead_time_hours, contribution_real,
                       colour = factor(root_number))) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line() +
  theme_minimal() +
  labs(colour = "Root", x = "Lead time, hours", y = "Contribution")

## ----workflow-data------------------------------------------------------------
event_time <- seq(
  as.POSIXct("2024-11-23 00:00:00", tz = "UTC"),
  by = "15 min",
  length.out = 289L
)

simulated_values <- 0.55 + 1.35 * exp(
  -((seq_along(event_time) - 145) / 34)^2
)

observed_values <- simulated_values +
  0.12 +
  0.08 * sin(seq_along(event_time) / 12)

observed <- data.table(
  date_time = event_time,
  value = observed_values
)

simulated <- data.table(
  date_time = event_time,
  value = simulated_values
)

## ----workflow-align-----------------------------------------------------------
aligned <- align_forecast_series(
  observed = observed,
  simulated = simulated,
  interval_minutes = 15,
  timezone = "UTC",
  metadata = list(
    site_id = "example-site",
    event_id = "synthetic-event",
    measure = "level",
    units = "m"
  )
)

alignment_diagnostics(aligned)
aligned_series(aligned)

## ----workflow-fixed-leads-----------------------------------------------------
lead_results <- fixed_lead_ar(
  parameters = parameters,
  data = aligned,
  lead_times_minutes = c(30, 60, 90),
  time_step_minutes = 15,
  lower_limit = 0,
  method = "recurrence",
  metadata = list(
    site_id = "example-site",
    event_id = "synthetic-event"
  )
)

lead_time_series(lead_results)

## ----workflow-score-----------------------------------------------------------
scores <- score_lead_times(lead_results)
scores

## ----workflow-plot------------------------------------------------------------
plot_lead_times(lead_results)

## ----workflow-verification, eval=FALSE----------------------------------------
# recurrence_results <- fixed_lead_ar(
#   parameters,
#   aligned,
#   lead_times_minutes = c(30, 60, 90),
#   method = "recurrence"
# )
# 
# root_results <- fixed_lead_ar(
#   parameters,
#   aligned,
#   lead_times_minutes = c(30, 60, 90),
#   method = "roots"
# )

## ----workflow-response--------------------------------------------------------
response_data <- response_components(
  parameters,
  ma_parameters = c(-0.5, -0.25, -0.125),
  steps = 100L
)

ggplot(response_data, aes(step, response, colour = component)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line() +
  theme_minimal()

## ----workflow-export, eval=FALSE----------------------------------------------
# fwrite(
#   lead_time_series(lead_results),
#   "lead-time-series.csv"
# )
# 
# fwrite(
#   scores,
#   "lead-time-scores.csv"
# )
# 
# ggsave(
#   "lead-time-plot.png",
#   plot = plot_lead_times(lead_results),
#   width = 300,
#   height = 150,
#   units = "mm",
#   dpi = 300,
#   bg = "white"
# )

