# Construct a CWI-adjusted rainfall trigger

Apply the experimental Part 2 wetness scaling to a dry-condition
rainfall threshold before comparing it with rolling rainfall
accumulation.

## Usage

``` r
cwi_adjusted_rainfall_trigger(
  rainfall,
  cwi,
  dry_threshold,
  window_steps,
  prior_rainfall = numeric(),
  time_step_minutes = 15
)
```

## Arguments

- rainfall, window_steps, prior_rainfall, time_step_minutes:

  As documented by
  [`rainfall_accumulation_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/rainfall_accumulation_trigger.md).

- cwi:

  One CWI value or one value per forecast timestep.

- dry_threshold:

  Accumulated rainfall threshold at CWI 125 or below.

## Value

An experimental `et_ar_trigger` with time-varying thresholds.

## Examples

``` r
trigger <- cwi_adjusted_rainfall_trigger(
  rainfall = c(0, 1, 2, 3), cwi = 145,
  dry_threshold = 8, window_steps = 3L
)
trigger$data
#>   step rainfall accumulated_rainfall threshold triggered cwi
#> 1    1        0                    0         4     FALSE 145
#> 2    2        1                    1         4     FALSE 145
#> 3    3        2                    3         4     FALSE 145
#> 4    4        3                    6         4      TRUE 145
```
