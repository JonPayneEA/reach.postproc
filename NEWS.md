# reach.postproc 0.9.5

## Documentation
- `developer-mathematics.Rmd` gains "Floating-point residuals on real
  roots", immediately after the modal-vs-reciprocal-lag section: why a
  mathematically real root prints with a nonzero imaginary part at the
  $10^{-15}$--$10^{-16}$ scale (different routes to the same true value
  accumulate different, unrelated floating-point rounding noise), and why
  `roots()`'s `tolerance = sqrt(.Machine$double.eps)` default correctly
  classifies it as real anyway. Prompted by exactly this showing up while
  comparing the modal and reciprocal-lag worked example.
- `roots-for-novices.Rmd`'s "Try it yourself" section now has a short,
  plain-English note on the same residual, since its own third example
  produces one, with a link through to the full explanation.

# reach.postproc 0.9.4

## Documentation
- `developer-mathematics.Rmd` gains a new section, "Modal roots versus
  reciprocal lag roots", recording the mathematical contract between
  `reach.postproc`'s modal-root convention (`root_real`/`root_imaginary`,
  stable inside the unit circle) and the Box-Jenkins/ARIMA backshift-operator
  convention (`lag_root_real`/`lag_root_imaginary`, stable outside it). The
  two are reciprocals of the same model, not competing answers, and this
  had never been written down as an explicit contract before -- it came up
  as a real point of confusion when an external check of this package's
  root output used the other convention and got, correctly, different
  numbers. Includes a worked, executable example and a one-line warning for
  future maintainers: a convention mismatch isn't a defect.
- `roots-for-novices.Rmd` now cross-references this section rather than
  leaving `lag_root_*` unexplained.

# reach.postproc 0.9.3

## Documentation
- Added a new vignette, "Characteristic Roots for Novice Flood Forecast
  Modellers" (`roots-for-novices.Rmd`): a plain-English deep dive on what a
  characteristic root is, how modulus and the unit circle determine
  stability, what decay time and oscillation mean in practice, how complex
  conjugate pairs work, and how `roots()`, `root_table()`, `plot_ar()`,
  `assess()` and `decompose_ar()` fit together. Includes the hand-checkable
  worked examples from recent root-finding troubleshooting. Added to the
  pkgdown "Getting started" article group, between "ARMA for Novice Flood
  Forecast Modellers" and "Using reach.postproc".
- README's vignette list was stale (said "four vignettes", missed "Event
  Triggered and Time Jumped AR" as well as the new one); corrected to list
  all six.

# reach.postproc 0.9.2

## Bug fixes
- `ar_parameters_from_timescales()` could never actually produce a genuinely
  oscillating (complex-conjugate) root pair. `root_from_timescale()` always
  rotates by `+2*pi/period`, so it only ever returns one member of a pair;
  any `oscillation_period` other than `Inf` (real) or `2` (real, period-2
  alternation) therefore failed `roots_to_parameters()`'s "complex roots
  must occur as conjugate pairs" check. In practice this meant every
  parameter set built through the documented timescale API was entirely
  real, which is why `plot_ar()` never showed a point off the real axis
  regardless of what was asked for -- not a plotting bug, a construction
  one. `ar_parameters_from_timescales()` now adds the missing conjugate
  automatically whenever a genuinely complex root is requested. This
  changes its order contract: an entry with a non-trivial period now
  contributes two roots, not one, so the resulting AR order can exceed
  `length(decay_times)`. Documented on both functions, with a worked
  oscillating-pair example.

# reach.postproc 0.9.1

## Bug fixes
- Fixed Mermaid diagrams not rendering on the pkgdown home page (the "Syntax
  error in text" box on https://jonpayneea.github.io/reach.postproc/). The
  home page is built from `README.md` directly, not through knitr, so its
  fenced ` ```mermaid ` blocks were rendered by pkgdown as
  `<pre class="mermaid"><code>...</code></pre>`: the diagram source ends up
  nested inside a `<code>` child, which Mermaid's client-side renderer
  cannot read. Every vignette already avoids this by writing diagrams
  through a `render_mermaid()` helper that emits a flat
  `<pre class="mermaid">TEXT</pre>` with no nesting. `README.md`'s two
  diagrams now use that same raw-HTML shape. The `_pkgdown.yml` unwrap
  script, which was targeting a DOM shape pkgdown has never actually
  produced here, now also targets the shape it does produce, as a
  defensive fallback should a fenced block be used again.
- `lead_time_series()`, `et_ar_series()` and `tj_ar_series()` had
  `@examples` blocks containing only a commented-out call. All three now
  have runnable examples.

# reach.postproc 0.9.0

## New functions
- `response_time_steps_from_tp()`: converts a catchment time-to-peak into the
  `response_time_steps` argument of `event_ar_parameters()`. **Temporary**:
  time-to-peak and AR decay time are different physical quantities, and
  equating them is a modelling approximation, not a derived equivalence.
  This belongs in `reach.hydro` once that module has a proper FEH or
  unit-hydrograph time-to-peak calculation; it should move there rather
  than be extended in place. Treat its output as a starting estimate to
  validate with `assess()` and `fixed_lead_ar()` / `score_lead_times()`,
  never as a fitted parameter.

# reach.postproc 0.8.1

## Bug fixes
- `assess_jump_size()`: fixed root ranking when the principal root has
  infinite decay (the steady-state ET-AR configuration). The earlier
  implementation filtered to finite decay times before ranking, which
  dropped the infinite-decay principal root and relabelled the remaining
  two roots as principal and middle, with the fast-root figure silently
  duplicating the middle one. Ranking now follows `root_table()`'s own
  `display_order`, so an infinite principal decay is reported as such.

## Changes
- Trigger constructors (`logical_et_trigger()`, `rainfall_accumulation_trigger()`,
  `updated_threshold_trigger()`, `cwi_adjusted_rainfall_trigger()`) now build
  their `data` field as a `data.table`, matching the rest of the package,
  rather than a base `data.frame`.
- `forecast_et_ar()` now accumulates its per-step series with
  `data.table::rbindlist()` instead of `data.frame()` rows joined by
  `do.call(rbind, ...)`.
- All `R/` files now carry the mandatory governance header block.

## Documentation
- Removed `event-triggered-vignette-error.log` and the orphaned
  `event-triggered-and-time-jumped-ar.knit.md` intermediate left behind by a
  failed vignette render predating the `assess_jump_size()` and TJ-AR
  conditioning fixes. The vignette needs re-rendering with
  `devtools::build_vignettes()` in an environment with R installed; that
  could not be done from this session (see commit message).
- `*.knit.md` and `*-error.log` are now gitignored so build intermediates and
  failure logs are not committed again.

# reach.postproc 0.8.0

- Added experimental Event Triggered AR, Time Jumped AR and combined ET-TJ-AR.
- Added rainfall, updated-threshold and CWI-adjusted trigger constructors.
- Added jump-size diagnostics, tests and a detailed advanced-methods vignette.

# reach.postproc 0.7.6

- Restored full vignettes and expanded all public function documentation.
