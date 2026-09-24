# Calculate observed-minus-simulated model error

Apply the package-wide error convention used to initialise and evaluate
AR forecasts.

## Usage

``` r
calculate_model_error(observed, simulated)
```

## Arguments

- observed:

  Numeric vector of observed level or flow values.

- simulated:

  Numeric vector of model values in the same domain, units, timestamps
  and order as `observed`.

## Value

Numeric vector calculated as `observed - simulated`. Positive values
mean the simulation is too low.

## Examples

``` r
calculate_model_error(
  observed = c(1.20, 1.30),
  simulated = c(1.00, 1.35)
)
#> [1]  0.20 -0.05
```
