# Default steady-condition parameters for ET-AR

Construct the Part 2 steady-condition AR(3) parameters with an infinite
principal decay time and the established middle and fast root behaviour.

## Usage

``` r
default_et_ar_steady_parameters(
  label = "ET-AR steady parameters: infinite principal decay"
)
```

## Arguments

- label:

  Description attached to the parameter set.

## Value

An AR parameter object.

## Examples

``` r
steady <- default_et_ar_steady_parameters()
root_table(roots(steady))
#>    root_id   root_real root_imaginary root_modulus lag_root_real
#>      <int>       <num>          <num>        <num>         <num>
#> 1:       3  0.99999969   2.356286e-14   0.99999969      1.000000
#> 2:       2  0.81478737  -2.356286e-14   0.81478737      1.227314
#> 3:       1 -0.04978707   0.000000e+00   0.04978707    -20.085538
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:      -2.356288e-14         1.000000         3.240563e+06     3.240563e+06
#> 2:       3.549274e-14         1.227314         4.882143e+00     4.882143e+00
#> 3:       0.000000e+00        20.085538         3.333333e-01     3.333333e-01
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:               3.240563e+06     8.101408e+05               8.101408e+05
#> 2:               4.882143e+00     1.220536e+00               1.220536e+00
#> 3:               2.338710e-01     8.333333e-02               5.846776e-02
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
