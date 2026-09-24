#' Detect effective autoregressive order
#'
#' Identify the highest active AR lag after allowing for small numerical values
#' in trailing coefficients.
#'
#' @param coefficients Numeric coefficients ordered from first to highest lag.
#' @param tolerance Non-negative activity threshold. A coefficient is active
#'   when its absolute value exceeds this value.
#'
#' @returns A single integer. Zero means no coefficient exceeds `tolerance`.
#'
#' @examples
#' detect_ar_order(c(0.8, -0.2, 0))
#' detect_ar_order(c(0.8, -0.2, 1e-12), tolerance = 1e-8)
#' @export
detect_ar_order <- function(coefficients,tolerance=1e-8){validate_numeric(coefficients,"coefficients");active<-which(abs(coefficients)>tolerance);if(!length(active))0L else as.integer(max(active))}
#' Detect effective moving-average order
#'
#' Identify the highest active MA lag after allowing for small trailing values.
#'
#' @param coefficients Numeric MA coefficients ordered from the most recent
#'   innovation to the oldest.
#' @param tolerance Non-negative activity threshold.
#'
#' @returns A single integer. An empty coefficient vector has order zero.
#'
#' @examples
#' detect_ma_order(c(-0.5, -0.25, 0))
#' detect_ma_order(numeric())
#' @export
detect_ma_order <- function(coefficients,tolerance=1e-8)if(!length(coefficients))0L else detect_ar_order(coefficients,tolerance)
#' Convert AR coefficient signs between supported conventions
#'
#' Change the signs of a coefficient vector when moving between the Deltares
#' recurrence and the alternative signed equation convention.
#'
#' @param coefficients Numeric vector ordered from first to highest lag.
#' @param from Convention currently used by `coefficients`.
#' @param to Convention required in the returned vector.
#'
#' @returns A numeric vector in the requested convention. Coefficient order and
#'   names are preserved.
#'
#' @examples
#' convert_sign_convention(
#'   coefficients = c(1.765, -0.72625, -0.040656),
#'   from = "Deltares",
#'   to = "Standard"
#' )
#' @export
convert_sign_convention <- function(coefficients,from=c("Deltares","Standard"),to=c("Deltares","Standard")){from<-match.arg(from);to<-match.arg(to);validate_numeric(coefficients,"coefficients");if(identical(from,to))coefficients else -coefficients}
#' Construct an autoregressive parameter set
#'
#' Create and validate the coefficients used by the AR recurrence. The function
#' accepts either the Deltares convention used by IMFS or the alternative signed
#' equation convention. It converts the supplied values to Deltares convention
#' once and stores that form internally.
#'
#' @param coefficients Numeric vector of AR coefficients ordered from the first
#'   lag to the highest lag. For AR(3), use `c(a_1, a_2, a_3)`. Names are
#'   optional. Supply either `coefficients` or values through `...`, not both.
#' @param label Single character value describing the parameter set, site,
#'   calibration or source. The label is retained for printing and reporting.
#' @param sign_convention Convention used by `coefficients`. Use `"Deltares"`
#'   for `x_t = a_1 x_{t-1} + ... + a_p x_{t-p}`. Use `"Standard"` where the
#'   lag terms are written on the left-hand side and therefore have opposite
#'   signs.
#' @param order_tolerance Non-negative numerical tolerance used to identify
#'   inactive trailing coefficients. A trailing coefficient whose absolute value
#'   is no greater than this tolerance is omitted when determining AR order.
#' @param ... Alternative coefficient input. This supports calls such as
#'   `ar_parameters(a_1 = 0.8)`. Do not combine this form with `coefficients`.
#'
#' @returns An internal AR parameter object accepted by [roots()], [assess()],
#'   [forecast_ar()] and the fixed lead-time functions.
#'
#' @examples
#' deltares <- ar_parameters(
#'   coefficients = c(1.765, -0.72625, -0.040656),
#'   sign_convention = "Deltares",
#'   label = "2024 defaults"
#' )
#'
#' standard <- ar_parameters(
#'   coefficients = c(-1.765, 0.72625, 0.040656),
#'   sign_convention = "Standard"
#' )
#'
#' all.equal(deltares@coefficients, standard@coefficients)
#' @export
ar_parameters <- function(coefficients=NULL,label="AR parameter set",sign_convention=c("Deltares","Standard"),order_tolerance=1e-8,...){sign_convention<-match.arg(sign_convention);dots<-unlist(list(...),recursive=TRUE,use.names=TRUE);if(!is.null(coefficients)&&length(dots))stop_bad_argument("Supply coefficients through one route only.");values<-if(is.null(coefficients))dots else coefficients;validate_numeric(values,"coefficients");values<-convert_sign_convention(values,sign_convention,"Deltares");order<-detect_ar_order(values,order_tolerance);if(!order)stop_bad_argument("At least one coefficient must be active.");values<-values[seq_len(order)];names(values)<-paste0("a_",seq_along(values));ARParameterSet(coefficients=values,order=order,sign_convention="Deltares",order_tolerance=order_tolerance,label=label)}
#' Return the Environment Agency 2024 default AR parameters
#'
#' Create the approved third-order default parameter set used throughout the
#' package examples. The coefficients are retained at their stated precision.
#'
#' @returns An AR(3) parameter object with Deltares coefficients `1.765`,
#'   `-0.72625` and `-0.040656`.
#'
#' @examples
#' parameters <- default_ar_parameters()
#' parameters@coefficients
#' assessment_table(assess(parameters))
#' @export
default_ar_parameters <- function()ar_parameters(c(1.765,-0.72625,-0.040656),label="2024 EA default")
#' Construct one modal root from decay and oscillation timescales
#'
#' Convert an interpretable decay time and oscillation period into a complex
#' modal root. Times are expressed in model timesteps, not hours.
#'
#' @param decay_time Non-zero numeric decay time in model steps. Positive values
#'   create decaying roots. Negative values represent growth and should normally
#'   be used only for testing assessment behaviour.
#' @param oscillation_period Numeric period in model steps. Use `Inf` for a
#'   positive real, non-oscillating root. Use `2` for a negative real root that
#'   changes sign every timestep.
#'
#' @returns One complex modal root.
#'
#' @examples
#' root_from_timescale(decay_time = 96, oscillation_period = Inf)
#' root_from_timescale(decay_time = 0.3333, oscillation_period = 2)
#' @export
root_from_timescale <- function(decay_time,oscillation_period=Inf){if(length(decay_time)!=1L||is.na(decay_time)||decay_time==0)stop_bad_argument("Invalid decay time.");if(length(oscillation_period)!=1L||is.na(oscillation_period)||oscillation_period<2)stop_bad_argument("Invalid period.");m<-exp(-1/decay_time);if(is.infinite(oscillation_period))as.complex(m)else m*exp(1i*2*pi/oscillation_period)}
#' Convert modal roots to AR coefficients
#'
#' Construct the Deltares AR polynomial from supplied modal roots. Complex roots
#' must occur as conjugate pairs so the resulting coefficients are real.
#'
#' @param root_values Numeric or complex vector of modal roots. These are the
#'   roots used by the Environment Agency guidance, for which stable roots lie
#'   inside the unit circle. Do not supply reciprocal lag-polynomial roots.
#' @param label Description attached to the returned parameter set.
#' @param tolerance Maximum permitted imaginary remainder in the calculated
#'   coefficients and the activity tolerance used to identify AR order.
#'
#' @returns An AR parameter object in Deltares convention.
#'
#' @examples
#' original <- default_ar_parameters()
#' modal_roots <- roots(original)@values
#' reconstructed <- roots_to_parameters(modal_roots)
#'
#' all.equal(
#'   original@coefficients,
#'   reconstructed@coefficients,
#'   tolerance = 1e-9
#' )
#' @export
roots_to_parameters <- function(root_values,label="Derived from roots",tolerance=1e-10){poly<-as.complex(1);for(r in root_values)poly<-multiply_polynomials_ascending(poly,c(-r,1));a<--rev(poly[-length(poly)]);if(any(abs(Im(a))>tolerance))stop_bad_argument("Complex roots must occur as conjugate pairs.");ar_parameters(Re(a),label=label,order_tolerance=tolerance)}
#' Construct AR parameters from root timescales
#'
#' Build interpretable modal roots from decay times and oscillation periods, then
#' convert those roots to Deltares AR coefficients.
#'
#' @param decay_times Numeric vector of decay times in model steps, one value per
#'   required root.
#' @param oscillation_periods Numeric vector of matching periods in model steps.
#'   Use `Inf` for non-oscillating positive roots and `2` for negative real roots.
#' @param label Description attached to the result.
#' @param tolerance Numerical tolerance used during root-to-coefficient
#'   conversion.
#'
#' @returns An AR parameter object whose order equals the number of supplied
#'   roots after numerical trimming.
#'
#' @examples
#' parameters <- ar_parameters_from_timescales(
#'   decay_times = c(96, 5.203171, 1 / 3),
#'   oscillation_periods = c(Inf, Inf, 2),
#'   label = "Example AR(3)"
#' )
#'
#' parameters@coefficients
#' root_table(roots(parameters))
#' @export
ar_parameters_from_timescales <- function(decay_times,oscillation_periods=rep(Inf,length(decay_times)),label="Derived from timescales",tolerance=1e-10){if(length(decay_times)!=length(oscillation_periods))stop_bad_argument("Timescale vectors must have equal lengths.");roots_to_parameters(mapply(root_from_timescale,decay_times,oscillation_periods),label,tolerance)}
#' Calculate observed-minus-simulated model error
#'
#' Apply the package-wide error convention used to initialise and evaluate AR
#' forecasts.
#'
#' @param observed Numeric vector of observed level or flow values.
#' @param simulated Numeric vector of model values in the same domain, units,
#'   timestamps and order as `observed`.
#'
#' @returns Numeric vector calculated as `observed - simulated`. Positive values
#'   mean the simulation is too low.
#'
#' @examples
#' calculate_model_error(
#'   observed = c(1.20, 1.30),
#'   simulated = c(1.00, 1.35)
#' )
#' @export
calculate_model_error <- function(observed,simulated){if(length(observed)!=length(simulated))stop_bad_argument("Series lengths differ.");observed-simulated}
