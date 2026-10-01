# Forecast an Event Triggered AR update

Begin with steady-condition parameters and switch once to
event-condition parameters when the configured trigger is met. The
recurrence state is retained across the switch, so the error series
remains continuous.

## Usage

``` r
forecast_et_ar(
  configuration,
  initial_errors,
  simulated,
  time = seq_along(simulated),
  lower_limit = NULL,
  time_step_minutes = 15
)
```

## Arguments

- configuration:

  An object from
  [`et_ar_configuration()`](https://jonpayneea.github.io/reach.postproc/reference/et_ar_configuration.md).

- initial_errors:

  Recent observed-minus-simulated errors, newest first. Length must
  equal the shared AR order.

- simulated:

  Numeric simulated values for the full projection horizon.

- time:

  Optional timestamps or lead values matching `simulated`.

- lower_limit:

  Optional lower bound applied to displayed updates.

- time_step_minutes:

  Minutes represented by one step.

## Value

An object of class `et_ar_forecast`. Use
[`et_ar_series()`](https://jonpayneea.github.io/reach.postproc/reference/et_ar_series.md)
to extract its auditable row-level table.

## Examples

``` r
config <- et_ar_configuration(
  default_et_ar_steady_parameters(), event_ar_parameters(48),
  logical_et_trigger(c(FALSE, FALSE, TRUE, rep(TRUE, 9)))
)
result <- forecast_et_ar(
  config, initial_errors = c(0.2, 0.18, 0.16), simulated = rep(1, 12)
)
et_ar_series(result)
#>      step  time lead_time_minutes simulated  ar_error updated_unconstrained
#>     <int> <int>             <num>     <num>     <num>                 <num>
#>  1:     1     1                15         1 0.2161113              1.216111
#>  2:     2     2                30         1 0.2292478              1.229248
#>  3:     3     3                45         1 0.2389928              1.238993
#>  4:     4     4                60         1 0.2460087              1.246009
#>  5:     5     5                75         1 0.2507916              1.250792
#>  6:     6     6                90         1 0.2537527              1.253753
#>  7:     7     7               105         1 0.2552309              1.255231
#>  8:     8     8               120         1 0.2555054              1.255505
#>  9:     9     9               135         1 0.2548061              1.254806
#> 10:    10    10               150         1 0.2533224              1.253322
#> 11:    11    11               165         1 0.2512101              1.251210
#> 12:    12    12               180         1 0.2485975              1.248597
#>      updated parameter_state trigger_type trigger_evidence triggered_this_step
#>        <num>          <char>       <char>           <AsIs>              <lgcl>
#>  1: 1.216111          steady      logical               NA               FALSE
#>  2: 1.229248          steady      logical               NA               FALSE
#>  3: 1.238993           event      logical               NA                TRUE
#>  4: 1.246009           event      logical               NA               FALSE
#>  5: 1.250792           event      logical               NA               FALSE
#>  6: 1.253753           event      logical               NA               FALSE
#>  7: 1.255231           event      logical               NA               FALSE
#>  8: 1.255505           event      logical               NA               FALSE
#>  9: 1.254806           event      logical               NA               FALSE
#> 10: 1.253322           event      logical               NA               FALSE
#> 11: 1.251210           event      logical               NA               FALSE
#> 12: 1.248597           event      logical               NA               FALSE
#>     switch_step
#>           <int>
#>  1:          NA
#>  2:          NA
#>  3:           3
#>  4:           3
#>  5:           3
#>  6:           3
#>  7:           3
#>  8:           3
#>  9:           3
#> 10:           3
#> 11:           3
#> 12:           3
```
