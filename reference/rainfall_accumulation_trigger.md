# Construct a rainfall-accumulation ET-AR trigger

Switch when accumulated catchment rainfall over a moving window reaches
or exceeds a threshold. The window should be related to catchment
response time.

## Usage

``` r
rainfall_accumulation_trigger(
  rainfall,
  window_steps,
  threshold,
  prior_rainfall = numeric(),
  inclusive = TRUE,
  time_step_minutes = 15
)
```

## Arguments

- rainfall:

  Numeric forecast rainfall depth per model timestep.

- window_steps:

  Positive whole number of timesteps in the accumulation.

- threshold:

  Non-negative accumulated rainfall threshold in the same depth units as
  `rainfall`.

- prior_rainfall:

  Optional rainfall immediately before the forecast, supplied oldest to
  newest. Up to `window_steps - 1` values are relevant.

- inclusive:

  If `TRUE`, equality triggers the switch; otherwise the accumulated
  rainfall must exceed the threshold.

- time_step_minutes:

  Minutes per rainfall timestep, retained as metadata.

## Value

An `et_ar_trigger` containing rainfall, accumulation and trigger state.

## Examples

``` r
trigger <- rainfall_accumulation_trigger(
  rainfall = c(0, 1, 2, 3, 0), window_steps = 3L, threshold = 5
)
trigger$data
#>   step rainfall accumulated_rainfall threshold triggered
#> 1    1        0                    0         5     FALSE
#> 2    2        1                    1         5     FALSE
#> 3    3        2                    3         5     FALSE
#> 4    4        3                    6         5      TRUE
#> 5    5        0                    5         5      TRUE
```
