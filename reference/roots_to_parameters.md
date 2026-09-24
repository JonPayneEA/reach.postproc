# Convert modal roots to AR coefficients

Construct the Deltares AR polynomial from supplied modal roots. Complex
roots must occur as conjugate pairs so the resulting coefficients are
real.

## Usage

``` r
roots_to_parameters(
  root_values,
  label = "Derived from roots",
  tolerance = 1e-10
)
```

## Arguments

- root_values:

  Numeric or complex vector of modal roots. These are the roots used by
  the Environment Agency guidance, for which stable roots lie inside the
  unit circle. Do not supply reciprocal lag-polynomial roots.

- label:

  Description attached to the returned parameter set.

- tolerance:

  Maximum permitted imaginary remainder in the calculated coefficients
  and the activity tolerance used to identify AR order.

## Value

An AR parameter object in Deltares convention.

## Examples

``` r
original <- default_ar_parameters()
modal_roots <- roots(original)@values
reconstructed <- roots_to_parameters(modal_roots)

all.equal(
  original@coefficients,
  reconstructed@coefficients,
  tolerance = 1e-9
)
#> [1] TRUE
```
