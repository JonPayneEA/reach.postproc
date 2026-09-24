# Aligned series

Extract the tabular data from a structured package result without
exposing callers to its internal S7 property layout.

## Usage

``` r
aligned_series(x)
```

## Arguments

- x:

  an aligned-series result returned by
  [`align_forecast_series()`](https://jonpayneea.github.io/reach.postproc/reference/align_forecast_series.md).

## Value

a copied `data.table` containing timestamps, observations, simulations
and errors. The returned table is a copy and may be modified safely.

## Examples

``` r
aligned_series(align_forecast_series(data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 1), data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 0.9)))
#> Key: <date_time>
#>     date_time observed simulated error
#>        <POSc>    <num>     <num> <num>
#> 1: 2024-01-01        1       0.9   0.1
```
