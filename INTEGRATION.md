# Integration with flode

`reach.postproc` is deliberately isolated from forecast download and catalogue classes. It can be merged into `flode` without changing the public API.

## Recommended merge

1. Copy the files under `R/` into the existing `flode/R/` directory.
2. Add `S7`, `data.table` and `ggplot2` to `Imports` if they are not already present.
3. Merge the exports from this package's `NAMESPACE`, preferably by adding matching `@export` tags when the main package is next documented with roxygen2.
4. Copy `inst/examples/01_arma_walkthrough.R` into the main package.
5. Copy the tests into `tests/testthat/`.
6. Rename the package references in the walkthrough from `library(reach.postproc)` to `library(reach.postproc)`.

## Dispatch boundary

Keep these AR generics separate from forecast acquisition generics:

- `roots()`
- `assess()`
- `forecast_ar()`
- `decompose_ar()`
- `response()`
- `plot_ar()`

This avoids overloading `forecast()` or `plot()` with another unrelated domain while retaining S7 dispatch within the AR model.

## Future integration points

A later `ARUpdateRequest` class could accept a `ForecastProduct` or extracted point series, then create an `ARForecast`. That class should sit in `flode`, not in the mathematical core, because it depends on the wider forecast-data object model.
