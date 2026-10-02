# Changelog

## reach.postproc 0.10.2

### Documentation

- New vignette, “Setting AR Parameters for a New Model”
  (`setting-parameters-for-a-new-model.Rmd`): a decision guide for a
  model with no existing calibration, covering PT-fitted coefficients,
  the standard and continuous default-family constructions, fully custom
  timescale construction, and ET-AR (flagged explicitly as untested and
  not yet deployable in IMFS). Frames the four deployable paths as a
  lifecycle rather than a flat menu: PT cannot run until a model has
  been live long enough to accumulate a residual series, so an a-priori
  default-family or custom-timescale choice is the deliberate,
  provisional bridge to go-live, intended to be superseded by a PT refit
  once that history exists. Includes a Mermaid decision tree and a
  validation checklist shared by every path.

## reach.postproc 0.10.1

### Documentation

- “Selecting a Default-Family Parameter Set” gains two plots:
  [`plot_ar()`](https://jonpayneea.github.io/reach.postproc/reference/plot_ar.md)
  on the worked nine-hour example’s roots, and a new “Visualising the
  family” section with a custom plot overlaying the principal, middle
  and fast roots of five standard members (3 hours to Infinite) on one
  unit circle. Makes the “why the coefficients change so little” claim
  visible rather than asserted: the principal root visibly compresses
  towards `1` as decay time lengthens, numerically confirmed (the
  3-hours-to-12-hours gap in the principal root is roughly 91x the
  16-days-to-Infinite gap, despite the second pair spanning far more
  decay time).

## reach.postproc 0.10.0

### New functions

- [`default_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_family_ar_parameters.md):
  constructs a continuous analytical family of default AR(3) parameter
  sets from a single principal decay timescale, holding the first
  coefficient and fast root fixed and solving the middle root so the
  three roots sum to the fixed `a_1`. Verified by hand and numerically
  against the test suite: the “1 day” and “Infinite” members reproduce
  [`default_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_ar_parameters.md)’s
  and
  [`default_et_ar_steady_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_et_ar_steady_parameters.md)’s
  published coefficients almost to the last digit, which is strong
  evidence the construction is correct and that those two
  previously-independent hard-coded defaults are in fact the same
  analytical family.
- [`standard_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_parameters.md)
  and
  [`standard_family_ar_table()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_table.md):
  the published standard catalogue (3 hours to 64 days, plus Infinite)
  as named lookups on the same construction, for governance recognition
  rather than bespoke calibration.
- New vignette, “Selecting a Default-Family Parameter Set”
  (`default-parameter-family-section.Rmd`), covering the practical
  workflow and the full mathematical derivation, including a worked
  nine-hour example.

### Bug fixes

- [`default_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_family_ar_parameters.md)’s
  fast root was taken via `Re(root_from_timescale(...))` with no check
  that the result was actually real. Any `fast_period_steps` other than
  `Inf` or `2` would have been genuinely complex, and
  [`Re()`](https://rdrr.io/r/base/complex.html) would have silently
  discarded the imaginary half rather than error, producing a subtly
  wrong, truncated root with no indication anything was lost. Now
  validated explicitly.
- [`standard_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_parameters.md)
  and
  [`standard_family_ar_table()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_table.md)
  hard-coded a 15-minute model timestep regardless of what the caller’s
  model actually used, even though the principal decay labels (“12
  hours”, say) only translate to a specific number of model steps – and
  therefore specific AR coefficients – once the timestep is known. Both
  now take and forward `time_step_minutes`, defaulting to 15 for
  backward compatibility.

### Governance

- `R/14-default-parameter-family.R` now carries the mandatory header
  block (it had none), and explanatory comments at each non-obvious
  decision: the tighter-than-default `1e-12` tolerance passed to
  [`roots_to_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/roots_to_parameters.md),
  the [`attr()`](https://rdrr.io/r/base/attr.html)-based provenance
  metadata’s limits (informational only, not guaranteed to survive
  further transformation elsewhere in the package), and the family’s
  implicit shortest representable principal decay (around 1.2 hours at
  default settings, scaling with `time_step_minutes`).
- Added validation and regression tests to `test-default-family-ar.R`:
  invalid `principal_decay`/`time_step_minutes`, the new
  `fast_period_steps` guard, the too-short-principal-decay failure path,
  a `units = "days"` check, and regression coverage for the
  `time_step_minutes` forwarding fix.

## reach.postproc 0.9.5

### Documentation

- `developer-mathematics.Rmd` gains “Floating-point residuals on real
  roots”, immediately after the modal-vs-reciprocal-lag section: why a
  mathematically real root prints with a nonzero imaginary part at the
  $`10^{-15}`$–$`10^{-16}`$ scale (different routes to the same true
  value accumulate different, unrelated floating-point rounding noise),
  and why
  [`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md)’s
  `tolerance = sqrt(.Machine$double.eps)` default correctly classifies
  it as real anyway. Prompted by exactly this showing up while comparing
  the modal and reciprocal-lag worked example.
- `roots-for-novices.Rmd`’s “Try it yourself” section now has a short,
  plain-English note on the same residual, since its own third example
  produces one, with a link through to the full explanation.

## reach.postproc 0.9.4

### Documentation

- `developer-mathematics.Rmd` gains a new section, “Modal roots versus
  reciprocal lag roots”, recording the mathematical contract between
  `reach.postproc`’s modal-root convention
  (`root_real`/`root_imaginary`, stable inside the unit circle) and the
  Box-Jenkins/ARIMA backshift-operator convention
  (`lag_root_real`/`lag_root_imaginary`, stable outside it). The two are
  reciprocals of the same model, not competing answers, and this had
  never been written down as an explicit contract before – it came up as
  a real point of confusion when an external check of this package’s
  root output used the other convention and got, correctly, different
  numbers. Includes a worked, executable example and a one-line warning
  for future maintainers: a convention mismatch isn’t a defect.
- `roots-for-novices.Rmd` now cross-references this section rather than
  leaving `lag_root_*` unexplained.

## reach.postproc 0.9.3

### Documentation

- Added a new vignette, “Characteristic Roots for Novice Flood Forecast
  Modellers” (`roots-for-novices.Rmd`): a plain-English deep dive on
  what a characteristic root is, how modulus and the unit circle
  determine stability, what decay time and oscillation mean in practice,
  how complex conjugate pairs work, and how
  [`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md),
  [`root_table()`](https://jonpayneea.github.io/reach.postproc/reference/root_table.md),
  [`plot_ar()`](https://jonpayneea.github.io/reach.postproc/reference/plot_ar.md),
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  and
  [`decompose_ar()`](https://jonpayneea.github.io/reach.postproc/reference/decompose_ar.md)
  fit together. Includes the hand-checkable worked examples from recent
  root-finding troubleshooting. Added to the pkgdown “Getting started”
  article group, between “ARMA for Novice Flood Forecast Modellers” and
  “Using reach.postproc”.
- README’s vignette list was stale (said “four vignettes”, missed “Event
  Triggered and Time Jumped AR” as well as the new one); corrected to
  list all six.

## reach.postproc 0.9.2

### Bug fixes

- [`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md)
  could never actually produce a genuinely oscillating
  (complex-conjugate) root pair.
  [`root_from_timescale()`](https://jonpayneea.github.io/reach.postproc/reference/root_from_timescale.md)
  always rotates by `+2*pi/period`, so it only ever returns one member
  of a pair; any `oscillation_period` other than `Inf` (real) or `2`
  (real, period-2 alternation) therefore failed
  [`roots_to_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/roots_to_parameters.md)’s
  “complex roots must occur as conjugate pairs” check. In practice this
  meant every parameter set built through the documented timescale API
  was entirely real, which is why
  [`plot_ar()`](https://jonpayneea.github.io/reach.postproc/reference/plot_ar.md)
  never showed a point off the real axis regardless of what was asked
  for – not a plotting bug, a construction one.
  [`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md)
  now adds the missing conjugate automatically whenever a genuinely
  complex root is requested. This changes its order contract: an entry
  with a non-trivial period now contributes two roots, not one, so the
  resulting AR order can exceed `length(decay_times)`. Documented on
  both functions, with a worked oscillating-pair example.

## reach.postproc 0.9.1

### Bug fixes

- Fixed Mermaid diagrams not rendering on the pkgdown home page (the
  “Syntax error in text” box on
  <https://jonpayneea.github.io/reach.postproc/>). The home page is
  built from `README.md` directly, not through knitr, so its fenced
  ```` ```mermaid ```` blocks were rendered by pkgdown as
  `<pre class="mermaid"><code>...</code></pre>`: the diagram source ends
  up nested inside a `<code>` child, which Mermaid’s client-side
  renderer cannot read. Every vignette already avoids this by writing
  diagrams through a `render_mermaid()` helper that emits a flat
  `<pre class="mermaid">TEXT</pre>` with no nesting. `README.md`’s two
  diagrams now use that same raw-HTML shape. The `_pkgdown.yml` unwrap
  script, which was targeting a DOM shape pkgdown has never actually
  produced here, now also targets the shape it does produce, as a
  defensive fallback should a fenced block be used again.
- [`lead_time_series()`](https://jonpayneea.github.io/reach.postproc/reference/lead_time_series.md),
  [`et_ar_series()`](https://jonpayneea.github.io/reach.postproc/reference/et_ar_series.md)
  and
  [`tj_ar_series()`](https://jonpayneea.github.io/reach.postproc/reference/tj_ar_series.md)
  had `@examples` blocks containing only a commented-out call. All three
  now have runnable examples.

## reach.postproc 0.9.0

### New functions

- [`response_time_steps_from_tp()`](https://jonpayneea.github.io/reach.postproc/reference/response_time_steps_from_tp.md):
  converts a catchment time-to-peak into the `response_time_steps`
  argument of
  [`event_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/event_ar_parameters.md).
  **Temporary**: time-to-peak and AR decay time are different physical
  quantities, and equating them is a modelling approximation, not a
  derived equivalence. This belongs in `reach.hydro` once that module
  has a proper FEH or unit-hydrograph time-to-peak calculation; it
  should move there rather than be extended in place. Treat its output
  as a starting estimate to validate with
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  and
  [`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
  /
  [`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md),
  never as a fitted parameter.

## reach.postproc 0.8.1

### Bug fixes

- [`assess_jump_size()`](https://jonpayneea.github.io/reach.postproc/reference/assess_jump_size.md):
  fixed root ranking when the principal root has infinite decay (the
  steady-state ET-AR configuration). The earlier implementation filtered
  to finite decay times before ranking, which dropped the infinite-decay
  principal root and relabelled the remaining two roots as principal and
  middle, with the fast-root figure silently duplicating the middle one.
  Ranking now follows
  [`root_table()`](https://jonpayneea.github.io/reach.postproc/reference/root_table.md)’s
  own `display_order`, so an infinite principal decay is reported as
  such.

### Changes

- Trigger constructors
  ([`logical_et_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/logical_et_trigger.md),
  [`rainfall_accumulation_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/rainfall_accumulation_trigger.md),
  [`updated_threshold_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/updated_threshold_trigger.md),
  [`cwi_adjusted_rainfall_trigger()`](https://jonpayneea.github.io/reach.postproc/reference/cwi_adjusted_rainfall_trigger.md))
  now build their `data` field as a `data.table`, matching the rest of
  the package, rather than a base `data.frame`.
- [`forecast_et_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_et_ar.md)
  now accumulates its per-step series with
  [`data.table::rbindlist()`](https://rdrr.io/pkg/data.table/man/rbindlist.html)
  instead of [`data.frame()`](https://rdrr.io/r/base/data.frame.html)
  rows joined by `do.call(rbind, ...)`.
- All `R/` files now carry the mandatory governance header block.

### Documentation

- Removed `event-triggered-vignette-error.log` and the orphaned
  `event-triggered-and-time-jumped-ar.knit.md` intermediate left behind
  by a failed vignette render predating the
  [`assess_jump_size()`](https://jonpayneea.github.io/reach.postproc/reference/assess_jump_size.md)
  and TJ-AR conditioning fixes. The vignette needs re-rendering with
  [`devtools::build_vignettes()`](https://devtools.r-lib.org/reference/build_vignettes.html)
  in an environment with R installed; that could not be done from this
  session (see commit message).
- `*.knit.md` and `*-error.log` are now gitignored so build
  intermediates and failure logs are not committed again.

## reach.postproc 0.8.0

- Added experimental Event Triggered AR, Time Jumped AR and combined
  ET-TJ-AR.
- Added rainfall, updated-threshold and CWI-adjusted trigger
  constructors.
- Added jump-size diagnostics, tests and a detailed advanced-methods
  vignette.

## reach.postproc 0.7.6

- Restored full vignettes and expanded all public function
  documentation.
