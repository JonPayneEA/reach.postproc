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

## ----overview-flow, echo=FALSE------------------------------------------------
render_mermaid("
flowchart LR
    A[Observation]
    B[Model simulation]
    C[Recent model error]
    D[AR model]
    E[Projected error]
    F[Updated forecast]

    A --> C
    B --> C
    C --> D --> E --> F
    B --> F
")

## ----novice-error-------------------------------------------------------------
calculate_model_error(
  observed = c(1.20, 0.95),
  simulated = c(1.00, 1.10)
)

## ----novice-ar1---------------------------------------------------------------
simple_parameters <- ar_parameters(
  coefficients = c(a_1 = 0.8),
  label = "Simple AR(1) example"
)

simple_forecast <- forecast_ar(
  simple_parameters,
  initial_errors = 0.20,
  steps = 24L,
  time_step_minutes = 15
)

forecast_series(simple_forecast)
plot_ar(simple_forecast)

## ----history-flow, echo=FALSE-------------------------------------------------
render_mermaid("
flowchart LR
    A[Oldest recent error]
    B[Middle recent error]
    C[Newest recent error]
    D[Weighted AR calculation]
    E[Next projected error]
    F[Repeat]

    A --> D
    B --> D
    C --> D
    D --> E --> F
")

## ----novice-defaults----------------------------------------------------------
parameters <- default_ar_parameters()
root_information <- roots(parameters)

root_table(root_information)
plot_ar(root_information, root_definition = "modal")

## ----conventions-flow, echo=FALSE---------------------------------------------
render_mermaid("
flowchart TD
    A{Which root definition?}
    B[EA modal roots]
    C[Reciprocal lag roots]
    D[Stable inside the circle]
    E[Stable outside the circle]

    A --> B --> D
    A --> C --> E
")

## ----novice-assessment-flow, echo=FALSE---------------------------------------
render_mermaid("
flowchart TD
    A[Start assessment]
    B{Any growing root?}
    C{Any root decays too slowly?}
    D{Do all roots decay too quickly?}
    E{Any unacceptable oscillation?}
    F[FAIL]
    G[PASS]

    A --> B
    B -- Yes --> F
    B -- No --> C
    C -- Yes --> F
    C -- No --> D
    D -- Yes --> F
    D -- No --> E
    E -- Yes --> F
    E -- No --> G
")

## ----novice-assessment--------------------------------------------------------
assessment <- assess(parameters)
assessment@summary
assessment_table(assessment)

## ----cutoff-flow, echo=FALSE--------------------------------------------------
render_mermaid("
flowchart LR
    A[Simulation]
    B[Projected error]
    C[Add values]
    D{Below zero?}
    E[Display zero]
    F[Display calculated value]
    G[Underlying AR series continues]

    A --> C
    B --> C
    C --> D
    D -- Yes --> E --> G
    D -- No --> F
")

## ----lead-flow, echo=FALSE----------------------------------------------------
render_mermaid("
flowchart LR
    A[Choose target time]
    B[Move back by fixed lead]
    C[Read errors available then]
    D[Project through the lead]
    E[Update target simulation]
    F[Repeat for every target]

    A --> B --> C --> D --> E --> F
")

## ----complete-flow, echo=FALSE------------------------------------------------
render_mermaid("
flowchart TD
    A([Start]) --> B[Load approved parameters]
    B --> C[Assess parameters]
    C --> D{Pass?}
    D -- No --> E[Review or replace parameters]
    D -- Yes --> F[Import observation and simulation]
    F --> G{Same domain and units?}
    G -- No --> H[Convert with reach.rate]
    G -- Yes --> I[Align series]
    H --> I
    I --> J{Diagnostics acceptable?}
    J -- No --> K[Fix gaps, timestamps or duplicates]
    K --> I
    J -- Yes --> L[Calculate fixed lead-time updates]
    L --> M[Score performance]
    M --> N[Plot and interpret]
    N --> O{Improves representative events?}
    O -- Yes --> P[Document evidence and use with judgement]
    O -- No --> Q[Review data, parameters and model structure]
")

