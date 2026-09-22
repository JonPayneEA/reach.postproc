# reach.postproc

`reach.postproc` implements the mathematics in *ARMA for flood forecasting, Part 1* as a compact R package. It uses S7 for domain objects and dispatch, `data.table` for every tabular result, and `ggplot2` for plots.

## Design

The package has five public object types:

- `ARParameterSet`: AR coefficients and their order.
- `CharacteristicRoots`: roots and interpretable decay and oscillation times.
- `ARForecast`: recurrence output from a supplied input-error sequence.
- `ARAssessment`: the EA quality tests and the roots on which they depend.
- `ARMAResponse`: a full ARMA unit response.

The main workflow is:

```r
parameters <- default_ar_parameters()
root_information <- roots(parameters)
quality <- assess(parameters)
forecast <- forecast_ar(
  parameters,
  initial_errors = c(0.20, 0.15, 0.10),
  steps = 480L
)
```

All tables are `data.table` objects:

```r
root_information@table
quality@tests
forecast@series
```

## Install from the source directory

```r
install.packages(c("S7", "data.table", "ggplot2", "testthat"))
install.packages("path/to/reach.postproc", repos = NULL, type = "source")
```

For active development:

```r
install.packages("devtools")
devtools::load_all("path/to/reach.postproc")
```

## Complete walkthrough

Run:

```r
source(system.file("examples", "01_arma_walkthrough.R", package = "reach.postproc"))
```

The source version is also available at `inst/examples/01_arma_walkthrough.R`.

## Important conventions

- Initial errors are ordered newest first: `c(x[t-1], x[t-2], x[t-3])`.
- Decay times and oscillation periods are expressed in model steps unless a column states otherwise.
- The cut-off applied by `apply_ar_update()` does not feed back into the AR recurrence.
- Full ARMA residuals are supplied explicitly. Random simulation is deliberately separate from the deterministic model calculation.
- Coefficients are never rounded internally.
