#' Root table
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x a characteristic-root result from `roots()` or an assessment result from `assess()`.
#'
#' @returns a copied `data.table` containing modal roots, reciprocal roots, decay times, periods and stability classifications. The returned table is a copy and may be modified safely.
#'
#' @examples
#' root_table(roots(default_ar_parameters()))
#' @export
root_table<-function(x){if(S7::S7_inherits(x,ARAssessment))x<-x@roots;data.table::copy(x@table)}
#' Assessment table
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x an assessment result returned by `assess()`.
#'
#' @returns a copied `data.table` containing each criterion, pass or fail status and affected roots. The returned table is a copy and may be modified safely.
#'
#' @examples
#' assessment_table(assess(default_ar_parameters()))
#' @export
assessment_table<-function(x)data.table::copy(x@tests)
#' Forecast series
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x an AR forecast result returned by `forecast_ar()`.
#'
#' @returns a copied `data.table` containing forecast step, lead time and projected error. The returned table is a copy and may be modified safely.
#'
#' @examples
#' forecast_series(forecast_ar(default_ar_parameters(), initial_errors = c(0.15, 0.12, 0.10), steps = 4L))
#' @export
forecast_series<-function(x)data.table::copy(x@series)
#' Aligned series
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x an aligned-series result returned by `align_forecast_series()`.
#'
#' @returns a copied `data.table` containing timestamps, observations, simulations and errors. The returned table is a copy and may be modified safely.
#'
#' @examples
#' aligned_series(align_forecast_series(data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 1), data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 0.9)))
#' @export
aligned_series<-function(x)data.table::copy(x@series)
#' Alignment diagnostics
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x an aligned-series result returned by `align_forecast_series()`.
#'
#' @returns a copied one-row diagnostic table reporting matched rows, missing values, duplicates and timestep checks. The returned table is a copy and may be modified safely.
#'
#' @examples
#' alignment_diagnostics(align_forecast_series(data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 1), data.frame(date_time = as.POSIXct('2024-01-01', tz='UTC'), value = 0.9)))
#' @export
alignment_diagnostics<-function(x)data.table::copy(x@diagnostics)
#' Lead time series
#'
#' Extract the tabular data from a structured package result without exposing
#' callers to its internal S7 property layout.
#'
#' @param x a fixed lead-time result returned by `fixed_lead_ar()`.
#'
#' @returns a copied long `data.table` containing observations, simulations, projected errors and updates by lead. The returned table is a copy and may be modified safely.
#'
#' @examples
#' # See fixed_lead_ar() for a complete construction example.
#' # lead_time_series(result)
#' @export
lead_time_series<-function(x)data.table::copy(x@series)
S7::method(plot_ar,CharacteristicRoots)<-function(x,...,root_definition=c("modal","lag"),show_labels=TRUE,maximum_plot_limit=NULL){root_definition<-match.arg(root_definition);d<-data.table::copy(x@table);if(root_definition=="modal"){d[,`:=`(plot_real=root_real,plot_imaginary=root_imaginary,stability=modal_stability)];subtitle<-"EA modal roots: stable region is inside the unit circle"}else{d[,`:=`(plot_real=lag_root_real,plot_imaginary=lag_root_imaginary,stability=lag_stability)];subtitle<-"Reciprocal lag roots: stable region is outside the unit circle"};a<-seq(0,2*pi,length.out=721L);circle<-data.table::data.table(x=cos(a),y=sin(a));limit<-1.1*max(1,abs(d$plot_real),abs(d$plot_imaginary));if(!is.null(maximum_plot_limit))limit<-min(limit,maximum_plot_limit);p<-ggplot2::ggplot()+ggplot2::geom_polygon(data=circle,ggplot2::aes(x,y,group=1),fill="grey95",colour="grey45")+ggplot2::geom_hline(yintercept=0,colour="grey75")+ggplot2::geom_vline(xintercept=0,colour="grey75")+ggplot2::geom_point(data=d,ggplot2::aes(plot_real,plot_imaginary,colour=stability),size=3.5)+ggplot2::scale_colour_manual(values=c(Stable="#00703C",Marginal="#F47738",Unstable="#D4351C"),drop=FALSE)+ggplot2::coord_fixed(xlim=c(-limit,limit),ylim=c(-limit,limit),expand=FALSE)+ggplot2::theme_minimal()+ggplot2::labs(title="Characteristic roots",subtitle=subtitle,x="Real component",y="Imaginary component",colour=NULL);if(show_labels)p<-p+ggplot2::geom_text(data=d,ggplot2::aes(plot_real,plot_imaginary,label=display_order),nudge_y=.05*limit,show.legend=FALSE);attr(p,"unit_circle_data")<-circle;p}
S7::method(plot_ar,ARForecast)<-function(x,...)ggplot2::ggplot(x@series,ggplot2::aes(lead_time_hours,ar_error))+ggplot2::geom_hline(yintercept=0,colour="grey70")+ggplot2::geom_line(colour="#005EA5")+ggplot2::theme_minimal()+ggplot2::labs(x="Lead time, hours",y="Projected error")
#' Plot fixed lead-time observations, simulations and updates
#'
#' Create a `ggplot2` time-series comparison for all evaluated lead times.
#'
#' @param x A fixed lead-time result from [fixed_lead_ar()].
#' @param thresholds Optional data frame or `data.table` containing threshold
#'   values and, where supported, display names. Values must use the same units
#'   as the forecast series.
#' @param common_period_only Logical. When `TRUE`, trim the display to the period
#'   where every requested lead has a calculated update. This supports fair
#'   visual comparison across leads.
#'
#' @returns A `ggplot` object that can be printed, modified or saved with
#'   `ggplot2::ggsave()`.
#'
#' @examples
#' time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:80 * 900
#' simulation <- 0.8 + sin(0:80 / 12)
#' observation <- simulation + 0.1
#' aligned <- align_forecast_series(
#'   data.frame(date_time = time, value = observation),
#'   data.frame(date_time = time, value = simulation),
#'   interval_minutes = 15
#' )
#' result <- fixed_lead_ar(
#'   default_ar_parameters(), aligned, c(30, 60)
#' )
#' plot_lead_times(result)
#' @export
plot_lead_times<-function(x,thresholds=NULL,common_period_only=TRUE){d<-lead_time_series(x);base<-unique(d[,.(date_time=date_time,observed=observed,simulated=simulated)]);long<-data.table::melt(base,id.vars="date_time",variable.name="series",value.name="value");long<-data.table::rbindlist(list(long,d[,.(date_time=date_time,series=paste0("t-",lead_time_minutes),value=updated)]));p<-ggplot2::ggplot(long,ggplot2::aes(date_time,value,colour=series))+ggplot2::geom_line()+ggplot2::theme_minimal()+ggplot2::labs(x="Date",y="Value",colour=NULL);if(!is.null(thresholds)){th<-as_dt_copy(thresholds);p<-p+ggplot2::geom_hline(data=th,ggplot2::aes(yintercept=value),linetype="dashed",colour="darkred")};p}
