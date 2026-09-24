# Assess AR parameters against operational root criteria

Test model order, growth, excessive persistence, universally rapid decay
and unacceptable oscillation.

## Usage

``` r
assess(x, ...)
```

## Arguments

- x:

  An AR parameter object.

- ...:

  Assessment controls passed to the AR-parameter method. These include
  `maximum_decay_time`, `minimum_useful_decay_time`,
  `rapid_decay_exception`, `oscillation_ratio`, `decay_measure`,
  `permitted_orders` and `time_step_minutes`.

## Value

An assessment result containing an overall pass flag, plain-English
summary, individual test outcomes and root diagnostics.

## Examples

``` r
assessment <- assess(
  default_ar_parameters(),
  maximum_decay_time = 240,
  minimum_useful_decay_time = 8,
  permitted_orders = c(2L, 3L)
)

assessment@summary
#> [1] "Pass. All roots meet the accepted criteria."
assessment_table(assessment)
#>    test_id                        test failed affected_roots
#>     <char>                      <char> <lgcl>         <list>
#> 1:   order          Permitted AR order  FALSE               
#> 2:       a          Exponential growth  FALSE               
#> 3:       b        Excessive decay time  FALSE               
#> 4:       c All roots decay too quickly  FALSE               
#> 5:       d    Unacceptable oscillation  FALSE               
#>               criterion
#>                  <char>
#> 1:      permitted order
#> 2:      no growing root
#> 3:        maximum decay
#> 4: minimum useful decay
#> 5:    oscillation ratio
```
