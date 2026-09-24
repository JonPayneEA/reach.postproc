# Decompose an AR forecast into characteristic-root contributions

Express the projected AR error as the sum of the modal contributions
implied by the characteristic roots. This supports mathematical
interpretation and verification of the recurrence.

## Usage

``` r
decompose_ar(x, ..., initial_errors, steps = 480L, time_step_minutes = 15)
```

## Arguments

- x:

  An AR parameter object.

- ...:

  Additional method arguments; currently unused.

- initial_errors:

  Numeric recent errors supplied newest first. Length must equal AR
  order.

- steps:

  Positive whole number of forecast steps to return.

- time_step_minutes:

  Minutes represented by one step.

## Value

A long `data.table` with one row per root and forecast step. Summing
`contribution_real` by `step` reconstructs
[`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md).
Modal time zero corresponds to forecast step one.

## Examples

``` r
parameters <- default_ar_parameters()

contributions <- decompose_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 24L
)

contributions[
  ,
  .(projected_error = sum(contribution_real)),
  by = step
]
#>      step projected_error
#>     <int>           <num>
#>  1:     1       0.2399969
#>  2:     2       0.2722461
#>  3:     3       0.2980855
#>  4:     4       0.3186448
#>  5:     5       0.3348550
#>  6:     6       0.3474844
#>  7:     7       0.3571667
#>  8:     8       0.3644248
#>  9:     9       0.3696901
#> 10:    10       0.3733186
#> 11:    11       0.3756038
#> 12:    12       0.3767879
#> 13:    13       0.3770708
#> 14:    14       0.3766172
#> 15:    15       0.3755630
#> 16:    16       0.3740203
#> 17:    17       0.3720814
#> 18:    18       0.3698226
#> 19:    19       0.3673065
#> 20:    20       0.3645850
#> 21:    21       0.3617007
#> 22:    22       0.3586887
#> 23:    23       0.3555778
#> 24:    24       0.3523919
#>      step projected_error
#>     <int>           <num>
```
