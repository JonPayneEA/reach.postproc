S7::method(forecast_ar,ARParameterSet)<-function(x,...,initial_errors,steps=480L,time_step_minutes=15){if(length(initial_errors)!=x@order)stop_bad_argument("Initial errors must match order.");steps<-validate_whole(steps,"steps");state<-initial_errors;values<-numeric(steps);for(i in seq_len(steps)){values[i]<-sum(x@coefficients*state);state<-if(x@order==1L)values[i] else c(values[i],state[-x@order])};ARForecast(parameters=x,initial_errors=initial_errors,series=data.table::data.table(step=seq_len(steps),lead_time_minutes=seq_len(steps)*time_step_minutes,lead_time_hours=format_hours(seq_len(steps),time_step_minutes),ar_error=values),time_step_minutes=time_step_minutes)}
S7::method(decompose_ar,ARParameterSet)<-function(x,...,initial_errors,steps=480L,time_step_minutes=15){z<-roots(x)@values;Z<-outer(-seq_len(x@order),z,function(t,r)r^t);weights<-solve(Z,as.complex(initial_errors));data.table::rbindlist(lapply(seq_along(z),function(j){forecast_step<-seq_len(steps);modal_time<-forecast_step-1L;contribution<-weights[j]*z[j]^modal_time;data.table::data.table(step=forecast_step,lead_time_minutes=forecast_step*time_step_minutes,lead_time_hours=format_hours(forecast_step,time_step_minutes),modal_time=modal_time,root_number=j,contribution_real=Re(contribution),contribution_imaginary=Im(contribution))}))}
#' Apply projected errors
#'
#' @param simulated Simulations.
#' @param ar_error Error projections.
#' @param lower_limit Optional bound.
#' @param time Time values.
#'
#' @returns Data table.
#' @export
apply_ar_update<-function(simulated,ar_error,lower_limit=NULL,time=seq_along(simulated)){u<-simulated+ar_error;v<-if(is.null(lower_limit))u else pmax(u,lower_limit);data.table::data.table(time=time,simulated=simulated,ar_error=ar_error,updated_unconstrained=u,updated=v,was_limited=v!=u)}
