# Construct an Event Triggered AR configuration

Pair the steady-condition and event-condition AR parameter sets with one
trigger definition. Forecasts begin with `steady_parameters` and switch
once to `event_parameters` when the trigger first becomes true. They do
not switch back within the same forecast.

## Usage

``` r
et_ar_configuration(
  steady_parameters,
  event_parameters,
  trigger,
  label = "ET-AR configuration",
  metadata = list()
)
```

## Arguments

- steady_parameters:

  An AR parameter set created by
  [`ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters.md)
  or
  [`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md).
  It should have a long principal decay time suitable for slowly
  changing errors under steady conditions.

- event_parameters:

  An AR parameter set with the same AR order as `steady_parameters`. Its
  principal decay time should reflect the catchment response time under
  event conditions.

- trigger:

  A trigger object created by
  [`logical_et_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/logical_et_trigger.md),
  [`rainfall_accumulation_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/rainfall_accumulation_trigger.md),
  [`updated_threshold_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/updated_threshold_trigger.md)
  or
  [`cwi_adjusted_rainfall_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/cwi_adjusted_rainfall_trigger.md).

- label:

  A short character description retained in the result metadata.

- metadata:

  A named list containing identifiers and provenance, such as site,
  model version, response-time source, calibration date and reviewer.

## Value

An object of class `et_ar_configuration`.

## Examples

``` r
steady <- ar_parameters_from_timescales(
  decay_times = c(Inf, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2)
)
event <- ar_parameters_from_timescales(
  decay_times = c(48, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2)
)
trigger <- logical_et_trigger(c(FALSE, FALSE, TRUE, TRUE))
config <- et_ar_configuration(steady, event, trigger)
```
