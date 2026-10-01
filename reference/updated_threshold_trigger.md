# Construct an updated-level or updated-flow ET-AR trigger

Define a threshold that is evaluated within
[`forecast_et_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_et_ar.md).
The forecast switches when the previous updated value crosses the
threshold. At the first forecast step, `initial_value` is used when
supplied.

## Usage

``` r
updated_threshold_trigger(
  threshold,
  direction = c("above", "below"),
  initial_value = NULL,
  quantity = "value"
)
```

## Arguments

- threshold:

  Scalar level or flow threshold in forecast units.

- direction:

  `"above"` or `"below"`.

- initial_value:

  Optional observed value at the forecast origin.

- quantity:

  Label such as `"level"` or `"flow"`.

## Value

An `et_ar_trigger` object.

## Examples

``` r
trigger <- updated_threshold_trigger(1.2, initial_value = 0.9, quantity = "level")
```
