#' Extract root table
#'
#' @param x Root or assessment result.
#'
#' @returns Data table.
#' @export
root_table<-function(x){if(S7::S7_inherits(x,ARAssessment))x<-x@roots;data.table::copy(x@table)}
#' Extract assessment table
#'
#' @param x Assessment.
#'
#' @returns Data table.
#' @export
assessment_table<-function(x)data.table::copy(x@tests)
#' Extract forecast series
#'
#' @param x Forecast.
#'
#' @returns Data table.
#' @export
forecast_series<-function(x)data.table::copy(x@series)
#' Extract aligned series
#'
#' @param x Aligned result.
#'
#' @returns Data table.
#' @export
aligned_series<-function(x)data.table::copy(x@series)
#' Extract alignment diagnostics
#'
#' @param x Aligned result.
#'
#' @returns Data table.
#' @export
alignment_diagnostics<-function(x)data.table::copy(x@diagnostics)
#' Extract lead-time series
#'
#' @param x Lead result.
#'
#' @returns Data table.
#' @export
lead_time_series<-function(x)data.table::copy(x@series)
S7::method(plot_ar,CharacteristicRoots)<-function(x,...,root_definition=c("modal","lag"),show_labels=TRUE,maximum_plot_limit=NULL){root_definition<-match.arg(root_definition);d<-data.table::copy(x@table);if(root_definition=="modal"){d[,`:=`(plot_real=root_real,plot_imaginary=root_imaginary,stability=modal_stability)];subtitle<-"EA modal roots: stable region is inside the unit circle"}else{d[,`:=`(plot_real=lag_root_real,plot_imaginary=lag_root_imaginary,stability=lag_stability)];subtitle<-"Reciprocal lag roots: stable region is outside the unit circle"};a<-seq(0,2*pi,length.out=721);circle<-data.table::data.table(x=cos(a),y=sin(a));limit<-1.1*max(1,abs(d$plot_real),abs(d$plot_imaginary));if(!is.null(maximum_plot_limit))limit<-min(limit,maximum_plot_limit);p<-ggplot2::ggplot()+ggplot2::geom_polygon(data=circle,ggplot2::aes(x,y,group=1),fill="grey95")+ggplot2::geom_point(data=d,ggplot2::aes(plot_real,plot_imaginary,colour=stability),size=3.5)+ggplot2::coord_fixed(xlim=c(-limit,limit),ylim=c(-limit,limit))+ggplot2::theme_minimal()+ggplot2::labs(subtitle=subtitle,x="Real",y="Imaginary");p}
S7::method(plot_ar,ARForecast)<-function(x,...)ggplot2::ggplot(x@series,ggplot2::aes(lead_time_hours,ar_error))+ggplot2::geom_line()+ggplot2::theme_minimal()
#' Plot fixed lead-time results
#'
#' @param x Lead result.
#' @param thresholds Optional thresholds.
#' @param common_period_only Common period flag.
#'
#' @returns Plot.
#' @export
plot_lead_times<-function(x,thresholds=NULL,common_period_only=TRUE){d<-data.table::copy(x@series);base<-unique(d[,.(date_time=date_time,observed=observed,simulated=simulated)]);long<-data.table::melt(base,id.vars="date_time",variable.name="series",value.name="value");long<-data.table::rbindlist(list(long,d[,.(date_time=date_time,series=paste0("t-",lead_time_minutes),value=updated)]));ggplot2::ggplot(long,ggplot2::aes(date_time,value,colour=series))+ggplot2::geom_line()+ggplot2::theme_minimal()}
