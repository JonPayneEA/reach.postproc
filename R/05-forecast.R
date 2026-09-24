S7::method(forecast_ar,ARParameterSet)<-function(x,...,initial_errors,steps=480L,time_step_minutes=15){if(length(initial_errors)!=x@order)stop_bad_argument("Initial errors must match order.");steps<-validate_whole(steps,"steps");state<-initial_errors;values<-numeric(steps);for(i in seq_len(steps)){values[i]<-sum(x@coefficients*state);state<-if(x@order==1L)values[i]else c(values[i],state[-x@order])};ARForecast(parameters=x,initial_errors=initial_errors,series=data.table::data.table(step=seq_len(steps),lead_time_minutes=seq_len(steps)*time_step_minutes,lead_time_hours=format_hours(seq_len(steps),time_step_minutes),ar_error=values),time_step_minutes=time_step_minutes)}
S7::method(decompose_ar,ARParameterSet)<-function(x,...,initial_errors,steps=480L,time_step_minutes=15){z<-roots(x)@values;Z<-outer(-seq_len(x@order),z,function(t,r)r^t);weights<-solve(Z,as.complex(initial_errors));data.table::rbindlist(lapply(seq_along(z),function(j){forecast_step<-seq_len(steps);modal_time<-forecast_step-1L;contribution<-weights[j]*z[j]^modal_time;data.table::data.table(step=forecast_step,lead_time_minutes=forecast_step*time_step_minutes,lead_time_hours=format_hours(forecast_step,time_step_minutes),modal_time=modal_time,root_number=j,weight_real=Re(weights[j]),weight_imaginary=Im(weights[j]),contribution_real=Re(contribution),contribution_imaginary=Im(contribution))}))}
#' Add projected AR error to a simulated forecast
#'
#' Combine a simulation and projected error series, retaining both the
#' unconstrained update and any lower-limited displayed value.
#'
#' @param simulated Numeric simulated level or flow values.
#' @param ar_error Numeric projected errors with the same length and units as
#'   `simulated`.
#' @param lower_limit Optional scalar lower bound, commonly zero. Use `NULL` to
#'   return the unconstrained update unchanged.
#' @param time Optional vector identifying each row. It may contain numeric lead
#'   times or date-times and must match the series length.
#'
#' @returns A `data.table` containing simulation, projected error,
#'   unconstrained update, displayed update and a flag showing where the lower
#'   limit was applied.
#'
#' @examples
#' apply_ar_update(
#'   simulated = c(0.10, 0.08, 0.05),
#'   ar_error = c(-0.05, -0.10, -0.04),
#'   lower_limit = 0,
#'   time = c(15, 30, 45)
#' )
#' @export
apply_ar_update<-function(simulated,ar_error,lower_limit=NULL,time=seq_along(simulated)){if(length(simulated)!=length(ar_error))stop_bad_argument("Series lengths differ.");u<-simulated+ar_error;v<-if(is.null(lower_limit))u else pmax(u,lower_limit);data.table::data.table(time=time,simulated=simulated,ar_error=ar_error,updated_unconstrained=u,updated=v,was_limited=!is.na(v)&v!=u)}
