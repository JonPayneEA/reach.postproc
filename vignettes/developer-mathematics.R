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

## ----validation-flow, echo=FALSE----------------------------------------------
render_mermaid("
flowchart LR
    A[Parameters] --> B[Modal roots] --> C[Reconstructed parameters]
    D[AR recurrence] --> E[Modal decomposition]
    F[Fixed-lead recurrence] --> G[Fixed-lead root projection]
    H[ARMA recurrence] --> I[Impulse response]
")

## ----developer-roundtrip------------------------------------------------------
p1 <- default_ar_parameters()
z1 <- roots(p1)@values
p2 <- roots_to_parameters(z1)
z2 <- roots(p2)@values

p1@coefficients
p2@coefficients

## ----developer-decomposition--------------------------------------------------
parameters <- default_ar_parameters()
forecast <- forecast_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 100L
)

components <- decompose_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 100L
)

reconstructed <- components[
  ,
  .(value = sum(contribution_real)),
  by = step
]

all.equal(
  reconstructed$value,
  forecast_series(forecast)$ar_error,
  tolerance = 1e-9
)

