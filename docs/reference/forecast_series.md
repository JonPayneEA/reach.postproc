# Forecast series

Extract the tabular data from a structured package result without
exposing callers to its internal S7 property layout.

## Usage

``` r
forecast_series(x)
```

## Arguments

- x:

  an AR forecast result returned by
  [`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md).

## Value

a copied `data.table` containing forecast step, lead time and projected
error. The returned table is a copy and may be modified safely.

## Examples

``` r
forecast_series(forecast_ar(default_ar_parameters(), initial_errors = c(0.15, 0.12, 0.10), steps = 4L))
#>     step lead_time_minutes lead_time_hours  ar_error
#>    <int>             <num>           <num>     <num>
#> 1:     1                15            0.25 0.1735344
#> 2:     2                30            0.50 0.1924720
#> 3:     3                45            0.75 0.2075853
#> 4:     4                60            1.00 0.2195501
```
