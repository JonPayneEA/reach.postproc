# Align observed and simulated forecast series

Join observations and simulations by timestamp, calculate model error
and report diagnostics before fixed lead-time analysis.

## Usage

``` r
align_forecast_series(
  observed,
  simulated,
  observed_time_column = "date_time",
  observed_value_column = "value",
  simulated_time_column = "date_time",
  simulated_value_column = "value",
  join = c("inner", "full"),
  duplicate_action = c("error", "mean", "first"),
  interval_minutes = NULL,
  timezone = "UTC",
  metadata = list()
)
```

## Arguments

- observed:

  Data frame or `data.table` containing observation timestamps and
  values.

- simulated:

  Data frame or `data.table` containing simulation timestamps and
  values.

- observed_time_column, simulated_time_column:

  Names of timestamp columns. Values must be convertible to `POSIXct`.

- observed_value_column, simulated_value_column:

  Names of numeric value columns. Both series must represent the same
  physical quantity and units.

- join:

  Join type. `"inner"` retains matched timestamps. `"full"` also retains
  unmatched values so missing data remain visible in diagnostics.

- duplicate_action:

  How duplicate timestamps are handled. `"error"` stops; `"mean"`
  averages duplicate values; `"first"` retains the first.

- interval_minutes:

  Optional expected interval. When supplied, the result reports whether
  the aligned sequence has a regular timestep.

- timezone:

  Timezone used when converting timestamps, normally `"UTC"`.

- metadata:

  Named list of identifiers such as site, event, measure, units, model
  version or rating version.

## Value

An aligned-series result. Use
[`aligned_series()`](https://jonpayneea.github.io/reach.postproc/reference/aligned_series.md)
for data and
[`alignment_diagnostics()`](https://jonpayneea.github.io/reach.postproc/reference/alignment_diagnostics.md)
for checks.

## Examples

``` r
time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:12 * 900

observed <- data.frame(date_time = time, value = 1 + sin(0:12 / 4))
simulated <- data.frame(date_time = time, value = 0.9 + sin(0:12 / 4))

aligned <- align_forecast_series(
  observed,
  simulated,
  interval_minutes = 15,
  metadata = list(site_id = "example", units = "m")
)

alignment_diagnostics(aligned)
#>    observed_rows simulated_rows aligned_rows missing_observed missing_simulated
#>            <int>          <int>        <int>            <int>             <int>
#> 1:            13             13           13                0                 0
#>    regular_time_step
#>               <lgcl>
#> 1:              TRUE
```
