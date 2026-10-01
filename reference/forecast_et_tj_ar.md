# Forecast combined Event Triggered and Time Jumped AR

Use TJ-AR to infer a noise-resistant recent consecutive state, then
continue with the ET-AR recurrence and its one-way parameter switch.

## Usage

``` r
forecast_et_tj_ar(
  configuration,
  error_history,
  jump = 1L,
  simulated,
  time = seq_along(simulated),
  lower_limit = NULL,
  time_step_minutes = 15
)
```

## Arguments

- configuration:

  An ET-AR configuration.

- error_history:

  Complete recent error history supplied newest first.

- jump:

  Positive timestep separation used to select TJ-AR inputs.

- simulated, time, lower_limit, time_step_minutes:

  As in
  [`forecast_et_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_et_ar.md).

## Value

An `et_ar_forecast` with TJ-AR initialisation details attached.

## Examples

``` r
history <- seq(0.2, 0.05, length.out = 20)
config <- et_ar_configuration(
  default_et_ar_steady_parameters(), event_ar_parameters(48),
  logical_et_trigger(c(FALSE, FALSE, TRUE, rep(TRUE, 9)))
)
result <- forecast_et_tj_ar(config, history, jump = 5L, simulated = rep(1, 12))
```
