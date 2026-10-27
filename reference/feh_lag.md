# Estimate FEH lag from time-to-peak

Convert an FEH time-to-peak into the corresponding FEH lag, via the
published regression relationship between the two.

## Usage

``` r
feh_lag(time_to_peak)
```

## Arguments

- time_to_peak:

  Positive numeric time-to-peak, in hours (as returned by
  [`feh_time_to_peak()`](https://jonpayneea.github.io/reach.postproc/reference/feh_time_to_peak.md)).

## Value

One positive numeric lag, in hours.

## See also

[`feh_time_to_peak()`](https://jonpayneea.github.io/reach.postproc/reference/feh_time_to_peak.md)

## Examples

``` r
feh_lag(2.085080)
#> [1] 2.480062
```
