# Detect effective moving-average order

Identify the highest active MA lag after allowing for small trailing
values.

## Usage

``` r
detect_ma_order(coefficients, tolerance = 1e-08)
```

## Arguments

- coefficients:

  Numeric MA coefficients ordered from the most recent innovation to the
  oldest.

- tolerance:

  Non-negative activity threshold.

## Value

A single integer. An empty coefficient vector has order zero.

## Examples

``` r
detect_ma_order(c(-0.5, -0.25, 0))
#> [1] 2
detect_ma_order(numeric())
#> [1] 0
```
