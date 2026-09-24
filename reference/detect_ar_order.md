# Detect effective autoregressive order

Identify the highest active AR lag after allowing for small numerical
values in trailing coefficients.

## Usage

``` r
detect_ar_order(coefficients, tolerance = 1e-08)
```

## Arguments

- coefficients:

  Numeric coefficients ordered from first to highest lag.

- tolerance:

  Non-negative activity threshold. A coefficient is active when its
  absolute value exceeds this value.

## Value

A single integer. Zero means no coefficient exceeds `tolerance`.

## Examples

``` r
detect_ar_order(c(0.8, -0.2, 0))
#> [1] 2
detect_ar_order(c(0.8, -0.2, 1e-12), tolerance = 1e-8)
#> [1] 2
```
