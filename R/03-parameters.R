#' Detect effective AR order
#'
#' @param coefficients Coefficients.
#' @param tolerance Activity tolerance.
#'
#' @returns Integer order.
#' @export
detect_ar_order <- function(coefficients,tolerance=1e-8){validate_numeric(coefficients,"coefficients");active<-which(abs(coefficients)>tolerance);if(!length(active))0L else as.integer(max(active))}
#' Detect effective MA order
#'
#' @inheritParams detect_ar_order
#'
#' @returns Integer order.
#' @export
detect_ma_order <- function(coefficients,tolerance=1e-8)if(!length(coefficients))0L else detect_ar_order(coefficients,tolerance)
#' Convert coefficient sign convention
#'
#' @param coefficients Coefficients.
#' @param from Current convention.
#' @param to Required convention.
#'
#' @returns Converted values.
#' @export
convert_sign_convention <- function(coefficients,from=c("Deltares","Standard"),to=c("Deltares","Standard")){from<-match.arg(from);to<-match.arg(to);if(identical(from,to))coefficients else -coefficients}
#' Construct AR parameters
#'
#' @param coefficients Coefficients from first to highest order.
#' @param label Label.
#'
#' @param sign_convention Input convention.
#' @param order_tolerance Tolerance.
#' @param ... Alternative coefficient input.
#'
#'
#' @returns An internal parameter object.
#' @export
ar_parameters <- function(coefficients=NULL,label="AR parameter set",sign_convention=c("Deltares","Standard"),order_tolerance=1e-8,...){
 sign_convention<-match.arg(sign_convention);dots<-unlist(list(...),recursive=TRUE,use.names=TRUE)
 if(!is.null(coefficients)&&length(dots))stop_bad_argument("Supply coefficients through one route only.")
 values<-if(is.null(coefficients))dots else coefficients;validate_numeric(values,"coefficients")
 values<-convert_sign_convention(values,sign_convention,"Deltares");order<-detect_ar_order(values,order_tolerance)
 if(!order)stop_bad_argument("At least one coefficient must be active.");values<-values[seq_len(order)];names(values)<-paste0("a_",seq_along(values))
 ARParameterSet(coefficients=values,order=order,sign_convention="Deltares",order_tolerance=order_tolerance,label=label)}
#' 2024 EA default AR parameters
#'
#'
#' @returns An internal parameter object.
#' @export
default_ar_parameters <- function() ar_parameters(c(1.765,-0.72625,-0.040656),label="2024 EA default")
#' Construct a modal root from timescales
#'
#' @param decay_time Decay time.
#' @param oscillation_period Period.
#'
#' @returns Complex root.
#' @export
root_from_timescale <- function(decay_time,oscillation_period=Inf){m<-exp(-1/decay_time);if(is.infinite(oscillation_period))as.complex(m) else m*exp(1i*2*pi/oscillation_period)}
#' Convert modal roots to parameters
#'
#' @param root_values Modal roots.
#' @param label Label.
#' @param tolerance Tolerance.
#'
#' @returns Parameter object.
#' @export
roots_to_parameters <- function(root_values,label="Derived from roots",tolerance=1e-10){
 poly<-as.complex(1);for(r in root_values)poly<-multiply_polynomials_ascending(poly,c(-r,1))
 a<--rev(poly[-length(poly)]);if(any(abs(Im(a))>tolerance))stop_bad_argument("Complex roots must occur as conjugate pairs.")
 ar_parameters(Re(a),label=label,order_tolerance=tolerance)}
#' Construct parameters from root timescales
#'
#' @param decay_times Decay times.
#' @param oscillation_periods Periods.
#' @param label Label.
#' @param tolerance Tolerance.
#'
#'
#' @returns Parameter object.
#' @export
ar_parameters_from_timescales <- function(decay_times,oscillation_periods=rep(Inf,length(decay_times)),label="Derived from timescales",tolerance=1e-10){roots_to_parameters(mapply(root_from_timescale,decay_times,oscillation_periods),label,tolerance)}
#' Calculate observed-minus-simulated error
#'
#' @param observed Observations.
#' @param simulated Simulations.
#'
#' @returns Errors.
#' @export
calculate_model_error <- function(observed,simulated){if(length(observed)!=length(simulated))stop_bad_argument("Series lengths differ.");observed-simulated}
