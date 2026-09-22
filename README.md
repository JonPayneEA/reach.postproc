# reach.postproc

`reach.postproc` provides S7 classes, data.table outputs and ggplot2 plots for AR and ARMA flood-forecast post-processing.

## Main workflow

```r
library(reach.postproc)
parameters <- default_ar_parameters()
roots(parameters)@table
assess(parameters)@tests
forecast <- forecast_ar(parameters, initial_errors = c(0.20, 0.15, 0.10))
plot_ar(forecast)
```

## Added from the original assessment tool

- Deltares and standard sign conventions.
- Automatic effective-order detection.
- Effective decay times.
- Configurable assessment using effective or exponential decay.
- Configurable permitted model orders.
- Mixed root and coefficient solving.
- Time-aligned complete-series updates.
- AR, MA and ARMA response components.
- Optional `afcolours` use in the walkthrough.

The complete walkthrough is in `inst/examples/01_arma_walkthrough.R`.


## Package boundaries

`reach.postproc` does not import source data or evaluate ratings. Use `reach.io` to ingest and standardise observed and simulated data. Use `reach.rate` to convert between level and flow. Pass the resulting aligned-domain series to `reach.postproc`.

## Fixed lead-time analysis

```r
event <- align_forecast_series(observed, simulated, interval_minutes = 15)
results <- fixed_lead_ar(
  parameters = default_ar_parameters(),
  data = event,
  lead_times_minutes = c(30, 60, 90),
  time_step_minutes = 15,
  site_name = "Parkend",
  measure = "level"
)
score_lead_times(results)
plot_lead_times(results)
```

The recurrence is the production method. `method = "roots"` exists as an independently formulated verification route. Tests require both methods to agree.


## Walkthrough structure

The installed walkthrough now contains two complete routes:

1. A reproducible mathematical example using synthetic data.
2. An operational event workflow showing the `reach.io` to optional `reach.rate` to `reach.postproc` boundary.

The operational route includes alignment diagnostics, fixed lead-time calculations, MAE, RMSE and bias scoring, threshold plotting, recurrence-versus-root diagnostics and optional output export.

Run it with:

```r
source(
  system.file(
    "examples",
    "01_arma_walkthrough.R",
    package = "reach.postproc"
  )
)
```
