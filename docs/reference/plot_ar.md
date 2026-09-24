# Plot AR and ARMA diagnostic objects

S7 generic for plotting roots, error forecasts, assessments and response
objects with `ggplot2`.

## Usage

``` r
plot_ar(x, ...)
```

## Arguments

- x:

  A supported `reach.postproc` result.

- ...:

  Method options. Root plots accept `root_definition` (`"modal"` or
  `"lag"`), `show_labels` and `maximum_plot_limit`. Other methods use
  options documented with their result type.

## Value

A `ggplot` object.

## Examples

``` r
parameters <- default_ar_parameters()
plot_ar(roots(parameters), root_definition = "modal")


forecast <- forecast_ar(
  parameters,
  initial_errors = c(0.15, 0.12, 0.10),
  steps = 24L
)
plot_ar(forecast)
```
