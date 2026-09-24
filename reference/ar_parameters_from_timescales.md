# Construct AR parameters from root timescales

Build interpretable modal roots from decay times and oscillation
periods, then convert those roots to Deltares AR coefficients.

## Usage

``` r
ar_parameters_from_timescales(
  decay_times,
  oscillation_periods = rep(Inf, length(decay_times)),
  label = "Derived from timescales",
  tolerance = 1e-10
)
```

## Arguments

- decay_times:

  Numeric vector of decay times in model steps, one value per required
  root.

- oscillation_periods:

  Numeric vector of matching periods in model steps. Use `Inf` for
  non-oscillating positive roots and `2` for negative real roots.

- label:

  Description attached to the result.

- tolerance:

  Numerical tolerance used during root-to-coefficient conversion.

## Value

An AR parameter object whose order equals the number of supplied roots
after numerical trimming.

## Examples

``` r
parameters <- ar_parameters_from_timescales(
  decay_times = c(96, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2),
  label = "Example AR(3)"
)

parameters@coefficients
#>         a_1         a_2         a_3 
#>  1.76500000 -0.72624604 -0.04065607 
root_table(roots(parameters))
#>    root_id   root_real root_imaginary root_modulus lag_root_real
#>      <int>       <num>          <num>        <num>         <num>
#> 1:       3  0.98963740  -2.019484e-28   0.98963740      1.010471
#> 2:       2  0.82514967   2.019484e-28   0.82514967      1.211901
#> 3:       1 -0.04978707   0.000000e+00   0.04978707    -20.085537
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:       2.061998e-28         1.010471           96.0000000       96.0000000
#> 2:      -2.966026e-28         1.211901            5.2031710        5.2031710
#> 3:       0.000000e+00        20.085537            0.3333333        0.3333333
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                 96.0000000      24.00000000                24.00000000
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
