# Compare AR and ARMA response components

Return long-format responses suitable for plotting the effect of adding
MA terms to a supplied AR parameter set.

## Usage

``` r
response_components(parameters, ma_parameters = numeric(), steps = 480L)
```

## Arguments

- parameters:

  An AR parameter object.

- ma_parameters:

  Numeric MA coefficients ordered from most recent to oldest residual.
  Use [`numeric()`](https://rdrr.io/r/base/numeric.html) for an AR-only
  comparison.

- steps:

  Positive whole number of response timesteps.

## Value

A long `data.table` containing response step, value and component label.

## Examples

``` r
components <- response_components(
  default_ar_parameters(),
  ma_parameters = c(-0.5, -0.25),
  steps = 48L
)

head(components)
#>     step response component
#>    <int>    <num>    <char>
#> 1:     0 1.000000        AR
#> 2:     1 1.765000        AR
#> 3:     2 2.388975        AR
#> 4:     3 2.894054        AR
#> 5:     4 3.301254        AR
#> 6:     5 3.627780        AR
```
