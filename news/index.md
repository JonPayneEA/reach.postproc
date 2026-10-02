# Changelog

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

- `response_time_steps_from_tp()`: converts a catchment time-to-peak
  into the `response_time_steps` argument of
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
  `devtools::build_vignettes()` in an environment with R installed; that
  could not be done from this session (see commit message).
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
