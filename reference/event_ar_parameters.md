# Construct ET-AR event parameters from catchment response time

Retain the standard middle and fast roots while setting the principal
decay time from a catchment response estimate.

## Usage

``` r
event_ar_parameters(
  response_time_steps,
  middle_decay_steps = 5.203171,
  fast_decay_steps = 1/3,
  label = "ET-AR event parameters"
)
```

## Arguments

- response_time_steps:

  Positive response time in model timesteps. For a 15-minute model, 48
  steps represent 12 hours.
  [`response_time_steps_from_tp()`](https://jonpayneea.github.io/reach.postproc/reference/response_time_steps_from_tp.md)
  offers one temporary, approximate way to derive this from
  time-to-peak.

- middle_decay_steps:

  Decay time of the intermediate positive root.

- fast_decay_steps:

  Decay time of the rapid negative root.

- label:

  Description attached to the result.

## Value

An AR(3) parameter object.

## Examples

``` r
event <- event_ar_parameters(response_time_steps = 48)
root_table(roots(event, time_step_minutes = 15))
#>    root_id   root_real root_imaginary root_modulus lag_root_real
#>      <int>       <num>          <num>        <num>         <num>
#> 1:       3  0.97938218  -1.173320e-24   0.97938218      1.021052
#> 2:       2  0.82514967   1.380115e-24   0.82514967      1.211901
#> 3:       1 -0.04978707  -2.067952e-25   0.04978707    -20.085537
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:       1.223241e-24         1.021052           48.0000000       48.0000000
#> 2:      -2.026982e-24         1.211901            5.2031710        5.2031710
#> 3:       8.342712e-23        20.085537            0.3333333        0.3333333
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                 48.0000000      12.00000000                12.00000000
#> 2:                  5.2031710       1.30079275                 1.30079275
#> 3:                  0.2338711       0.08333333                 0.05846776
#>    oscillation_period_steps oscillation_period_hours is_growing is_persistent
#>                       <num>                    <num>     <lgcl>        <lgcl>
#> 1:                      Inf                      Inf      FALSE         FALSE
#> 2:                      Inf                      Inf      FALSE         FALSE
#> 3:                        2                      0.5      FALSE         FALSE
#>    is_oscillating modal_stability lag_stability display_order
#>            <lgcl>          <fctr>        <fctr>         <int>
#> 1:          FALSE          Stable        Stable             1
#> 2:          FALSE          Stable        Stable             2
#> 3:           TRUE          Stable        Stable             3
```
