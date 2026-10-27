# Project a single AR update forward from one forecast origin

Seed the AR recurrence from the real errors immediately before a chosen
origin, then project it forward continuously to the end of the supplied
series – one forecast, issued once, rather than a retrospective,
every-timestep reconstruction. Compare with
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md),
which answers a different question (see Details).

## Usage

``` r
single_origin_ar_update(
  parameters,
  data,
  origin,
  lower_limit = NULL,
  time_step_minutes = 15
)
```

## Arguments

- parameters:

  An AR parameter object.

- data:

  An aligned-series result from
  [`align_forecast_series()`](https://jonpayneea.github.io/reach.postproc/reference/align_forecast_series.md),
  or a table with `date_time`, `observed` and `simulated` columns.

- origin:

  The forecast origin: either a single `POSIXct` matching one row of
  `data`'s `date_time` column, or a single positive integer row index.
  This is the first row the projection fills in; the `order` rows
  immediately before it supply the seed errors (observed minus
  simulated), newest first, exactly as `initial_errors` is supplied
  elsewhere in this package.

- lower_limit:

  Optional scalar lower bound applied to the displayed update, as in
  [`apply_ar_update()`](https://jonpayneea.github.io/reach.postproc/reference/apply_ar_update.md).

- time_step_minutes:

  Minutes represented by one model timestep.

## Value

A `data.table` with one row per row of `data`: `date_time`, `observed`,
`simulated`, `ar_error`, `updated_unconstrained` and `updated`. The last
three are `NA` before `origin`. Carries `origin_index`,
`origin_date_time` and `initial_errors` as attributes (provenance for
this call's own output only, as elsewhere in this package – they do not
survive the table being reconstructed elsewhere).

## Details

This is not a replacement for
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md).
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
reconstructs what a fixed-lead update would have said at *every*
timestep, for scoring. `single_origin_ar_update()` issues exactly *one*
forecast, at exactly *one* origin, and lets the AR recurrence run
forward uninterrupted to the end of the data – closer to what an
operational forecaster actually sees: one update, right now, projected
as far forward as the series goes. Rows before the origin are returned
with `NA` in the update columns; nothing is retrospectively
reconstructed for them.

## See also

[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
for retrospective, every-timestep scoring,
[`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md),
[`apply_ar_update()`](https://jonpayneea.github.io/reach.postproc/reference/apply_ar_update.md),
[`plot_single_origin_update()`](https://jonpayneea.github.io/reach.postproc/reference/plot_single_origin_update.md)

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

result <- single_origin_ar_update(
  default_ar_parameters(), aligned, origin = 21L
)
tail(result)
#>              date_time  observed simulated   ar_error updated_unconstrained
#>                 <POSc>     <num>     <num>      <num>                 <num>
#> 1: 2024-01-01 08:45:00 1.0730342 1.0230342 0.08874431             1.1117785
#> 2: 2024-01-01 09:00:00 0.9911200 0.9411200 0.08786189             1.0289819
#> 3: 2024-01-01 09:15:00 0.9082264 0.8582264 0.08698179             0.9452082
#> 4: 2024-01-01 09:30:00 0.8249286 0.7749286 0.08610517             0.8610338
#> 5: 2024-01-01 09:45:00 0.7418049 0.6918049 0.08523298             0.7770378
#> 6: 2024-01-01 10:00:00 0.6594320 0.6094320 0.08436601             0.6937980
#>      updated
#>        <num>
#> 1: 1.1117785
#> 2: 1.0289819
#> 3: 0.9452082
#> 4: 0.8610338
#> 5: 0.7770378
#> 6: 0.6937980
```
