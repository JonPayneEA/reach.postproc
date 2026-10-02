# List the published standard default-family AR parameter sets

Calculate a reference table of the standard parameter sets. The table is
a catalogue for recognition, assurance and verification. The
coefficients are calculated directly rather than interpolated between
rows.

## Usage

``` r
standard_family_ar_table(time_step_minutes = 15)
```

## Arguments

- time_step_minutes:

  Duration of one model timestep in minutes, passed through to
  [`standard_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_parameters.md)
  for every row.

## Value

A `data.table` with the standard label, principal decay, three AR
coefficients and the three root timescales.

## Examples

``` r
standard_family_ar_table()
#>     parameter_set principal_decay_steps principal_decay_hours   a_1        a_2
#>            <char>                 <num>                 <num> <num>      <num>
#>  1:       3 hours                    12                     3 1.765 -0.7328501
#>  2:       6 hours                    24                     6 1.765 -0.7303273
#>  3:      12 hours                    48                    12 1.765 -0.7278277
#>  4:         1 day                    96                    24 1.765 -0.7262460
#>  5:        2 days                   192                    48 1.765 -0.7253693
#>  6:        4 days                   384                    96 1.765 -0.7249091
#>  7:        8 days                   768                   192 1.765 -0.7246735
#>  8:       16 days                  1536                   384 1.765 -0.7245543
#>  9:       32 days                  3072                   768 1.765 -0.7244943
#> 10:       64 days                  6144                  1536 1.765 -0.7244643
#> 11:      Infinite                   Inf                   Inf 1.765 -0.7244341
#>             a_3 fast_decay_steps fast_period_steps middle_decay_steps
#>           <num>            <num>             <num>              <num>
#>  1: -0.04098486        0.3333333                 2           8.991258
#>  2: -0.04085926        0.3333333                 2           6.412102
#>  3: -0.04073482        0.3333333                 2           5.560536
#>  4: -0.04065607        0.3333333                 2           5.203171
#>  5: -0.04061242        0.3333333                 2           5.038467
#>  6: -0.04058951        0.3333333                 2           4.959295
#>  7: -0.04057777        0.3333333                 2           4.920468
#>  8: -0.04057184        0.3333333                 2           4.901240
#>  9: -0.04056886        0.3333333                 2           4.891672
#> 10: -0.04056736        0.3333333                 2           4.886899
#> 11: -0.04056586        0.3333333                 2           4.882134
```
