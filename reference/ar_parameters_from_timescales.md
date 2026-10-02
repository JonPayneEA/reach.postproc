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

  Numeric vector of decay times in model steps, one value per requested
  root (before conjugate pairing).

- oscillation_periods:

  Numeric vector of matching periods in model steps. Use `Inf` for a
  non-oscillating positive root and `2` for a negative real root. Any
  other value (for example `8`, for a root that completes one
  oscillation every eight steps) requests a genuinely complex pair.

- label:

  Description attached to the result.

- tolerance:

  Numerical tolerance used during root-to-coefficient conversion.

## Value

An AR parameter object. Its order equals `length(decay_times)` plus one
for every entry that requested a genuinely complex root (any period
other than `Inf` or `2`), after numerical trimming.

## Details

An oscillation period of `Inf` or `2` produces a single real root (see
[`root_from_timescale()`](https://jonpayneea.github.io/reach.postproc/reference/root_from_timescale.md))
and contributes one root to the result. Any other period produces a
genuinely complex root; since a real AR polynomial can only contain
complex roots in conjugate pairs, its conjugate is added automatically.
Each such entry therefore contributes **two** roots to the result, so
the AR order can exceed `length(decay_times)`.

## Examples

``` r
parameters <- ar_parameters_from_timescales(
  decay_times = c(96, 5.203171, 1 / 3),
  oscillation_periods = c(Inf, Inf, 2),
  label = "Example AR(3), all real roots"
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

# A genuinely oscillating root: one timescale, one period, but the
# conjugate is added automatically, so this is an AR(2) model.
oscillating <- ar_parameters_from_timescales(
  decay_times = 20,
  oscillation_periods = 8,
  label = "Example AR(2), oscillating pair"
)
oscillating@order
#> [1] 2
root_table(roots(oscillating))
#>    root_id root_real root_imaginary root_modulus lag_root_real
#>      <int>     <num>          <num>        <num>         <num>
#> 1:       2 0.6726208     -0.6726208    0.9512294     0.7433609
#> 2:       1 0.6726208      0.6726208    0.9512294     0.7433609
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:          0.7433609         1.051271                   20               20
#> 2:         -0.7433609         1.051271                   20               20
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                   1.481367                5                  0.3703418
#> 2:                   1.481367                5                  0.3703418
#>    oscillation_period_steps oscillation_period_hours is_growing is_persistent
#>                       <num>                    <num>     <lgcl>        <lgcl>
#> 1:                        8                        2      FALSE         FALSE
#> 2:                        8                        2      FALSE         FALSE
#>    is_oscillating modal_stability lag_stability display_order
#>            <lgcl>          <fctr>        <fctr>         <int>
#> 1:           TRUE          Stable        Stable             1
#> 2:           TRUE          Stable        Stable             2
```
