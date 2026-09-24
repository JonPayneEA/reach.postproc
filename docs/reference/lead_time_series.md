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
# See fixed_lead_ar() for a complete construction example.
# lead_time_series(result)
```
