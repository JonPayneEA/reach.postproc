# Calculate the Part 2 CWI rainfall-threshold factor

Calculate the Part 2 CWI rainfall-threshold factor

## Usage

``` r
cwi_rainfall_factor(cwi)
```

## Arguments

- cwi:

  Numeric Catchment Wetness Index values.

## Value

Numeric factors: one at or below 125, linearly declining to zero at 165,
and zero at or above 165.

## Examples

``` r
cwi_rainfall_factor(c(120, 125, 145, 165, 170))
#> [1] 1.0 1.0 0.5 0.0 0.0
```
