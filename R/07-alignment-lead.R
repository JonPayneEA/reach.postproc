#' Align observed and simulated forecast series
#'
#' Join observations and simulations by timestamp, calculate model error and
#' report diagnostics before fixed lead-time analysis.
#'
#' @param observed Data frame or `data.table` containing observation timestamps
#'   and values.
#' @param simulated Data frame or `data.table` containing simulation timestamps
#'   and values.
#' @param observed_time_column,simulated_time_column Names of timestamp columns.
#'   Values must be convertible to `POSIXct`.
#' @param observed_value_column,simulated_value_column Names of numeric value
#'   columns. Both series must represent the same physical quantity and units.
#' @param join Join type. `"inner"` retains matched timestamps. `"full"` also
#'   retains unmatched values so missing data remain visible in diagnostics.
#' @param duplicate_action How duplicate timestamps are handled. `"error"`
#'   stops; `"mean"` averages duplicate values; `"first"` retains the first.
#' @param interval_minutes Optional expected interval. When supplied, the result
#'   reports whether the aligned sequence has a regular timestep.
#' @param timezone Timezone used when converting timestamps, normally `"UTC"`.
#' @param metadata Named list of identifiers such as site, event, measure, units,
#'   model version or rating version.
#'
#' @returns An aligned-series result. Use [aligned_series()] for data and
#'   [alignment_diagnostics()] for checks.
#'
#' @examples
#' time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:12 * 900
#'
#' observed <- data.frame(date_time = time, value = 1 + sin(0:12 / 4))
#' simulated <- data.frame(date_time = time, value = 0.9 + sin(0:12 / 4))
#'
#' aligned <- align_forecast_series(
#'   observed,
#'   simulated,
#'   interval_minutes = 15,
#'   metadata = list(site_id = "example", units = "m")
#' )
#'
#' alignment_diagnostics(aligned)
#' @export
align_forecast_series<-function(observed,simulated,observed_time_column="date_time",observed_value_column="value",simulated_time_column="date_time",simulated_value_column="value",join=c("inner","full"),duplicate_action=c("error","mean","first"),interval_minutes=NULL,timezone="UTC",metadata=list()){join<-match.arg(join);duplicate_action<-match.arg(duplicate_action);o<-as_dt_copy(observed);s<-as_dt_copy(simulated);obs<-data.table::data.table(date_time=as.POSIXct(o[[observed_time_column]],tz=timezone),observed=o[[observed_value_column]]);sim<-data.table::data.table(date_time=as.POSIXct(s[[simulated_time_column]],tz=timezone),simulated=s[[simulated_value_column]]);if(duplicate_action=="error"&&(anyDuplicated(obs$date_time)||anyDuplicated(sim$date_time)))stop_bad_argument("Duplicate timestamps.");if(duplicate_action=="mean"){obs<-obs[,.(observed=mean(observed,na.rm=TRUE)),by=date_time];sim<-sim[,.(simulated=mean(simulated,na.rm=TRUE)),by=date_time]};if(duplicate_action=="first"){obs<-obs[!duplicated(date_time)];sim<-sim[!duplicated(date_time)]};out<-merge(obs,sim,by="date_time",all=join=="full",sort=TRUE);data.table::set(out,j="error",value=out$observed-out$simulated);delta<-if(nrow(out)>1)as.numeric(diff(out$date_time),units="secs")else numeric();diag<-data.table::data.table(observed_rows=nrow(obs),simulated_rows=nrow(sim),aligned_rows=nrow(out),missing_observed=sum(is.na(out$observed)),missing_simulated=sum(is.na(out$simulated)),regular_time_step=if(is.null(interval_minutes)||!length(delta))NA else all(abs(delta-interval_minutes*60)<=1));AlignedForecastSeries(series=out,diagnostics=diag,metadata=metadata)}
#' Calculate fixed lead-time AR updates
#'
#' Reconstruct what the updated forecast would have said at each target time had
#' it always started a fixed number of minutes earlier.
#'
#' @param parameters An assessed AR parameter object.
#' @param data An aligned-series result from [align_forecast_series()] or a table
#'   with `date_time`, `observed` and `simulated` columns.
#' @param lead_times_minutes Positive numeric lead times. Every value must be an
#'   exact multiple of `time_step_minutes`.
#' @param time_step_minutes Minutes represented by one model timestep.
#' @param lower_limit Optional lower bound applied to the displayed update.
#' @param method Calculation method. `"recurrence"` is the production route.
#'   `"roots"` provides an independent mathematical comparison where supported.
#' @param metadata Named list of site, model and event identifiers attached to
#'   the result.
#'
#' @returns A fixed lead-time result. Use [lead_time_series()],
#'   [score_lead_times()] and [plot_lead_times()] to inspect it.
#'
#' @examples
#' time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:80 * 900
#' simulation <- 0.8 + sin(0:80 / 12)
#' observation <- simulation + 0.1
#'
#' aligned <- align_forecast_series(
#'   data.frame(date_time = time, value = observation),
#'   data.frame(date_time = time, value = simulation),
#'   interval_minutes = 15
#' )
#'
#' result <- fixed_lead_ar(
#'   default_ar_parameters(),
#'   aligned,
#'   lead_times_minutes = c(30, 60),
#'   time_step_minutes = 15
#' )
#'
#' head(lead_time_series(result))
#' @export
fixed_lead_ar<-function(parameters,data,lead_times_minutes=c(30,60,90),time_step_minutes=15,lower_limit=NULL,method=c("recurrence","roots"),metadata=list()){method<-match.arg(method);d<-if(S7::S7_inherits(data,AlignedForecastSeries))data.table::copy(data@series)else as_dt_copy(data);if(any(lead_times_minutes<=0)||any(lead_times_minutes%%time_step_minutes!=0))stop_bad_argument("Lead times must be positive timestep multiples.");errors<-d$observed-d$simulated;result<-data.table::rbindlist(lapply(lead_times_minutes,function(minutes){L<-as.integer(minutes/time_step_minutes);corr<-rep(NA_real_,nrow(d));for(i in seq_len(nrow(d))){origin<-i-L;ix<-origin-seq.int(0L,parameters@order-1L);if(min(ix)<1L||anyNA(errors[ix]))next;corr[i]<-forecast_ar(parameters,initial_errors=errors[ix],steps=L)@series$ar_error[L]};u<-d$simulated+corr;v<-if(is.null(lower_limit))u else pmax(u,lower_limit);data.table::data.table(date_time=d$date_time,lead_time_minutes=minutes,observed=d$observed,simulated=d$simulated,ar_error=corr,updated_unconstrained=u,updated=v,calculation_method=method)}));ARLeadTimeResult(parameters=parameters,series=result,lead_times_minutes=as.numeric(lead_times_minutes),time_step_minutes=as.numeric(time_step_minutes),metadata=metadata)}
#' Score fixed lead-time AR forecasts
#'
#' Compare simulated and updated values against observations separately for each
#' forecast lead.
#'
#' @param x A fixed lead-time result from [fixed_lead_ar()] or a compatible long
#'   table containing `lead_time_minutes`, `observed`, `simulated` and `updated`.
#' @param metrics Character vector of requested metrics where supported. Common
#'   choices include `"mae"`, `"rmse"`, `"bias"`,
#'   `"maximum_absolute_error"` and `"outperformance_rate"`.
#'
#' @returns One-row-per-lead `data.table` of performance metrics. Positive MAE
#'   or RMSE improvement means the update outperformed the simulation.
#'
#' @examples
#' # See fixed_lead_ar() for construction of a full result.
#' example_scores <- data.table::data.table(
#'   lead_time_minutes = c(30, 30, 60, 60),
#'   observed = c(1.0, 1.2, 1.0, 1.2),
#'   simulated = c(0.8, 1.0, 0.8, 1.0),
#'   updated = c(0.95, 1.15, 0.9, 1.1)
#' )
#'
#' score_lead_times(example_scores)
#' @export
score_lead_times<-function(x,metrics=c("mae","rmse","bias")){s<-if(S7::S7_inherits(x,ARLeadTimeResult))data.table::copy(x@series)else as_dt_copy(x);s<-s[stats::complete.cases(s[,c("observed","simulated","updated"),with=FALSE])];s[,.(n=.N,mae_simulated=mean(abs(simulated-observed)),mae_updated=mean(abs(updated-observed)),rmse_simulated=sqrt(mean((simulated-observed)^2)),rmse_updated=sqrt(mean((updated-observed)^2)),bias_simulated=mean(simulated-observed),bias_updated=mean(updated-observed),improvement_mae=mean(abs(simulated-observed))-mean(abs(updated-observed)),improvement_rmse=sqrt(mean((simulated-observed)^2))-sqrt(mean((updated-observed)^2))),by=lead_time_minutes]}
