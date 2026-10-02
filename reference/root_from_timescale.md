# Construct one modal root from decay and oscillation timescales

Convert an interpretable decay time and oscillation period into a
complex modal root. Times are expressed in model timesteps, not hours.

## Usage

``` r
root_from_timescale(decay_time, oscillation_period = Inf)
```

## Arguments

- decay_time:

  Non-zero numeric decay time in model steps. Positive values create
  decaying roots. Negative values represent growth and should normally
  be used only for testing assessment behaviour.

- oscillation_period:

  Numeric period in model steps. Use `Inf` for a positive real,
  non-oscillating root. Use `2` for a negative real root that changes
  sign every timestep.

## Value

One complex modal root. For an `oscillation_period` other than `Inf` or
`2`, this is only one member of a genuine complex-conjugate pair: the
other member (its complex conjugate) is required for a real AR
polynomial, but this function has no way to return both. Pass the
request through
[`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md)
rather than building on this function directly; it adds the missing
conjugate automatically.

## Examples

``` r
root_from_timescale(decay_time = 96, oscillation_period = Inf)
#> [1] 0.9896374+0i
root_from_timescale(decay_time = 0.3333, oscillation_period = 2)
#> [1] -0.04977213+6.095328e-18i
root_from_timescale(decay_time = 20, oscillation_period = 8)
#> [1] 0.6726208+0.6726208i
```
