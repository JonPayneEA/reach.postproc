# Calculate effective decay time for an oscillating root

Find the first time at which exponential decay combined with oscillation
reaches `exp(-1)` of its starting value.

## Usage

``` r
effective_decay_time(decay_time, oscillation_period)
```

## Arguments

- decay_time:

  Positive exponential decay time in model steps.

- oscillation_period:

  Oscillation period in model steps. Use `Inf` for a non-oscillating
  root, in which case effective and exponential decay are the same.

## Value

One numeric effective decay time in model steps.

## Examples

``` r
effective_decay_time(8, Inf)
#> [1] 8
effective_decay_time(8, 12)
#> [1] 2.053511
```
