#' Calculate characteristic roots
#'
#' @param x Object to analyse.
#' @param ... Method arguments.
#'
#'
#' @returns A characteristic-root result.
#' @export
roots <- S7::new_generic("roots", "x", function(x, ...) S7::S7_dispatch())
#' Assess AR parameters
#'
#' @param x Object to assess.
#' @param ... Method arguments.
#'
#'
#' @returns An assessment result.
#' @export
assess <- S7::new_generic("assess", "x", function(x, ...) S7::S7_dispatch())
#' Forecast an AR error series
#'
#' @param x AR parameters.
#' @param ... Method arguments.
#'
#' @param initial_errors Errors ordered newest first.
#' @param steps Projected steps.
#'
#' @param time_step_minutes Minutes per step.
#'
#' @returns An AR forecast result.
#' @export
forecast_ar <- S7::new_generic("forecast_ar","x",function(x,...,initial_errors,steps=480L,time_step_minutes=15)S7::S7_dispatch())
#' Decompose AR behaviour by root
#'
#' @inheritParams forecast_ar
#'
#' @returns A long data table.
#' @export
decompose_ar <- S7::new_generic("decompose_ar","x",function(x,...,initial_errors,steps=480L,time_step_minutes=15)S7::S7_dispatch())
#' Calculate an ARMA unit response
#'
#' @param x AR parameters.
#' @param ... Method arguments.
#' @param ma_parameters MA parameters.
#'
#' @param steps Response steps.
#'
#' @returns An ARMA response.
#' @export
response <- S7::new_generic("response","x",function(x,...,ma_parameters=numeric(),steps=480L)S7::S7_dispatch())
#' Plot a reach.postproc result
#'
#' @param x Object to plot.
#' @param ... Method arguments.
#'
#' @returns A ggplot.
#' @export
plot_ar <- S7::new_generic("plot_ar","x",function(x,...)S7::S7_dispatch())
