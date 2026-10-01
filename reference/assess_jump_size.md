# Assess a proposed TJ-AR jump size

Compare a jump with characteristic-root timescales. This is a
diagnostic, not a universal pass/fail rule.

## Usage

``` r
assess_jump_size(parameters, jump, noise_decorrelation_steps = NULL)
```

## Arguments

- parameters:

  An AR parameter set.

- jump:

  Positive whole timestep jump.

- noise_decorrelation_steps:

  Optional estimate of noise decorrelation time.

## Value

One-row `data.table` with jump-to-root ratios and warnings.

## Examples

``` r
assess_jump_size(default_ar_parameters(), jump = 5L, noise_decorrelation_steps = 3)
#>     jump principal_decay_steps middle_decay_steps fast_decay_steps
#>    <int>                 <num>              <num>            <num>
#> 1:     5              95.79098             5.2039        0.3333327
#>    jump_to_middle_ratio jump_to_fast_ratio smaller_than_noise_decorrelation
#>                   <num>              <num>                           <lgcl>
#> 1:            0.9608179           15.00003                            FALSE
#>                                                    effective_order_warning
#>                                                                     <char>
#> 1: Fast-root contribution may be negligible; behaviour may approach AR(2).
```
