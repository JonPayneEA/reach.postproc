# Return the Environment Agency 2024 default AR parameters

Create the approved third-order default parameter set used throughout
the package examples. The coefficients are retained at their stated
precision.

## Usage

``` r
default_ar_parameters()
```

## Value

An AR(3) parameter object with Deltares coefficients `1.765`, `-0.72625`
and `-0.040656`.

## Examples

``` r
parameters <- default_ar_parameters()
parameters@coefficients
#>       a_1       a_2       a_3 
#>  1.765000 -0.726250 -0.040656 
assessment_table(assess(parameters))
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
