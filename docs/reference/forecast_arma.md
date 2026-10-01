# Evaluate a deterministic ARMA error recurrence

Calculate an error series from autoregressive memory, current residual
innovations and moving-average memory. This function evaluates a
supplied ARMA model; it does not estimate AR or MA parameters from
observations.

## Usage

``` r
forecast_arma(
  parameters,
  initial_errors,
  residuals,
  ma_parameters = numeric(),
  previous_residuals = numeric()
)
```

## Arguments

- parameters:

  An AR parameter set created by
  [`ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters.md),
  [`default_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_ar_parameters.md)
  or
  [`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md).
  The coefficient order determines how many values `initial_errors` must
  contain. Coefficients are stored internally in the Deltares
  convention.

- initial_errors:

  Numeric vector containing the error values immediately before the
  first forecast step. Supply values **newest first**. For AR(3), use
  `c(error_t_minus_1, error_t_minus_2, error_t_minus_3)`. The vector
  must have the same length as the AR order and must not contain missing
  values.

- residuals:

  Numeric vector of innovations to apply during the forecast. One value
  is required for each output timestep. Use `0` where no new innovation
  is applied. A unit impulse response uses `c(1, 0, 0, ...)`.

- ma_parameters:

  Numeric vector of moving-average coefficients, ordered from the most
  recent residual to the oldest. An empty vector, the default, evaluates
  an AR-only model. These are MA coefficients, not rolling-average
  window weights.

- previous_residuals:

  Numeric vector containing residual innovations from before the first
  forecast step, supplied newest first. Its length must equal
  `length(ma_parameters)`. Use `numeric(length(ma_parameters))` when no
  earlier innovations should contribute.

## Value

A `data.table` with one row per forecast step and columns containing the
AR contribution, current residual contribution, MA contribution and
resulting ARMA error.

## Examples

``` r
parameters <- default_ar_parameters()

innovations <- c(1, rep(0, 23))

arma_forecast <- forecast_arma(
  parameters = parameters,
  initial_errors = c(0, 0, 0),
  residuals = innovations,
  ma_parameters = c(-0.5, -0.25),
  previous_residuals = c(0, 0)
)

head(arma_forecast)
#>     step ar_contribution residual_contribution ma_contribution arma_error
#>    <int>           <num>                 <num>           <num>      <num>
#> 1:     0        0.000000                     1            0.00   1.000000
#> 2:     1        1.765000                     0           -0.50   1.265000
#> 3:     2        1.506475                     0           -0.25   1.256475
#> 4:     3        1.258316                     0            0.00   1.258316
#> 5:     4        1.256983                     0            0.00   1.256983
#> 6:     5        1.253640                     0            0.00   1.253640
```
