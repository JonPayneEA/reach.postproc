# Assessment table

Extract the tabular data from a structured package result without
exposing callers to its internal S7 property layout.

## Usage

``` r
assessment_table(x)
```

## Arguments

- x:

  an assessment result returned by
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md).

## Value

a copied `data.table` containing each criterion, pass or fail status and
affected roots. The returned table is a copy and may be modified safely.

## Examples

``` r
assessment_table(assess(default_ar_parameters()))
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
