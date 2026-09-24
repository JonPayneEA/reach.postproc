#' Align observed and simulated series
#'
#' @param observed,simulated Input tables.
#' @param observed_time_column,simulated_time_column Time columns.
#'
#' @param observed_value_column,simulated_value_column Value columns.
#' @param join Join type.
#'
#' @param duplicate_action Duplicate handling.
#' @param interval_minutes Expected interval.
#' @param timezone Timezone.
#' @param metadata Metadata.
#'
#'
#' @returns An aligned-series result.
#' @export
align_forecast_series<-function(observed,simulated,observed_time_column="date_time",observed_value_column="value",simulated_time_column="date_time",simulated_value_column="value",join=c("inner","full"),duplicate_action=c("error","mean","first"),interval_minutes=NULL,timezone="UTC",metadata=list()){
 join<-match.arg(join);duplicate_action<-match.arg(duplicate_action);o<-as_dt_copy(observed);s<-as_dt_copy(simulated);obs<-data.table::data.table(date_time=as.POSIXct(o[[observed_time_column]],tz=timezone),observed=o[[observed_value_column]]);sim<-data.table::data.table(date_time=as.POSIXct(s[[simulated_time_column]],tz=timezone),simulated=s[[simulated_value_column]])
 if(duplicate_action=="error"&&(anyDuplicated(obs$date_time)||anyDuplicated(sim$date_time)))stop_bad_argument("Duplicate timestamps.");out<-merge(obs,sim,by="date_time",all=join=="full",sort=TRUE);data.table::set(out,j="error",value=out$observed-out$simulated);delta<-if(nrow(out)>1)as.numeric(diff(out$date_time),units="secs") else numeric();diag<-data.table::data.table(observed_rows=nrow(obs),simulated_rows=nrow(sim),aligned_rows=nrow(out),missing_observed=sum(is.na(out$observed)),missing_simulated=sum(is.na(out$simulated)),regular_time_step=if(is.null(interval_minutes)||!length(delta))NA else all(abs(delta-interval_minutes*60)<=1));AlignedForecastSeries(series=out,diagnostics=diag,metadata=metadata)}
#' Fixed lead-time updates
#'
#' @param parameters AR parameters.
#' @param data Aligned data.
#' @param lead_times_minutes Leads.
#'
#' @param time_step_minutes Timestep.
#' @param lower_limit Lower bound.
#' @param method Method.
#' @param metadata Metadata.
#'
#'
#' @returns A lead-time result.
#' @export
fixed_lead_ar<-function(parameters,data,lead_times_minutes=c(30,60,90),time_step_minutes=15,lower_limit=NULL,method=c("recurrence","roots"),metadata=list()){method<-match.arg(method);d<-if(S7::S7_inherits(data,AlignedForecastSeries))data.table::copy(data@series) else as_dt_copy(data);errors<-d$observed-d$simulated;result<-data.table::rbindlist(lapply(lead_times_minutes,function(minutes){L<-as.integer(minutes/time_step_minutes);corr<-rep(NA_real_,nrow(d));for(i in seq_len(nrow(d))){origin<-i-L;ix<-origin-seq.int(0L,parameters@order-1L);if(min(ix)<1L||anyNA(errors[ix]))next;corr[i]<-forecast_ar(parameters,initial_errors=errors[ix],steps=L)@series$ar_error[L]};u<-d$simulated+corr;v<-if(is.null(lower_limit))u else pmax(u,lower_limit);data.table::data.table(date_time=d$date_time,lead_time_minutes=minutes,observed=d$observed,simulated=d$simulated,ar_error=corr,updated=v)}));ARLeadTimeResult(parameters=parameters,series=result,lead_times_minutes=as.numeric(lead_times_minutes),time_step_minutes=as.numeric(time_step_minutes),metadata=metadata)}
#' Score lead-time results
#'
#' @param x Lead-time result.
#'
#' @returns Scores.
#' @export
score_lead_times<-function(x){s<-data.table::copy(x@series);s<-s[stats::complete.cases(s[,c("observed","simulated","updated"),with=FALSE])];s[,.(n=.N,mae_simulated=mean(abs(simulated-observed)),mae_updated=mean(abs(updated-observed)),rmse_simulated=sqrt(mean((simulated-observed)^2)),rmse_updated=sqrt(mean((updated-observed)^2)),bias_simulated=mean(simulated-observed),bias_updated=mean(updated-observed)),by=lead_time_minutes]}
