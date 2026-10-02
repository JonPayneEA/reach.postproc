# Return a published standard default-family AR parameter set

Select one of the named standard parameter sets from the published
default family. Use this function where operational standardisation is
more important than matching a bespoke catchment timescale exactly.

## Usage

``` r
standard_family_ar_parameters(
  principal_decay = c("3 hours", "6 hours", "12 hours", "1 day", "2 days", "4 days",
    "8 days", "16 days", "32 days", "64 days", "Infinite"),
  time_step_minutes = 15
)
```

## Arguments

- principal_decay:

  Standard principal decay label. Accepted values are `"3 hours"`,
  `"6 hours"`, `"12 hours"`, `"1 day"`, `"2 days"`, `"4 days"`,
  `"8 days"`, `"16 days"`, `"32 days"`, `"64 days"` and `"Infinite"`.

- time_step_minutes:

  Duration of one model timestep in minutes. The labels above are fixed
  durations (for example "12 hours"), but how many model steps that
  represents, and therefore the resulting AR coefficients, depends on
  this value. Must match the timestep of the model the parameters will
  actually run in; it is not just metadata.

## Value

An AR parameter object calculated from the analytical default-family
construction at the selected standard timescale.

## Examples

``` r
parameters <- standard_family_ar_parameters("12 hours")
parameters@coefficients
#>         a_1         a_2         a_3 
#>  1.76500000 -0.72782773 -0.04073482 
root_table(roots(parameters))
#>    root_id   root_real root_imaginary root_modulus lag_root_real
#>      <int>       <num>          <num>        <num>         <num>
#> 1:       3  0.97938218  -1.266620e-24   0.97938218      1.021052
#> 2:       2  0.83540489   1.473415e-24   0.83540489      1.197024
#> 3:       1 -0.04978707  -2.067952e-25   0.04978707    -20.085537
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:       1.320511e-24         1.021052           48.0000000       48.0000000
#> 2:      -2.111209e-24         1.197024            5.5605360        5.5605360
#> 3:       8.342712e-23        20.085537            0.3333333        0.3333333
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                 48.0000000      12.00000000                12.00000000
#> 2:                  5.5605360       1.39013401                 1.39013401
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
