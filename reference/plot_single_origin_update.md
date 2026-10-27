# Plot a single-origin AR update against observed and simulated series

Overlay observed, simulated and updated values on one time axis, with a
marker at the forecast origin.

## Usage

``` r
plot_single_origin_update(x, include_ar_error = FALSE)
```

## Arguments

- x:

  A result from
  [`single_origin_ar_update()`](https://jonpayneea.github.io/reach.postproc/reference/single_origin_ar_update.md).

- include_ar_error:

  Logical. If `TRUE`, also draw the raw AR correction (`ar_error`) as a
  dotted line. Default `FALSE`: the correction is usually a much smaller
  magnitude than `observed`, `simulated` and `updated`, and crowds the
  same axis badly.

## Value

A `ggplot` object.

## See also

[`single_origin_ar_update()`](https://jonpayneea.github.io/reach.postproc/reference/single_origin_ar_update.md)

## Examples

``` r
time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:40 * 900
simulation <- 0.8 + sin(0:40 / 12)
observation <- simulation + c(rep(0.1, 20), rep(0.05, 21))
aligned <- align_forecast_series(
  data.frame(date_time = time, value = observation),
  data.frame(date_time = time, value = simulation),
  interval_minutes = 15
)
result <- single_origin_ar_update(default_ar_parameters(), aligned, origin = 21L)
plot_single_origin_update(result)
#> Warning: Removed 20 rows containing missing values or values outside the scale range
#> (`geom_line()`).
```
