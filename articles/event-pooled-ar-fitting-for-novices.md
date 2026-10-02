# Event-Pooled AR Fitting for Novice Flood Forecast Modellers

## Purpose

[“ARMA for Novice Flood Forecast
Modellers”](https://jonpayneea.github.io/reach.postproc/articles/arma-for-novices.md)
explains what AR does. [“Setting AR Parameters for a New
Model”](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md)
explains the usual ways to get AR coefficients for a model. This
vignette covers one more option that sits alongside those:
`fit_ar_from_events()`, a way of calibrating AR coefficients using only
flood events, rather than a model’s whole history. No background in
time-series mathematics is assumed.

## The problem this solves

The usual way AR coefficients get fitted is Performance Testing (PT): it
looks at a model’s whole residual record — every day it has ever run,
flood or not — and fits one AR model to all of it. That works, but it
has a quirk worth understanding: ordinary, everyday flow and quiet
low-flow periods make up most of that record, by simple weight of time.
A flood might be a handful of days a year; the rest is normal running.
PT’s fit reflects whatever is *typical* of the whole record, which is
mostly not flood behaviour at all, even though AR’s whole job is
correcting the forecast during floods.

``` mermaid

flowchart LR
    A[Whole residual record] --> B[Mostly normal and low flow]
    A --> C[A few flood events]
    B --> D[PT fits one model to all of it]
    C --> D
    D --> E[Fit mostly reflects normal-flow behaviour]
```

`fit_ar_from_events()` is a different way of fitting: give it only the
event windows you actually care about, and it fits coefficients from
those alone. Normal and low flow never get a vote.

## Why not just glue the events together?

The obvious-looking shortcut is to paste all your flood events end to
end into one long series and fit an ordinary AR model to that. This does
not work, and it is worth seeing why rather than just taking that on
trust.

AR works by looking at what happened one timestep ago, and the one
before that, to predict what happens next. If you paste event A’s last
timestep directly in front of event B’s first timestep, the fitting
process reads those as neighbours — as though B started the instant A
finished. In reality they might be two completely different floods,
years apart. That invented, fictional “just happened before”
relationship pollutes the very thing you are trying to measure: how the
error actually evolves from one timestep to the next.

``` mermaid

flowchart LR
    A[Event A ends]
    B[Event B begins]
    A -. invented adjacency .-> B
    B --> C[AR fit wrongly treats these as consecutive timesteps]
```

`fit_ar_from_events()` avoids this altogether. It keeps every event’s
own history separate when building the fit, and only combines the
*results* across events, never the raw timesteps. No event’s ending ever
gets treated as another event’s beginning.

## Why weighting matters

Once you are combining several events into one fit, a new question
appears: should every event count equally? The surprising answer is that
counting by “how many timesteps did this event last” is not enough on
its own.

Picture a room of people voting. If one person shouts far louder than
everyone else, giving each *person* one vote does not stop the loud one
from dominating the discussion — their volume still drowns the room out,
regardless of the headcount. The same thing happens here: an event whose
errors happen to be unusually large in scale can pull a pooled fit
toward its own behaviour, even if it is only one event among many,
unless the fitting process specifically corrects for how loud — how
large in scale — each event’s errors are, not just how long it lasted.

This is exactly why `fit_ar_from_events()` weights each event by the
inverse of its own internal variance by default
(`weighting = "variance"`). It was checked with a deliberately extreme
test case before this function was written: one highly atypical,
much-larger event among many ordinary ones. Weighting by row count alone
barely helped; only weighting by variance kept the fit close to what the
ordinary events actually shared. See [“Event-Pooled AR Fitting:
Mathematics and
Validation”](https://jonpayneea.github.io/reach.postproc/articles/event-pooled-ar-fitting.md)
for the full numerical demonstration, reproducible in your own R
session.

## Using it

``` r

set.seed(11)
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
#>  0.8606041 -0.1203371
```

Each event is a numeric vector of that event’s residuals (observed minus
simulated), in the order they actually happened — oldest first. This is
the opposite of how you’d supply `initial_errors` to
[`forecast_ar()`](https://jonpayneea.github.io/reach.postproc/reference/forecast_ar.md),
which wants the most recent value first: here you are fitting from
history, not projecting a forecast forward from today.

## Reading the output

`fit_ar_from_events()` attaches a table showing how much each event
actually contributed to the fit:

``` r

attr(fitted, "fit_per_event")
#>         event n_timesteps n_rows variance weight_share
#>        <char>       <int>  <int>    <num>        <num>
#> 1: flood_2019          40     38 1.751978    0.3221024
#> 2: flood_2020          25     23 1.017079    0.5548406
#> 3: flood_2021          60     58 4.585816    0.1230570
```

`weight_share` is the part worth watching. If events are roughly
comparable, their shares should be roughly even. One event sitting far
above the rest is a prompt to look closer — is it genuinely
representative, or is something about it (a data problem, an unusually
severe or unusual flood) worth treating separately rather than pooling
in by default?

## Treat the result like any other parameter set

A pooled fit is still just an AR parameter set once it comes out the
other end — it does not skip the usual checks:

``` r

assessment <- assess(fitted, permitted_orders = c(2L, 3L))
assessment@summary
#> [1] "Fail: All roots decay too quickly"
```

Run
[`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
on it, and where you have events held back from the fit, score it with
[`fixed_lead_ar()`](https://jonpayneea.github.io/reach.postproc/reference/fixed_lead_ar.md)
and
[`score_lead_times()`](https://jonpayneea.github.io/reach.postproc/reference/score_lead_times.md)
before trusting it operationally — exactly as the [“Setting AR
Parameters for a New
Model”](https://jonpayneea.github.io/reach.postproc/articles/setting-parameters-for-a-new-model.md)
decision guide recommends for every other path.

## When to reach for this

``` mermaid

flowchart TD
    A{Do you have a residual series PT can fit?}
    A -- No --> B[Use a default-family or standard construction instead]
    A -- Yes --> C{Do you specifically want event-only calibration,&lt;br/&gt;not PT's whole-record fit?}
    C -- No --> D[Use PT as usual]
    C -- Yes --> E[fit_ar_from_events on your event windows]
```

This is not a replacement for PT in general. If a model has run long
enough to have a full residual history and there’s no particular concern
about normal flow diluting the fit, PT remains the higher-confidence
choice. Reach for `fit_ar_from_events()` specifically when you want
calibration that only “sees” flood behaviour.

## Key messages

1.  PT fits across a model’s whole record, so normal and low flow — most
    of that record, by time — shape the fit of a model meant to correct
    floods specifically.
2.  Pasting events together before fitting invents a false “just
    happened before” relationship at every join; `fit_ar_from_events()`
    keeps events separate while fitting.
3.  Counting events equally by length is not enough to stop one
    unusually large event from dominating; this function corrects for
    scale (variance), not just event length, by default.
4.  The result is an ordinary AR parameter set — it still needs
    [`assess()`](https://jonpayneea.github.io/reach.postproc/reference/assess.md)
    and, where possible, scoring against real events, exactly like every
    other path.
