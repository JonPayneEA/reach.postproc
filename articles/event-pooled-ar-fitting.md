# Event-Pooled AR Fitting: Mathematics and Validation

## Purpose

[`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
estimates AR coefficients directly from a set of event windows, by
weighted least squares across all of them at once. This article records
why it exists, the mathematics behind it, and the numerical evidence
that led to its default weighting scheme. It assumes familiarity with
[“Mathematical and Developer
Validation”](https://jonpayneea.github.io/reach.postproc/articles/developer-mathematics.md)
and the decision guide in [“Setting AR Parameters for a New
Model”](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md).

## Why this exists

`reach.postproc` otherwise has no AR estimator of its own: everywhere
else, coefficients are either published defaults, a default-family
construction from a timescale, or fitted externally by Performance
Testing (PT) and brought in with
[`ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters.md).
PT fits across a model’s entire residual record, with no way to restrict
the fit to events. For a package whose correction is meant to matter
during floods, that means ordinary and low-flow behaviour — including
anything a hydraulic model’s own minimum-flow floor has corrupted, see
[“Setting AR Parameters for a New
Model”](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md)
— shapes the calibration of a model meant to correct flood events
specifically.

[`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
is a narrow, deliberate exception to the no-estimator design, built to
close exactly that gap, transparently, inside a package whose
mathematics is meant to be reviewed rather than worked around from the
outside. It is not a general replacement for PT: it has no access to a
model’s full operational history, only the event windows supplied to it,
and it makes no claim to outperform PT once a genuine residual series
exists to fit PT against.

## The problem with naive concatenation

The direct-looking approach — paste all the event series end to end into
one long vector and fit an ordinary AR model to it — is wrong, and worth
seeing why rather than taking on trust. Concatenation invents a lag-1
relationship between the last point of one event and the first point of
the next, even though nothing connects them: they may be years apart,
under completely different conditions. Any lagged-regression estimator
reads that invented adjacency as real autocorrelation.

``` r

set.seed(1)
# Two short, unrelated events. Nothing connects event_b's start to
# event_a's end -- they could be entirely different years.
event_a <- cumsum(rnorm(15, sd = 0.3))
event_b <- cumsum(rnorm(15, sd = 0.3)) - 4

concatenated <- c(event_a, event_b)

# The lag-1 pair straddling the join:
boundary_index <- length(event_a)
data.table(
  position = c("last point of event_a", "first point of event_b"),
  value = c(event_a[length(event_a)], event_b[1])
)
#>                  position      value
#>                    <char>      <num>
#> 1:  last point of event_a  0.4537928
#> 2: first point of event_b -4.0134801
```

That single invented pair is one row out of many, but every additional
event boundary adds another one, and each is a *false* observation of
how the process evolves from one timestep to the next.
[`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
avoids this by never forming a regression row that spans two events:
every event builds its own lagged design matrix in isolation before the
rows are pooled.

``` mermaid

flowchart LR
    A[Event 1 residuals] --> D1[Event 1's own lagged rows]
    B[Event 2 residuals] --> D2[Event 2's own lagged rows]
    C[Event 3 residuals] --> D3[Event 3's own lagged rows]
    D1 --> E[Stack all rows]
    D2 --> E
    D3 --> E
    E --> F[One weighted regression]
```

## Per-event design matrix construction

For one event’s residual series $`e_1, e_2, \ldots, e_n`$
(chronological, oldest first) and AR order $`p`$, the usual
lagged-regression rows are formed entirely within that event:

``` math
e_t = a_1 e_{t-1} + a_2 e_{t-2} + \cdots + a_p e_{t-p}, \qquad t = p+1, \ldots, n.
```

This is already the Deltares recurrence’s own additive form, with no
intercept and no sign conversion needed: the regression coefficients
recovered below *are* the Deltares $`a_1, \ldots, a_p`$ coefficients
directly. An event of length $`n`$ contributes $`n-p`$ rows; events may
be any length, from any dates, with gaps of any size between them,
because no row is ever built across that gap.

## Weighted least squares across events

Stacking every event’s rows gives one design matrix $`X`$ and response
$`y`$, and
[`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
fits

``` math
\hat a = \arg\min_a \sum_i w_i \left(y_i - x_i^\top a\right)^2
```

by [`stats::lm.wfit()`](https://rdrr.io/r/stats/lmfit.html) — direct
matrix input, no intercept, no formula built programmatically for an
arbitrary order. The only design choice left is the per-row weight
$`w_i`$, and it is not a free one: it is the whole reason this function
needed numerical validation before shipping.

## Choosing a weighting scheme

Two tempting defaults both turn out to be wrong in the same way. Equal
weighting of *every row* makes long events dominate purely by producing
more rows. Equalising by *row count per event* (`"equal_event"`,
$`w = 1/n_{\text{rows}}`$) looks like it should fix that, since every
event then casts the same total vote regardless of length — but it does
not protect against a single event whose errors are simply much *larger*
in magnitude than the rest, because squared-residual loss amplifies a
scale difference faster than a row-count weight can cancel it out. Only
weighting each event by the inverse of its own variance (`"variance"`,
$`w = 1/(n_{\text{rows}} \cdot \mathrm{Var}(e))`$, the default) removes
magnitude as a channel of influence entirely: an event’s vote then
depends on neither its length nor its scale.

This is checked below, not asserted. Fifteen typical events share true
coefficients $`a_1=1.2, a_2=-0.45`$; one atypical event is both far
longer and an order of magnitude larger in scale, with different true
coefficients $`a_1=0.3, a_2=0.1`$ — the kind of thing a single unusually
severe or long event could plausibly produce in a real record.

``` r

simulate_ar_event <- function(n, a1, a2, sd = 1, burn_in = 50) {
  x <- numeric(n + burn_in)
  for (t in 3:length(x)) {
    x[t] <- a1 * x[t - 1] + a2 * x[t - 2] + rnorm(1, sd = sd)
  }
  x[-(1:burn_in)]
}

set.seed(7)
typical_events <- replicate(
  15,
  simulate_ar_event(n = 40, a1 = 1.2, a2 = -0.45, sd = 1),
  simplify = FALSE
)
atypical_event <- simulate_ar_event(n = 400, a1 = 0.3, a2 = 0.1, sd = 12)
events <- c(typical_events, list(atypical = atypical_event))

comparison <- rbindlist(lapply(
  c("none", "equal_event", "variance"),
  function(scheme) {
    fitted <- fit_ar_from_events(events, order = 2, weighting = scheme)
    data.table(
      weighting = scheme,
      a_1 = unname(fitted@coefficients[["a_1"]]),
      a_2 = unname(fitted@coefficients[["a_2"]]),
      distance_from_typical_a1 = abs(unname(fitted@coefficients[["a_1"]]) - 1.2)
    )
  }
))
comparison
#>      weighting       a_1         a_2 distance_from_typical_a1
#>         <char>     <num>       <num>                    <num>
#> 1:        none 0.3955897  0.02870729                0.8044103
#> 2: equal_event 0.4915222  0.02324690                0.7084778
#> 3:    variance 1.0800284 -0.33608159                0.1199716
```

The typical events’ true $`a_1`$ is $`1.2`$. `"none"` and
`"equal_event"` both land well short of it, pulled toward the atypical
event’s much larger-magnitude errors; `"variance"` lands closest. This
is the basis for making `"variance"` the default rather than the more
obvious-looking `"equal_event"`.

## Reading the per-event diagnostics

[`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
attaches `fit_per_event`, a table of each event’s row count, variance
and realised share of the total fitting weight, so a fit quietly
dominated by one event is visible rather than silently trusted:

``` r

fitted <- fit_ar_from_events(events, order = 2, weighting = "variance")
per_event <- attr(fitted, "fit_per_event")
per_event[order(-weight_share)]
#>        event n_timesteps n_rows   variance weight_share
#>       <char>       <int>  <int>      <num>        <num>
#>  1: event_11          40     38   1.926102  0.115390920
#>  2:  event_7          40     38   2.239127  0.099259522
#>  3: event_15          40     38   2.293193  0.096919321
#>  4:  event_2          40     38   2.306326  0.096367440
#>  5:  event_9          40     38   2.796843  0.079466287
#>  6:  event_8          40     38   3.287379  0.067608490
#>  7:  event_5          40     38   3.384626  0.065665959
#>  8: event_12          40     38   3.991127  0.055687201
#>  9: event_10          40     38   4.004734  0.055497994
#> 10:  event_6          40     38   4.198960  0.052930897
#> 11:  event_4          40     38   4.622502  0.048081043
#> 12:  event_3          40     38   4.643542  0.047863188
#> 13: event_14          40     38   4.963124  0.044781213
#> 14: event_13          40     38   5.638484  0.039417463
#> 15:  event_1          40     38   6.558788  0.033886555
#> 16: atypical         400    398 188.910635  0.001176507
```

A `weight_share` far above what an even split across events would give
(here, roughly $`1/16 \approx 6\%`$) is worth a second look: either that
event is genuinely representative and the others are thin, or something
about it (a data problem, a genuinely different regime) deserves
separate treatment rather than being pooled in. As with
[`default_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_family_ar_parameters.md)’s
attributes, these are provenance for this call’s own output, not part of
the `ARParameterSet` contract: they will not survive the object being
reconstructed elsewhere in the package.

## Composing with the rest of the package

The returned object is an ordinary AR parameter set in Deltares
convention and composes exactly like any other construction path:

``` r

root_information <- roots(fitted, time_step_minutes = 15)
root_table(root_information)
#>    root_id root_real root_imaginary root_modulus lag_root_real
#>      <int>     <num>          <num>        <num>         <num>
#> 1:       2 0.5400142     -0.2108702    0.5797254      1.606795
#> 2:       1 0.5400142      0.2108702    0.5797254      1.606795
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:          0.6274377         1.724954             1.834187         1.834187
#> 2:         -0.6274377         1.724954             1.834187         1.834187
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                   1.522352        0.4585468                  0.3805879
#> 2:                   1.522352        0.4585468                  0.3805879
#>    oscillation_period_steps oscillation_period_hours is_growing is_persistent
#>                       <num>                    <num>     <lgcl>        <lgcl>
#> 1:                 16.87751                 4.219378      FALSE         FALSE
#> 2:                 16.87751                 4.219378      FALSE         FALSE
#>    is_oscillating modal_stability lag_stability display_order
#>            <lgcl>          <fctr>        <fctr>         <int>
#> 1:           TRUE          Stable        Stable             1
#> 2:           TRUE          Stable        Stable             2

assessment <- assess(fitted, permitted_orders = c(2L, 3L))
assessment@summary
#> [1] "Fail: All roots decay too quickly"
```

A fit that produces sensible-looking coefficients can still fail
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
— pooling does not exempt the result from the same root-based acceptance
criteria as every other path. Treat a pass here the same way the
decision-guide vignette treats a PT fit: necessary, not sufficient, and
still worth scoring against held-out events with
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
and
[`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md)
before trusting it operationally.

## Constraining undesired behaviour

Weighted least squares has no concept of the Environment Agency’s
root-acceptance criteria; it only minimises squared error. Nothing stops
it handing back a fit with an excessively fast-decaying root, a
borderline-persistent one, or an order outside what governance permits,
if that is what best fits the pooled rows. Two guardrails are available,
and they are deliberately not the same kind of thing.

**`minimum_rows_per_parameter`** (default `10`, always enforced, not
gated by `strict`) is a data-sufficiency floor: the pooled fit is
rejected outright if the total number of regression rows across all
events is fewer than `order * minimum_rows_per_parameter`. This is the
same category of guard as the per-event length check already covered
above, just applied to the pooled total rather than to each event
individually — a near-singular
[`lm.wfit()`](https://rdrr.io/r/stats/lmfit.html) solve from too few
rows would look precise while meaning very little.

``` r

tryCatch(
  fit_ar_from_events(list(short_a = rnorm(8), short_b = rnorm(8)), order = 3),
  error = function(e) conditionMessage(e)
)
#> [1] "Only 10 regression rows are available across all events, against a minimum of order * minimum_rows_per_parameter = 30 for order = 3. Supply more or longer events, lower `order`, or lower `minimum_rows_per_parameter` deliberately if there is a specific reason to trust a thinner fit."
```

**`strict`** (default `FALSE`) is a governance gate, not a data check:
set it `TRUE` and the function runs
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
on the fitted parameters before returning, erroring rather than handing
back an unvalidated fit if it fails. It deliberately reuses
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
itself — the same single criteria every other construction path in this
package is already expected to pass — rather than re-implementing or
approximating those thresholds inside the estimator. That keeps
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
the single source of truth for what “acceptable” means, and keeps this
function’s contract the same as every other construction path’s, where
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
is always a separate, explicit step the caller chooses to run. This is
also why `strict` defaults to `FALSE` rather than `TRUE`: making it
implicit here and nowhere else would make this one construction path
behave differently from the rest for no reason tied to the estimator
itself.

``` r

tryCatch(
  fit_ar_from_events(events, order = 2, weighting = "variance", strict = TRUE),
  error = function(e) conditionMessage(e)
)
#> [1] "strict = TRUE and the pooled fit failed assess(): Fail: All roots decay too quickly Inspect with root_table(roots(parameters)) to see which root(s) are responsible, then adjust the events, the order, or the assess() thresholds passed via `...` -- or re-run with strict = FALSE to accept the fit for further investigation rather than erroring."
```

Arguments passed via `...` are forwarded to
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
only when `strict = TRUE` — for instance, to work with criteria other
than the defaults:

``` r

fit_ar_from_events(
  events, order = 2, weighting = "variance", strict = TRUE,
  minimum_useful_decay_time = 0, maximum_decay_time = Inf,
  oscillation_ratio = 0, permitted_orders = 2L
)
#> <reach.postproc::ARParameterSet>
#>  @ coefficients   : Named num [1:2] 1.08 -0.336
#>  .. - attr(*, "names")= chr [1:2] "a_1" "a_2"
#>  @ order          : int 2
#>  @ sign_convention: chr "Deltares"
#>  @ order_tolerance: num 1e-08
#>  @ label          : chr "Event-pooled AR fit"
```

Passed without `strict = TRUE`, the same arguments are silently
irrelevant to the fit, so they are instead flagged with a warning rather
than doing nothing unannounced.

Turn `strict` on by default in any workflow where the fit’s output will
not be inspected by hand before use — exactly the same judgement the
decision-guide vignette recommends applying to every other construction
path.

## Scope and limitations

- **Tier 1, experimental.** Not yet operationally reviewed; treat output
  as a candidate to validate, not a finished calibration.
- **Needs enough events.** A pooled fit from two or three short events
  carries little more information than a single one; the weighting
  scheme controls *influence*, not the total evidence available.
  `minimum_rows_per_parameter` catches the most extreme case of this,
  not the general one.
- **`"variance"` requires non-degenerate variance.** An event with a
  flat (zero-variance) residual series cannot be weighted this way; use
  `"equal_event"` or `"none"`, or exclude that event.
- **Not a PT replacement.** Once a model has run long enough to
  accumulate a genuine residual history, PT’s full-record fit remains
  the higher-confidence path for everything PT is meant to capture; this
  function’s purpose is specifically event-only calibration, which PT
  cannot do, not a general substitute for it.
- **`strict` does not make the fit good, only checked.** A pass means
  the roots meet the acceptance criteria in the abstract, exactly as for
  every other path — it says nothing about whether the update actually
  helps on real events. Score against held-out events regardless.

## Key messages

1.  Concatenating events before fitting invents a false lag-1
    relationship at every boundary;
    [`fit_ar_from_events()`](https://jonpayneea.github.io/reach.postproc/reference/fit_ar_from_events.md)
    avoids this by building each event’s design matrix in isolation.
2.  Row-count weighting (`"equal_event"`) looks like it should prevent
    one event from dominating a pooled fit, but does not: magnitude, not
    just row count, needs to be controlled for.
3.  Variance weighting (the default) was adopted because it was checked
    numerically, not assumed, and it is the only one of the three
    schemes that held up under a stress test with one atypical event.
4.  The output still has to pass
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    and still benefits from scoring against held-out events, exactly
    like every other construction path in this package.
5.  `minimum_rows_per_parameter` always guards against too little pooled
    data; `strict` optionally makes
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    a hard gate inside the function itself, rather than a step a caller
    could forget to run.
