# Setting AR Parameters for a New Model

## Purpose

A decision guide for choosing how to construct AR parameters when a
model has no existing calibration, covering both `reach.postproc`’s own
construction functions and where they sit alongside Performance Testing
(PT) and the current state of ET-AR. It assumes familiarity with the
material in [“Using
reach.postproc”](https://jonpayneea.github.io/reach.postproc/articles/using-reach-postproc.md)
and [“Selecting a Default-Family Parameter
Set”](https://jonpayneea.github.io/reach.postproc/articles/default-parameter-family-section.md).

## The decision

``` mermaid

flowchart TD
    A([New model needs AR parameters]) --> B{Residual series already exists?}
    B -- Yes --> C[Run PT fit on residual series]
    C --> D[PT-fitted coefficients]
    B -- No --> E{Have a specific timescale estimate?}
    E -- No, classification only --> F[Standard published point]
    E -- Yes --> G{Expect default-family fixed roots to fit?}
    G -- Yes --> H[Continuous default-family construction]
    G -- No --> I[Custom timescale construction]
    D --> J[Validation gate: assess, then score against history]
    F --> J
    H --> J
    I --> J
    J --> K([Go live])
    K -. residual series accumulates .-> B
    I -. if steady and event behaviour genuinely differ .-> L[ET-AR: steady and event parameters plus a trigger. Untested, not yet deployable in IMFS]
```

Every solid path converges on the validation gate before go-live. The
dashed loop back from go-live to the top is deliberate, not an edge
case: an a-priori choice made at go-live is provisional until a residual
series exists to fit PT against. The ET-AR branch is tracked, not
actionable today.

## The five paths

### 1. PT-fitted coefficients

PT looks at the model’s residual (observed-minus-simulated) series and
statistically fits an AR model to it. This is the only path here that
estimates coefficients from this catchment’s own data, rather than from
an a-priori timescale judgement. `reach.postproc` does not do this
fitting itself: it has no Yule-Walker, least-squares or
maximum-likelihood estimator anywhere in it, by design. What it does is
consume PT’s output: bring the fitted coefficients in with
[`ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters.md)
and put them through the same assessment and scoring pipeline as every
other path.

**Needs:** a residual series with enough history for PT to fit against.
That means an existing simulation already running, not a model that
hasn’t gone live yet.

**Confidence:** highest, once it exists — it’s the only path grounded in
this catchment’s actual error behaviour rather than a general-purpose
assumption.

### 2. Standard published default-family point

`standard_family_ar_parameters("12 hours")` (or any of the other ten
labels, 3 hours to 64 days, plus Infinite). A broad rapid/medium/slow
classification is enough to pick a label.

**Needs:** no catchment data at all — just a qualitative judgement.

**Confidence:** lowest of the a-priori paths, but the most recognisable
and easiest to defend at governance sign-off, since it’s a named,
published point rather than a bespoke number.

### 3. Continuous default-family construction

[`default_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/default_family_ar_parameters.md),
same fixed shape as option 2 (fixed `a_1`, fixed fast root) but driven
by a specific principal decay estimate — catchment response time, FEH
lag, event analysis — rather than snapping to a published label.

**Needs:** one defensible timescale estimate for the catchment. Does not
need a residual series.

**Confidence:** a step up from option 2 if the timescale estimate is
itself trustworthy; still an a-priori judgement, not a fit.

### 4. Fully custom timescale construction

[`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md).
Breaks free of the default family’s fixed middle and fast roots entirely
— specify every root’s timescale independently, including a genuinely
oscillating pair if there’s reason to think the catchment behaves that
way.

**Needs:** more evidence and more judgement than options 2-3, since
you’re no longer leaning on the default family’s established middle- and
fast-root behaviour at all.

**Confidence:** depends entirely on the quality of the evidence behind
each timescale chosen. Needs the most scrutiny at the assessment and
scoring stage of anything here, because nothing about it is
pre-validated the way the default family is.

### 5. ET-AR (event-triggered) — not yet available

[`et_ar_configuration()`](https://jonpayneea.github.io/reach.postproc/reference/et_ar_configuration.md)
pairing steady and event parameter sets with a trigger. Conceptually the
right answer for a catchment where behaviour genuinely differs between
steady and event conditions, rather than one fixed AR set trying to
cover both. **Currently untested and not deployable in IMFS.** Worth
knowing about and revisiting, not worth building a new model’s go-live
around today.

## How the paths relate: a lifecycle, not a menu

These aren’t five interchangeable alternatives to pick once. For a
genuinely new model, they’re stages: no residual series exists yet, so
PT cannot run; an a-priori path (2, 3 or 4) gets the model to go-live;
the model runs operationally and the residual series accumulates; once
there’s enough history, PT runs; if the PT-fitted coefficients genuinely
improve on the a-priori set, they become the new baseline.

The a-priori choice at go-live is a deliberate, temporary bridge, not a
permanent decision made once and left alone. Record it as such (see
below) so whoever reviews the model later knows a PT refit was always
the intended next step, not something that got missed.

## Choosing between 2, 3 and 4 at go-live

- Know the catchment well enough to name a single timescale (FEH lag, a
  comparable gauge’s response time, a clear classification) but have no
  reason to think it behaves unusually -\> **option 3**, the continuous
  construction. More precise than snapping to a label, still trades on
  the default family’s already-reviewed structure.
- Don’t have a specific timescale, just a broad sense of “fast”,
  “typical” or “slow” -\> **option 2**, a standard label. Fastest to
  agree, easiest to recognise later.
- Have specific reason to think the catchment won’t fit the default
  family’s fixed middle- and fast-root assumptions (unusual secondary
  response, genuine oscillation) -\> **option 4**. Don’t reach for this
  by default; it’s the one that needs the most justification and the
  most validation before trusting it.

## Validation: the same gate, whichever path

Every path ends here, no exceptions:

1.  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    must pass. A pass on a custom-timescale set (option 4) deserves
    closer reading than a pass on a standard set (option 2), since the
    standard family is already a known-good shape and a bespoke one
    isn’t.
2.  Where any historic event data exists at all — even if not enough for
    PT to fit against — run
    [`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
    and
    [`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md)
    against it before trusting the parameters operationally. A pass from
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    only confirms the roots behave sensibly in the abstract; it says
    nothing about whether the update actually helps on this catchment’s
    real events.
3.  For PT-fitted coefficients specifically:
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    them anyway. PT fits from data, it doesn’t know about the
    Environment Agency’s root-acceptance criteria, so a statistically
    good fit can still fail assessment (for instance, a non-permitted
    order, or a borderline-persistent root in a short record).

``` r

assessment <- assess(parameters)
assessment@summary
assessment_table(assessment)

# Where historic events exist, even a short record:
lead_results <- fixed_lead_ar(
  parameters, aligned,
  lead_times_minutes = c(30, 60, 90),
  time_step_minutes = 15
)
score_lead_times(lead_results)
```

## What to record, regardless of path

Matching the provenance fields
[`et_ar_configuration()`](https://jonpayneea.github.io/reach.postproc/reference/et_ar_configuration.md)
and the rest of the package already expect:

- which path was used, and why (the judgement behind option 2/3/4, or
  the PT run reference for option 1)
- site, catchment and model identifiers
- the timescale source, if option 3 or 4 (response-time study, FEH,
  analogous gauge, named expert judgement)
- calibration or construction date and reviewer
- the
  [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
  result
- the intention to revisit once a residual series exists, if this was an
  a-priori go-live choice

## Key messages

1.  A genuinely new model has no residual series, so PT cannot run yet —
    that forces an a-priori choice (standard, continuous or custom) to
    reach go-live.
2.  The a-priori choice is a bridge, not a permanent decision: record it
    as provisional, and refit with PT once enough history exists.
3.  Every path, PT-fitted coefficients included, still has to pass
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    before it is trusted operationally.
4.  ET-AR is the conceptually right answer for genuinely different
    steady and event behaviour, but it isn’t deployable in IMFS yet —
    track it, don’t build a go-live around it.
