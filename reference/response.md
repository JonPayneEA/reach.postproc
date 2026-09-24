# Calculate an ARMA unit-innovation response

Evaluate how a unit residual innovation is propagated by the supplied AR
and optional MA coefficients.

## Usage

``` r
response(x, ..., ma_parameters = numeric(), steps = 480L)
```

## Arguments

- x:

  An AR parameter object.

- ...:

  Additional method arguments; currently unused.

- ma_parameters:

  Numeric MA coefficients ordered from most recent to oldest residual.
  Use [`numeric()`](https://rdrr.io/r/base/numeric.html) for an AR-only
  response.

- steps:

  Positive whole number of response timesteps.

## Value

An ARMA response result containing component contributions and total
error through time.

## Examples

``` r
parameters <- default_ar_parameters()

unit_response <- response(
  parameters,
  ma_parameters = c(-0.5, -0.25),
  steps = 48L
)

head(unit_response@series)
#>     step ar_contribution residual_contribution ma_contribution arma_error
#>    <int>           <num>                 <num>           <num>      <num>
#> 1:     0        0.000000                     1            0.00   1.000000
#> 2:     1        1.765000                     0           -0.50   1.265000
#> 3:     2        1.506475                     0           -0.25   1.256475
#> 4:     3        1.258316                     0            0.00   1.258316
#> 5:     4        1.256983                     0            0.00   1.256983
#> 6:     5        1.253640                     0            0.00   1.253640
```
