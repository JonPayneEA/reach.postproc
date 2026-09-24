# Add projected AR error to a simulated forecast

Combine a simulation and projected error series, retaining both the
unconstrained update and any lower-limited displayed value.

## Usage

``` r
apply_ar_update(
  simulated,
  ar_error,
  lower_limit = NULL,
  time = seq_along(simulated)
)
```

## Arguments

- simulated:

  Numeric simulated level or flow values.

- ar_error:

  Numeric projected errors with the same length and units as
  `simulated`.

- lower_limit:

  Optional scalar lower bound, commonly zero. Use `NULL` to return the
  unconstrained update unchanged.

- time:

  Optional vector identifying each row. It may contain numeric lead
  times or date-times and must match the series length.

## Value

A `data.table` containing simulation, projected error, unconstrained
update, displayed update and a flag showing where the lower limit was
applied.

## Examples

``` r
apply_ar_update(
  simulated = c(0.10, 0.08, 0.05),
  ar_error = c(-0.05, -0.10, -0.04),
  lower_limit = 0,
  time = c(15, 30, 45)
)
#>     time simulated ar_error updated_unconstrained updated was_limited
#>    <num>     <num>    <num>                 <num>   <num>      <lgcl>
#> 1:    15      0.10    -0.05                  0.05    0.05       FALSE
#> 2:    30      0.08    -0.10                 -0.02    0.00        TRUE
#> 3:    45      0.05    -0.04                  0.01    0.01       FALSE
```
