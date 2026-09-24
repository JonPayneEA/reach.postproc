# Construct an autoregressive parameter set

Create and validate the coefficients used by the AR recurrence. The
function accepts either the Deltares convention used by IMFS or the
alternative signed equation convention. It converts the supplied values
to Deltares convention once and stores that form internally.

## Usage

``` r
ar_parameters(
  coefficients = NULL,
  label = "AR parameter set",
  sign_convention = c("Deltares", "Standard"),
  order_tolerance = 1e-08,
  ...
)
```

## Arguments

- coefficients:

  Numeric vector of AR coefficients ordered from the first lag to the
  highest lag. For AR(3), use `c(a_1, a_2, a_3)`. Names are optional.
  Supply either `coefficients` or values through `...`, not both.

- label:

  Single character value describing the parameter set, site, calibration
  or source. The label is retained for printing and reporting.

- sign_convention:

  Convention used by `coefficients`. Use `"Deltares"` for
  `x_t = a_1 x_{t-1} + ... + a_p x_{t-p}`. Use `"Standard"` where the
  lag terms are written on the left-hand side and therefore have
  opposite signs.

- order_tolerance:

  Non-negative numerical tolerance used to identify inactive trailing
  coefficients. A trailing coefficient whose absolute value is no
  greater than this tolerance is omitted when determining AR order.

- ...:

  Alternative coefficient input. This supports calls such as
  `ar_parameters(a_1 = 0.8)`. Do not combine this form with
  `coefficients`.

## Value

An internal AR parameter object accepted by
[`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md),
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md),
[`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md)
and the fixed lead-time functions.

## Examples

``` r
deltares <- ar_parameters(
  coefficients = c(1.765, -0.72625, -0.040656),
  sign_convention = "Deltares",
  label = "2024 defaults"
)

standard <- ar_parameters(
  coefficients = c(-1.765, 0.72625, 0.040656),
  sign_convention = "Standard"
)

all.equal(deltares@coefficients, standard@coefficients)
#> [1] TRUE
```
