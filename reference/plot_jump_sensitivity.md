# Compare TJ-AR sensitivity across jump sizes

Calculate and plot TJ-AR projections for several candidate jump sizes.
Numerically invalid jumps are omitted from the plot and recorded in the
returned plot object's `failed_jumps` attribute.

## Usage

``` r
plot_jump_sensitivity(
  parameters,
  error_history,
  jumps = c(1L, 3L, 5L),
  steps = 96L,
  time_step_minutes = 15
)
```

## Arguments

- parameters:

  An AR parameter set.

- error_history:

  Complete error history supplied newest first.

- jumps:

  Positive whole-number jump sizes to compare.

- steps:

  Positive whole number of forecast steps.

- time_step_minutes:

  Minutes represented by one model timestep.

## Value

A `ggplot` showing each numerically valid projection. The plot has a
`failed_jumps` attribute containing any omitted jump sizes and their
corresponding error messages.

## Examples

``` r
history <- seq(
  0.2,
  0.05,
  length.out = 30
) +
  rep(
    c(
      -0.01,
      0.01
    ),
    15
  )

plot_jump_sensitivity(
  default_ar_parameters(),
  history,
  jumps = c(
    1L,
    3L,
    5L
  )
)

```
