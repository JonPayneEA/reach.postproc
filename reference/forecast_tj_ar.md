# Forecast a Time Jumped AR error series

Estimate modal weights from non-consecutive historic errors separated by
`jump` timesteps, then project the characteristic-root solution
forwards.

## Usage

``` r
forecast_tj_ar(
  parameters,
  error_history,
  jump = 1L,
  steps = 480L,
  time_step_minutes = 15
)
```

## Arguments

- parameters:

  An AR parameter set.

- error_history:

  Numeric error history supplied newest first. It must contain at least
  `1 + (order - 1) * jump` values.

- jump:

  Positive whole number of timesteps between selected errors. Use `1L`
  for conventional consecutive-error AR.

- steps:

  Positive whole number of projected timesteps.

- time_step_minutes:

  Minutes represented by one timestep.

## Value

An object of class `tj_ar_forecast` containing selected inputs, modal
weights, root contributions and projected error.

## Examples

``` r
history <- c(0.20, 0.19, 0.23, 0.18, 0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.11)
result <- forecast_tj_ar(default_ar_parameters(), history, jump = 5L, steps = 24L)
tj_ar_series(result)
#>      step lead_time_minutes lead_time_hours  ar_error
#>     <int>             <num>           <num>     <num>
#>  1:     1                15            0.25 0.2032683
#>  2:     2                30            0.50 0.2055681
#>  3:     3                45            0.75 0.2070729
#>  4:     4                60            1.00 0.2079258
#>  5:     5                75            1.25 0.2082447
#>  6:     6                90            1.50 0.2081271
#>  7:     7               105            1.75 0.2076531
#>  8:     8               120            2.00 0.2068891
#>  9:     9               135            2.25 0.2058896
#> 10:    10               150            2.50 0.2046995
#> 11:    11               165            2.75 0.2033561
#> 12:    12               180            3.00 0.2018898
#> 13:    13               195            3.25 0.2003259
#> 14:    14               210            3.50 0.1986851
#> 15:    15               225            3.75 0.1969844
#> 16:    16               240            4.00 0.1952381
#> 17:    17               255            4.25 0.1934575
#> 18:    18               270            4.50 0.1916522
#> 19:    19               285            4.75 0.1898301
#> 20:    20               300            5.00 0.1879974
#> 21:    21               315            5.25 0.1861596
#> 22:    22               330            5.50 0.1843208
#> 23:    23               345            5.75 0.1824846
#> 24:    24               360            6.00 0.1806538
#>      step lead_time_minutes lead_time_hours  ar_error
#>     <int>             <num>           <num>     <num>
```
