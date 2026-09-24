#' Evaluate a deterministic ARMA recurrence
#'
#' @param parameters AR parameters.
#' @param initial_errors Initial state.
#' @param residuals Innovations.
#'
#' @param ma_parameters MA parameters.
#' @param previous_residuals MA state.
#'
#' @returns Data table.
#' @export
forecast_arma<-function(parameters,initial_errors,residuals,ma_parameters=numeric(),previous_residuals=numeric()){es<-initial_errors;rs<-previous_residuals;out<-vector("list",length(residuals));for(i in seq_along(residuals)){ar<-sum(parameters@coefficients*es);ma<-if(length(ma_parameters))sum(ma_parameters*rs) else 0;total<-ar+ma+residuals[i];out[[i]]<-data.table::data.table(step=i-1L,ar_contribution=ar,ma_contribution=ma,residual_contribution=residuals[i],arma_error=total);es<-if(parameters@order==1L)total else c(total,es[-parameters@order]);if(length(ma_parameters))rs<-if(length(ma_parameters)==1L)residuals[i] else c(residuals[i],rs[-length(rs)])};data.table::rbindlist(out)}
S7::method(response,ARParameterSet)<-function(x,...,ma_parameters=numeric(),steps=480L){q<-detect_ma_order(ma_parameters);b<-if(q)ma_parameters[seq_len(q)] else numeric();res<-numeric(steps);res[1]<-1;ARMAResponse(parameters=x,ma_parameters=b,series=forecast_arma(x,numeric(x@order),res,b,numeric(length(b))))}
#' Compare response components
#'
#' @param parameters AR parameters.
#' @param ma_parameters MA parameters.
#' @param steps Steps.
#'
#' @returns Long data table.
#' @export
response_components<-function(parameters,ma_parameters=numeric(),steps=480L){q<-detect_ma_order(ma_parameters);b<-if(q)ma_parameters[seq_len(q)] else numeric();ar<-response(parameters,steps=steps)@series[,.(step=step,response=arma_error,component="AR")];both<-response(parameters,ma_parameters=b,steps=steps)@series[,.(step=step,response=arma_error,component="ARMA")];data.table::rbindlist(list(ar,both))}
