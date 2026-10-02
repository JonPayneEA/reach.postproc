# Construct a default-family AR parameter set

`default_family_ar_parameters()` calculates a continuous member of the
default parameter family. It does not interpolate AR coefficients
between rows in the published table.

The modeller selects a principal decay time from catchment evidence,
such as response time, FEH lag, event analysis or a broad rapid, medium
or slow classification. The function then derives the characteristic
roots and AR coefficients deterministically.

## Usage

``` r
default_family_ar_parameters(
  principal_decay,
  units = c("steps", "hours", "days"),
  time_step_minutes = 15,
  first_coefficient = 1.765,
  fast_decay_steps = 1/3,
  fast_period_steps = 2,
  label = NULL
)
```

## Arguments

- principal_decay:

  One positive number giving the desired principal decay time. Use `Inf`
  for a non-decaying principal root.

- units:

  Unit used by `principal_decay`: `"steps"`, `"hours"` or `"days"`.

- time_step_minutes:

  Duration of one model timestep in minutes. Current IMFS AR models
  normally use 15-minute timesteps.

- first_coefficient:

  Fixed first AR coefficient. The published default family uses `1.765`.

- fast_decay_steps:

  Decay time of the rapid oscillating root in model timesteps. The
  published family uses `1 / 3`.

- fast_period_steps:

  Oscillation period of the rapid root in timesteps. The published
  family uses `2`, which gives a negative real root.

- label:

  Optional description attached to the returned parameter set.

## Value

An AR parameter object in Deltares convention. Attributes record the
requested principal decay, solved middle decay and modal roots.

## Details

Create a third-order autoregressive parameter set from one interpretable
timescale: the principal decay time. The function implements the
analytical construction used to produce the published family of default
parameter sets.

A third-order AR model has three characteristic roots. Within this
default family:

- the principal positive root is set from the requested decay time;

- the rapid negative root retains a decay time of one-third of a
  timestep and an oscillation period of two timesteps;

- the first AR coefficient is held at `1.765`;

- the remaining positive root is solved from the sum of the three roots.

For principal decay time \\\tau_1\\, the principal modal root is

\$\$z_1 = \exp(-1 / \tau_1).\$\$

Infinite principal decay gives \\z_1 = 1\\. The fast root is

\$\$z_3 = \exp(-1 / \tau_3)\exp(2\pi i / T_3),\$\$

with \\\tau_3 = 1/3\\ and \\T_3 = 2\\ by default. Because \\a_1 = z_1 +
z_2 + z_3\\, the middle root is

\$\$z_2 = a_1 - z_1 - z_3.\$\$

The three roots are converted to Deltares AR coefficients. The published
default table contains selected standard points from this continuous
family. It supports recognition, governance and verification; it is not
used for interpolation.

Coefficients should be stored at full double precision. Where
coefficients are transferred manually, retain at least five significant
figures.

## See also

[`standard_family_ar_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/standard_family_ar_parameters.md),
[`roots()`](https://jonpayneea.github.io/reach.postproc/reference/roots.md),
[`roots_to_parameters()`](https://jonpayneea.github.io/reach.postproc/reference/roots_to_parameters.md),
[`ar_parameters_from_timescales()`](https://jonpayneea.github.io/reach.postproc/reference/ar_parameters_from_timescales.md)

## Examples

``` r
nine_hour <- default_family_ar_parameters(
  principal_decay = 9,
  units = "hours"
)

nine_hour@coefficients
#>         a_1         a_2         a_3 
#>  1.76500000 -0.72875763 -0.04078111 
root_table(roots(nine_hour, time_step_minutes = 15))
#>    root_id   root_real root_imaginary root_modulus lag_root_real
#>      <int>       <num>          <num>        <num>         <num>
#> 1:       3  0.97260448   9.047288e-26   0.97260448      1.028167
#> 2:       2  0.84218259  -9.047288e-26   0.84218259      1.187391
#> 3:       1 -0.04978707   0.000000e+00   0.04978707    -20.085537
#>    lag_root_imaginary lag_root_modulus raw_decay_time_steps decay_time_steps
#>                 <num>            <num>                <num>            <num>
#> 1:      -9.564139e-26         1.028167           36.0000000       36.0000000
#> 2:       1.275575e-25         1.187391            5.8221304        5.8221304
#> 3:       0.000000e+00        20.085537            0.3333333        0.3333333
#>    effective_decay_time_steps decay_time_hours effective_decay_time_hours
#>                         <num>            <num>                      <num>
#> 1:                 36.0000000       9.00000000                 9.00000000
#> 2:                  5.8221304       1.45553260                 1.45553260
#> 3:                  0.2338711       0.08333333                 0.05846776
#>    oscillation_period_steps oscillation_period_hours is_growing is_persistent
#>                       <num>                    <num>     <lgcl>        <lgcl>
#> 1:                      Inf                      Inf      FALSE         FALSE
#> 2:                      Inf                      Inf      FALSE         FALSE
#> 3:                        2                      0.5      FALSE         FALSE
#>    is_oscillating modal_stability lag_stability display_order
#>            <lgcl>          <fctr>        <fctr>         <int>
#> 1:          FALSE          Stable        Stable             1
#> 2:          FALSE          Stable        Stable             2
#> 3:           TRUE          Stable        Stable             3

one_day <- default_family_ar_parameters(
  principal_decay = 1,
  units = "days"
)

steady <- default_family_ar_parameters(
  principal_decay = Inf,
  units = "steps"
)
```
