# Alignment diagnostics

Extract the tabular data from a structured package result without
exposing callers to its internal S7 property layout.

## Usage

``` r
alignment_diagnostics(x)
```

## Arguments

- x:

  an aligned-series result returned by
  [`align_forecast_series()`](https://jonpayneea.github.io/reach.postproc/reference/align_forecast_series.md).

## Value

a copied one-row diagnostic table reporting matched rows, missing
values, duplicates and timestep checks. The returned table is a copy and
may be modified safely.

## Examples

``` r
alignment_diagnostics(align_forecast_series(data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 1), data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 0.9)))
#>    observed_rows simulated_rows aligned_rows missing_observed missing_simulated
#>            <int>          <int>        <int>            <int>             <int>
#> 1:             1              1            1                0                 0
#>    regular_time_step
#>               <lgcl>
#> 1:                NA
```
