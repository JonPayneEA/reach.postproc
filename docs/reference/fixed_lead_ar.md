# Calculate fixed lead-time AR updates

Reconstruct what the updated forecast would have said at each target
time had it always started a fixed number of minutes earlier.

## Usage

``` r
fixed_lead_ar(
  parameters,
  data,
  lead_times_minutes = c(30, 60, 90),
  time_step_minutes = 15,
  lower_limit = NULL,
  method = c("recurrence", "roots"),
  metadata = list()
)
```

## Arguments

- parameters:

  An assessed AR parameter object.

- data:

  An aligned-series result from
  [`align_forecast_series()`](https://jonpayneea.github.io/reach.postproc/reference/align_forecast_series.md)
  or a table with `date_time`, `observed` and `simulated` columns.

- lead_times_minutes:

  Positive numeric lead times. Every value must be an exact multiple of
  `time_step_minutes`.

- time_step_minutes:

  Minutes represented by one model timestep.

- lower_limit:

  Optional lower bound applied to the displayed update.

- method:

  Calculation method. `"recurrence"` is the production route. `"roots"`
  provides an independent mathematical comparison where supported.

- metadata:

  Named list of site, model and event identifiers attached to the
  result.

## Value

A fixed lead-time result. Use
[`lead_time_series()`](https://jonpayneea.github.io/reach.postproc/reference/lead_time_series.md),
[`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md)
and
[`plot_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/plot_lead_times.md)
to inspect it.

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
  default_ar_parameters(),
  aligned,
  lead_times_minutes = c(30, 60),
  time_step_minutes = 15
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
#>     updated
#>       <num>
#> 1:       NA
#> 2:       NA
#> 3:       NA
#> 4:       NA
#> 5: 1.226668
#> 6: 1.304188
```
