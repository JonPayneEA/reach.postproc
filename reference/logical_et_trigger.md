# Construct an ET-AR trigger from a logical series

Use a pre-calculated logical series when trigger evidence is prepared by
an external workflow. The first `TRUE` value causes the permanent
parameter switch.

## Usage

``` r
logical_et_trigger(triggered, evidence = NULL, label = "Supplied trigger")
```

## Arguments

- triggered:

  Logical vector with one value per projected timestep.

- evidence:

  Optional numeric or character vector retained for audit.

- label:

  Description of the external trigger calculation.

## Value

An `et_ar_trigger` object.

## Examples

``` r
trigger <- logical_et_trigger(c(FALSE, FALSE, TRUE, TRUE))
```
