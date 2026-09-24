# Score fixed lead-time AR forecasts

Compare simulated and updated values against observations separately for
each forecast lead.

## Usage

``` r
score_lead_times(x, metrics = c("mae", "rmse", "bias"))
```

## Arguments

- x:

  A fixed lead-time result from
  [`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
  or a compatible long table containing `lead_time_minutes`, `observed`,
  `simulated` and `updated`.

- metrics:

  Character vector of requested metrics where supported. Common choices
  include `"mae"`, `"rmse"`, `"bias"`, `"maximum_absolute_error"` and
  `"outperformance_rate"`.

## Value

One-row-per-lead `data.table` of performance metrics. Positive MAE or
RMSE improvement means the update outperformed the simulation.

## Examples

``` r
# See fixed_lead_ar() for construction of a full result.
example_scores <- data.table::data.table(
  lead_time_minutes = c(30, 30, 60, 60),
  observed = c(1.0, 1.2, 1.0, 1.2),
  simulated = c(0.8, 1.0, 0.8, 1.0),
  updated = c(0.95, 1.15, 0.9, 1.1)
)

score_lead_times(example_scores)
#>    lead_time_minutes     n mae_simulated mae_updated rmse_simulated
#>                <num> <int>         <num>       <num>          <num>
#> 1:                30     2           0.2        0.05            0.2
#> 2:                60     2           0.2        0.10            0.2
#>    rmse_updated bias_simulated bias_updated improvement_mae improvement_rmse
#>           <num>          <num>        <num>           <num>            <num>
#> 1:         0.05           -0.2        -0.05            0.15             0.15
#> 2:         0.10           -0.2        -0.10            0.10             0.10
```
