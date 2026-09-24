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

One complex modal root.

## Examples

``` r
root_from_timescale(decay_time = 96, oscillation_period = Inf)
#> [1] 0.9896374+0i
root_from_timescale(decay_time = 0.3333, oscillation_period = 2)
#> [1] -0.04977213+6.095127e-18i
```
