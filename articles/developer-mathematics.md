# Mathematical and Developer Validation

## Purpose

This article records the mathematical contracts and numerical
equivalences that protect the package from subtle sign, root and
indexing errors.

``` mermaid

flowchart LR
    A[Parameters] --> B[Modal roots] --> C[Reconstructed parameters]
    D[AR recurrence] --> E[Modal decomposition]
    F[Fixed-lead recurrence] --> G[Fixed-lead root projection]
    H[ARMA recurrence] --> I[Impulse response]
```

## Characteristic polynomial

For Deltares coefficients,

``` math
z^p-a_1z^{p-1}-a_2z^{p-2}-\cdots-a_p=0.
```

The modal solution is

``` math
x_t=\sum_{n=1}^{p}c_nz_n^t.
```

## Root-to-parameter conversion

For modal root $`r`$, the polynomial factor is

``` math
z-r.
```

When polynomial coefficients are stored in ascending order, the factor
is

``` r

c(-r, 1)
```

Using `c(1, -r)` would create $`1-rz`$ and therefore introduce
reciprocal roots.

``` r

p1 <- default_ar_parameters()
z1 <- roots(p1)@values
p2 <- roots_to_parameters(z1)
z2 <- roots(p2)@values

p1@coefficients
#>       a_1       a_2       a_3 
#>  1.765000 -0.726250 -0.040656
p2@coefficients
#>       a_1       a_2       a_3 
#>  1.765000 -0.726250 -0.040656
```

The test suite should order complex roots deterministically before
comparing them, because
[`polyroot()`](https://rdrr.io/r/base/polyroot.html) does not guarantee
a semantic root order.

## Raw and displayed decay time

The mathematical decay parameter is

``` math
\tau=-\frac{1}{\ln|z|}.
```

Growing roots have negative raw $`\tau`$. Operational diagnostic tables
may display infinite decay for growth, but should retain the raw value
separately.

## Modal decomposition

The root weights solve the recent errors at times

``` math
-1,-2,\ldots,-p.
```

Modal time zero is therefore the first forecast value. Package indexing
is:

``` text
modal time 0 = forecast step 1
modal time 1 = forecast step 2
modal time 2 = forecast step 3
```

``` r

parameters <- default_ar_parameters()
forecast <- forecast_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 100L
)

components <- decompose_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 100L
)

reconstructed <- components[
  ,
  .(value = sum(contribution_real)),
  by = step
]

all.equal(
  reconstructed$value,
  forecast_series(forecast)$ar_error,
  tolerance = 1e-9
)
#> [1] TRUE
```

## Fixed-lead equivalence

The recurrence implementation is the production path. Independent root
projection is a valuable cross-check.

For target index $`i`$ and lead $`L`$, initialise from errors available
at $`i-L`$, then project exactly $`L`$ steps.

The test suite should compare recurrence and root projection for
multiple leads, error histories, real roots and complex conjugate roots.

## ARMA response equivalence

For deterministic residual sequence $`\varepsilon_t`$, the recurrence is

``` math
x_t=\sum_{n=1}^{p}a_nx_{t-n}
+\varepsilon_t
+\sum_{m=1}^{q}b_m\varepsilon_{t-m}.
```

A unit impulse should produce the same series through direct recurrence
and the response interface.

## Numerical conditioning

Root decomposition solves a Vandermonde-like system. Closely spaced
roots can cause poor conditioning. Development checks should inspect the
condition number and warn where the decomposition may be numerically
fragile.

## Assessment boundaries

Tests should cover values immediately below, on and above each boundary:

- modulus one;
- decay time 240;
- decay time 8;
- rapid-decay exception at one;
- oscillation ratio 4.605;
- permitted and non-permitted model orders.

## Sign-convention invariance

Deltares and standard inputs that differ only by sign convention must
produce identical internal coefficients, roots and forecasts.

## Plot contracts

The unit-circle polygon should:

- close exactly;
- have modulus one at every coordinate;
- use fixed aspect ratio;
- display stable modal roots inside;
- display stable reciprocal roots outside;
- expand limits for unstable or large reciprocal roots.

## Reproducibility contract

Public calculation functions should:

- avoid hidden file output;
- avoid changing caller-owned tables by reference;
- return stable column names;
- retain units and identifiers as metadata;
- expose diagnostics rather than silently repair data;
- fail early for impossible inputs.

## Minimum developer checks

``` r

# Not run in the vignette build.
devtools::document()
devtools::load_all()
devtools::test()
devtools::build_vignettes()
devtools::check()
```

The package is ready for release only when the numerical tests and
package checks pass together.
