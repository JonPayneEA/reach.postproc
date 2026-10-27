# Estimate an ET-AR event response time from catchment time-to-peak

Convert a catchment time-to-peak directly into the `response_time_steps`
argument of
[`event_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/event_ar_parameters.md),
on the assumption that the event-condition AR root should decay on
roughly the timescale the catchment itself takes to reach peak flow.

## Usage

``` r
response_time_steps_from_tp(
  time_to_peak,
  time_step_minutes = 15,
  time_to_peak_units = c("hours", "minutes")
)
```

## Arguments

- time_to_peak:

  Positive numeric catchment time-to-peak, in the units given by
  `time_to_peak_units`.

- time_step_minutes:

  Minutes represented by one model timestep.

- time_to_peak_units:

  Units of `time_to_peak`. `"hours"` (default) or `"minutes"`.

## Value

A single positive numeric response-time estimate in model timesteps,
suitable as `response_time_steps` for
[`event_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/event_ar_parameters.md).

## Status

temporary. Time-to-peak (rainfall-to-peak-flow) and AR decay time
(forecast-error persistence) are different physical quantities; equating
them here is a modelling approximation, not a derived equivalence. This
function exists so that approximation has one place to live, rather than
being re-implemented ad hoc in calibration scripts for individual
gauges. It belongs in `reach.hydro` once that module has a proper FEH or
unit-hydrograph time-to-peak calculation to draw on, and it should move
there rather than be extended in place.
[`feh_time_to_peak()`](https://jonpayneea.github.io/reach.postproc/reference/feh_time_to_peak.md)
is now available as that calculation, so `time_to_peak` no longer has to
be a guess – but it does not make the approximation this function itself
makes any less of one: supplying a proper FEH time-to-peak only improves
the input, not the physical assumption that an AR decay root should
match it. Whatever this function returns is a starting estimate, not a
validated parameter: check it with
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
and against historic events with
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
/
[`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md)
before operational use.

## See also

[`feh_time_to_peak()`](https://jonpayneea.github.io/reach.postproc/reference/feh_time_to_peak.md)
for a defensible `time_to_peak` source,
[`event_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/event_ar_parameters.md)

## Examples

``` r
response_time_steps_from_tp(time_to_peak = 12, time_step_minutes = 15)
#> [1] 48
event_ar_parameters(
  response_time_steps = response_time_steps_from_tp(12, time_step_minutes = 15)
)
#> <reach.postproc::ARParameterSet>
#>  @ coefficients   : Named num [1:3] 1.7547 -0.7183 -0.0402
#>  .. - attr(*, "names")= chr [1:3] "a_1" "a_2" "a_3"
#>  @ order          : int 3
#>  @ sign_convention: chr "Deltares"
#>  @ order_tolerance: num 1e-10
#>  @ label          : chr "ET-AR event parameters"

# From FEH catchment descriptors, rather than a guessed time-to-peak:
catchment_tp <- feh_time_to_peak(
  propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003
)
response_time_steps_from_tp(catchment_tp, time_step_minutes = 15)
#> [1] 8.340321
```
