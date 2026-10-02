# Lead time series

Extract the tabular data from a structured package result without
exposing callers to its internal S7 property layout.

## Usage

``` r
lead_time_series(x)
```

## Arguments

- x:

  a fixed lead-time result returned by
  [`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md).

## Value

a copied long `data.table` containing observations, simulations,
projected errors and updates by lead. The returned table is a copy and
may be modified safely.

## Examples

``` r
time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:80 * 900
simulation <- 0.8 + sin(0:80 / 12)
observation <- simulation + 0.1
aligned <- align_forecast_series(
  data.frame(date_time = time, value = observation),
  data.frame(date_time = time, value = simulation),
  interval_minutes = 15
)
result <- fixed_lead_ar(
  default_ar_parameters(), aligned,
  lead_times_minutes = c(30, 60), time_step_minutes = 15
)
head(lead_time_series(result))
#>              date_time lead_time_minutes  observed simulated   ar_error
#>                 <POSc>             <num>     <num>     <num>      <num>
#> 1: 2024-01-01 00:00:00                30 0.9000000 0.8000000         NA
#> 2: 2024-01-01 00:15:00                30 0.9832369 0.8832369         NA
#> 3: 2024-01-01 00:30:00                30 1.0658961 0.9658961         NA
#> 4: 2024-01-01 00:45:00                30 1.1474040 1.0474040         NA
#> 5: 2024-01-01 01:00:00                30 1.2271947 1.1271947 0.09947299
#> 6: 2024-01-01 01:15:00                30 1.3047146 1.2047146 0.09947299
#>    updated_unconstrained  updated calculation_method
#>                    <num>    <num>             <char>
#> 1:                    NA       NA         recurrence
#> 2:                    NA       NA         recurrence
#> 3:                    NA       NA         recurrence
#> 4:                    NA       NA         recurrence
#> 5:              1.226668 1.226668         recurrence
#> 6:              1.304188 1.304188         recurrence
```
