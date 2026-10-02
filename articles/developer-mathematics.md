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

## Modal roots versus reciprocal lag roots

The polynomial above is solved directly for $`z`$ in $`x_t=c\,z^t`$.
Call these the **modal roots**. Stable modal roots lie inside the unit
circle.
[`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md),
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
and
[`plot_ar()`](https://jonpayneea.github.io/reach.postproc/reference/plot_ar.md)’s
default view all use this convention.

A different, equally standard construction exists. Write the recurrence
with the backshift operator $`B`$ (where $`Bx_t=x_{t-1}`$) and solve
$`\phi(B)=0`$ directly for $`B`$:

``` math
1-a_1B-a_2B^2-\cdots-a_pB^p=0.
```

This is the Box-Jenkins/ARIMA textbook convention, and its stable region
is *outside* the unit circle. The two polynomials are reciprocals of one
another: substituting $`B=1/z`$ into the modal polynomial and clearing
denominators recovers the backshift polynomial, so each backshift root
is the reciprocal of the matching modal root.

``` r

parameters <- ar_parameters(c(2.1, -1.6, 0.4))

# Modal roots: direct solution of z^3 - 2.1z^2 + 1.6z - 0.4 = 0
modal <- polyroot(c(-0.4, 1.6, -2.1, 1))

# Reciprocal lag (backshift/Box-Jenkins) roots: 1 - 2.1z + 1.6z^2 - 0.4z^3 = 0
lag <- polyroot(c(1, -2.1, 1.6, -0.4))

modal
#> [1] 0.5+8.414707e-16i 0.8+4.000000e-01i 0.8-4.000000e-01i
lag
#> [1] 1+5.000000e-01i 1-5.000000e-01i 2-2.602085e-14i

all.equal(sort(Mod(1 / modal)), sort(Mod(lag)), tolerance = 1e-9)
#> [1] TRUE
```

[`root_table()`](https://jonpayneea.github.io/reach.postproc/reference/root_table.md)
reports both without requiring either polynomial to be built by hand:
`root_real`/`root_imaginary` for the modal form,
`lag_root_real`/`lag_root_imaginary` for the reciprocal.

``` r

root_table(roots(parameters))[
  ,
  .(root_real, root_imaginary, lag_root_real, lag_root_imaginary)
]
#>    root_real root_imaginary lag_root_real lag_root_imaginary
#>        <num>          <num>         <num>              <num>
#> 1:       0.8   4.000000e-01             1      -5.000000e-01
#> 2:       0.8  -4.000000e-01             1       5.000000e-01
#> 3:       0.5   8.414707e-16             2      -3.365883e-15
```

An external check of this package’s root calculations that assumes the
Box-Jenkins convention will report different root values, and a
different stability region (outside rather than inside the unit circle),
to those `reach.postproc` reports. That is not a disagreement about the
arithmetic. It is two valid conventions describing the same model.
Confirm which convention a comparison is using before treating a
mismatch as a defect.

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
