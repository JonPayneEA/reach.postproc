# Convert AR coefficient signs between supported conventions

Change the signs of a coefficient vector when moving between the
Deltares recurrence and the alternative signed equation convention.

## Usage

``` r
convert_sign_convention(
  coefficients,
  from = c("Deltares", "Standard"),
  to = c("Deltares", "Standard")
)
```

## Arguments

- coefficients:

  Numeric vector ordered from first to highest lag.

- from:

  Convention currently used by `coefficients`.

- to:

  Convention required in the returned vector.

## Value

A numeric vector in the requested convention. Coefficient order and
names are preserved.

## Examples

``` r
convert_sign_convention(
  coefficients = c(1.765, -0.72625, -0.040656),
  from = "Deltares",
  to = "Standard"
)
#> [1] -1.765000  0.726250  0.040656
```
