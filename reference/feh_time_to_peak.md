# Estimate FEH time-to-peak from catchment descriptors

Calculate the FEH (Flood Estimation Handbook) rainfall-runoff model's
time-to-peak from standard catchment descriptors. This is a plain
implementation of the published FEH regression equation; it does not fit
or recalibrate anything, and it does not know which descriptor source
(FEH webservice, CD-ROM, or a bespoke catchment analysis) the values
came from – that provenance is the caller's responsibility to record.

## Usage

``` r
feh_time_to_peak(propwet, dplbar, dpsbar, urbext = 0)
```

## Arguments

- propwet:

  Catchment PROPWET descriptor (proportion of time soil is wet), a
  positive proportion.

- dplbar:

  Catchment DPLBAR descriptor (mean drainage path length, km), positive.

- dpsbar:

  Catchment DPSBAR descriptor (mean drainage path slope, m/km),
  positive.

- urbext:

  Catchment URBEXT descriptor (urban extent fraction). Default `0` (no
  urbanisation adjustment).

## Value

One positive numeric time-to-peak, in hours.

## Relationship to this package's AR functions

`reach.postproc` has no time-to-peak calculation of its own;
[`response_time_steps_from_tp()`](https://jonpayneea.github.io/reach.postproc/reference/response_time_steps_from_tp.md)
takes a time-to-peak as given and converts it to model timesteps,
deliberately leaving the question of *where that number comes from* to
the caller. This function is one defensible answer to that question, for
a catchment with FEH descriptors available. It does not make
[`response_time_steps_from_tp()`](https://jonpayneea.github.io/reach.postproc/reference/response_time_steps_from_tp.md)'s
own time-to-peak/AR-decay-time approximation any less of an
approximation – see that function's documentation – it only replaces a
guessed input with a traceable, standard one.

## See also

[`feh_lag()`](https://jonpayneea.github.io/reach.postproc/reference/feh_lag.md),
[`response_time_steps_from_tp()`](https://jonpayneea.github.io/reach.postproc/reference/response_time_steps_from_tp.md)

## Examples

``` r
feh_time_to_peak(propwet = 0.54, dplbar = 6.46, dpsbar = 213.5, urbext = 0.0003)
#> [1] 2.08508
```
