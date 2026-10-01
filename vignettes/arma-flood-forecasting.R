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

## ----sign-conventions---------------------------------------------------------
deltares <- ar_parameters(
  coefficients = c(1.765, -0.72625, -0.040656),
  sign_convention = "Deltares"
)

standard <- ar_parameters(
  coefficients = c(-1.765, 0.72625, 0.040656),
  sign_convention = "Standard"
)

all.equal(
  deltares@coefficients,
  standard@coefficients
)

## ----technical-roots----------------------------------------------------------
parameters <- default_ar_parameters()
root_information <- roots(parameters, time_step_minutes = 15)
root_table(root_information)
plot_ar(root_information, root_definition = "modal")

## ----root-decomposition-------------------------------------------------------
components <- decompose_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 96L,
  time_step_minutes = 15
)

ggplot(
  components,
  aes(
    x = lead_time_hours,
    y = contribution_real,
    colour = factor(root_number)
  )
) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line() +
  theme_minimal() +
  labs(x = "Lead time, hours", y = "Root contribution", colour = "Root")

## ----technical-assessment-----------------------------------------------------
assessment <- assess(
  parameters,
  maximum_decay_time = 240,
  minimum_useful_decay_time = 8,
  rapid_decay_exception = 1,
  oscillation_ratio = -2 * log(0.1),
  decay_measure = "effective",
  permitted_orders = c(2L, 3L),
  time_step_minutes = 15
)

assessment@summary
assessment_table(assessment)

## ----parameter-construction---------------------------------------------------
constructed <- ar_parameters_from_timescales(
  decay_times = c(96, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2),
  label = "One-day principal decay"
)

constructed@coefficients
root_table(roots(constructed))

## ----maintenance-flow, echo=FALSE---------------------------------------------
render_mermaid("
flowchart TD
    A[Updated forecast issue reported]
    B[Obtain operational parameters]
    C[Assess roots and timescales]
    D{Parameters fail?}
    E[Recalibrate or replace]
    F[Check input errors]
    G[Check gaps and ratings]
    H[Check cut-off and model dependencies]
    I[Implement through model maintenance]

    A --> B --> C --> D
    D -- Yes --> E --> I
    D -- No --> F --> G --> H --> I
")

## ----response-components------------------------------------------------------
response_data <- response_components(
  parameters,
  ma_parameters = c(-0.5, -0.25, -0.125),
  steps = 100L
)

ggplot(response_data, aes(step, response, colour = component)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line() +
  theme_minimal()

