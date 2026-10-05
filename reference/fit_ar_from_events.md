# Fit AR coefficients by pooling weighted least squares across events

Estimate AR coefficients directly from a set of event windows, rather
than from a model's full continuous residual record. Each event
contributes its own lagged regression rows; no row is ever built from
values spanning two different events, so events can be any length, from
any dates, with gaps of any size between them – unlike naively
concatenating events into one long series, which would invent a false
"this timestep immediately preceded that one" relationship at every
event boundary and corrupt exactly the autocorrelation structure being
estimated.

## Usage

``` r
fit_ar_from_events(
  events,
  ...,
  order = 3L,
  weighting = c("variance", "equal_event", "none"),
  label = "Event-pooled AR fit",
  strict = FALSE,
  minimum_rows_per_parameter = 10
)
```

## Arguments

- events:

  A named or unnamed list of numeric vectors, one per event. Each vector
  is that event's residual (observed-minus-simulated) series in
  chronological order, oldest first – the opposite of `initial_errors`
  elsewhere in this package, which is always supplied newest first for
  seeding a live recurrence. This function is fitting from history, not
  projecting from a forecast origin, so it reads history the way it
  naturally occurs. Each event must be complete (no `NA`) and longer
  than `order`.

- ...:

  Forwarded to
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  when `strict = TRUE` (for example `permitted_orders`,
  `minimum_useful_decay_time`). Ignored, with a warning, when
  `strict = FALSE`.

- order:

  Positive whole number AR order to fit. Default `3L`, matching this
  package's usual default order;
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)'s
  `permitted_orders` still governs what counts as acceptable once
  fitted, exactly as for every other construction path.

- weighting:

  One of `"variance"` (default), `"equal_event"` or `"none"`. See the
  Details above.

- label:

  Description attached to the returned parameter set.

- strict:

  If `TRUE`, run
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  on the fitted parameters before returning and error (rather than hand
  back an unchecked fit) if it fails. Default `FALSE`, matching every
  other construction path in this package, where
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  is always a separate, explicit step the caller chooses to run – see
  @section Constraining undesired behaviour.

- minimum_rows_per_parameter:

  Always enforced (not gated by `strict`). The pooled fit is rejected if
  the total number of regression rows across all events is fewer than
  `order * minimum_rows_per_parameter`. Default `10`, the common rule of
  thumb for a minimally trustworthy least-squares fit. Set lower only
  with a specific reason to trust a thinner fit.

## Value

An AR parameter object in Deltares convention, exactly like every other
construction path in this package, so it composes directly with
[`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md),
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md),
[`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md)
and the fixed lead-time functions. Carries fit diagnostics as
attributes: `fit_weighting`, `fit_total_rows`, `fit_n_events`,
`fit_residual_se` and `fit_per_event` (a `data.table` of each event's
row count, variance and realised weight share, so a fit dominated by one
event is visible rather than silently trusted). As with
[`default_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_family_ar_parameters.md)'s
attributes, these are provenance for this call's own output, not part of
the `ARParameterSet` contract – they will not survive the object being
reconstructed elsewhere in the package. Recompute from
`parameters@coefficients` after any such transformation.

## Why this exists

Performance Testing (PT) fits AR coefficients from a model's full
residual record, with no way to restrict that fit to events. For a
package whose correction is meant to matter during floods, letting
ordinary and low-flow behaviour shape the fit is a real cost, compounded
by anything a hydraulic model's own minimum-flow floor has corrupted in
that record (see
[`vignette("setting-parameters-for-a-new-model")`](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md)).
This function is a narrow, deliberate exception to reach.postproc
otherwise having no AR estimator of its own: it exists specifically to
let event-only calibration happen transparently, inside a package whose
mathematics is meant to be reviewed, rather than by working around PT's
limitation from the outside.

## Choosing a weighting scheme

`"variance"` (the default) weights each event's rows by
`1 / (n_rows * variance)`, so an event's influence on the fit depends on
neither how long it is nor how large its own errors happen to be – every
event ends up contributing equally. `"equal_event"` weights only by
`1 / n_rows`, equalising each event's vote by row count alone; this
sounds like it should prevent one event from dominating, but does not
protect against a single much-larger-magnitude event pulling the fit
toward itself, since squared residuals amplify a scale difference faster
than a row-count weight can cancel it out. `"none"` applies no weighting
at all: every row counts equally regardless of which event it came from,
so long or large events dominate by construction. Checked numerically
before this function was written: a single tenfold-larger, atypical
event among otherwise-similar events pulled an unweighted fit almost
entirely onto its own (wrong, for the other 19) coefficients, and
`"equal_event"` weighting barely helped; only `"variance"` kept the fit
close to the coefficients the typical events actually shared.

## Constraining undesired behaviour

This estimator can return a fit nothing else in the package would accept
– an excessively fast- decaying root, a borderline-persistent one, an
order outside what governance permits – because weighted least squares
has no concept of the Environment Agency's root-acceptance criteria; it
only minimises squared error. Two guardrails are available, and they are
deliberately not the same kind of thing. `minimum_rows_per_parameter` is
a data- sufficiency floor: a near-singular fit from too few rows
relative to `order` is rejected unconditionally, the same way too-short
individual events already are. `strict` is a governance gate: it reuses
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md),
the same single criteria this package applies to every other
construction path, rather than duplicating or approximating those
criteria inside the estimator itself. Keeping `strict` opt-in preserves
that single source of truth and this function's contract with the rest
of the package; turn it on whenever the fit is not going to be inspected
by hand before use.

## See also

[`ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters.md),
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md),
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md),
[`vignette("setting-parameters-for-a-new-model")`](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md),
[`vignette("event-pooled-ar-fitting")`](https://jonpayneea.github.io/reach.postproc/articles/event-pooled-ar-fitting.md)

## Examples

``` r
set.seed(1)
simulate_event <- function(n, a1 = 1.2, a2 = -0.45) {
  x <- numeric(n + 20)
  for (t in 3:(n + 20)) {
    x[t] <- a1 * x[t - 1] + a2 * x[t - 2] + rnorm(1)
  }
  x[-(1:20)]
}
events <- list(
  flood_2019 = simulate_event(40),
  flood_2020 = simulate_event(25),
  flood_2021 = simulate_event(60)
)
fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")
fitted@coefficients
#>        a_1        a_2 
#>  1.2462964 -0.5076118 
attr(fitted, "fit_per_event")
#>         event n_timesteps n_rows variance weight_share
#>        <char>       <int>  <int>    <num>        <num>
#> 1: flood_2019          40     38 2.487820    0.4345322
#> 2: flood_2020          25     23 4.093730    0.2640716
#> 3: flood_2021          60     58 3.586767    0.3013962

# strict = TRUE reuses assess() as a hard gate rather than letting an
# unvalidated fit leave the function silently -- wrapped in tryCatch()
# here so the example runs whichever way this particular random draw
# happens to assess:
tryCatch(
  fit_ar_from_events(events, order = 2, weighting = "variance", strict = TRUE),
  error = function(e) conditionMessage(e)
)
#> [1] "strict = TRUE and the pooled fit failed assess(): Fail: All roots decay too quickly; Unacceptable oscillation Inspect with root_table(roots(parameters)) to see which root(s) are responsible, then adjust the events, the order, or the assess() thresholds passed via `...` -- or re-run with strict = FALSE to accept the fit for further investigation rather than erroring."
```
