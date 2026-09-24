#' Calculate characteristic roots and their timescales
#'
#' Convert an AR parameter set into modal roots, reciprocal lag roots, decay
#' times, oscillation periods and stability classifications.
#'
#' @param x An AR parameter object.
#' @param ... Method arguments. For AR parameters, use `time_step_minutes` to
#'   convert step-based timescales to hours and `tolerance` to classify roots
#'   close to the unit circle.
#'
#' @returns A characteristic-root result. Use [root_table()] to extract the
#'   diagnostic table and [plot_ar()] to display the roots.
#'
#' @examples
#' root_information <- roots(
#'   default_ar_parameters(),
#'   time_step_minutes = 15
#' )
#'
#' root_table(root_information)
#' plot_ar(root_information, root_definition = "modal")
#' @export
roots <- S7::new_generic("roots","x",function(x,...)S7::S7_dispatch())
#' Assess AR parameters against operational root criteria
#'
#' Test model order, growth, excessive persistence, universally rapid decay and
#' unacceptable oscillation.
#'
#' @param x An AR parameter object.
#' @param ... Assessment controls passed to the AR-parameter method. These
#'   include `maximum_decay_time`, `minimum_useful_decay_time`,
#'   `rapid_decay_exception`, `oscillation_ratio`, `decay_measure`,
#'   `permitted_orders` and `time_step_minutes`.
#'
#' @returns An assessment result containing an overall pass flag, plain-English
#'   summary, individual test outcomes and root diagnostics.
#'
#' @examples
#' assessment <- assess(
#'   default_ar_parameters(),
#'   maximum_decay_time = 240,
#'   minimum_useful_decay_time = 8,
#'   permitted_orders = c(2L, 3L)
#' )
#'
#' assessment@summary
#' assessment_table(assessment)
#' @export
assess <- S7::new_generic("assess","x",function(x,...)S7::S7_dispatch())
#' Forecast an autoregressive model-error series
#'
#' Project future model error one timestep at a time from a supplied recent
#' error history and AR parameter set.
#'
#' @param x An AR parameter object.
#' @param ... Additional method arguments. The current AR-parameter method does
#'   not use additional unnamed arguments.
#' @param initial_errors Numeric recent errors supplied newest first. The vector
#'   length must equal the AR order. For AR(3), supply errors at times `t-1`,
#'   `t-2` and `t-3` in that order.
#' @param steps Positive whole number of future timesteps to calculate.
#' @param time_step_minutes Positive number of minutes represented by one model
#'   timestep. It controls reported lead times but not the recurrence itself.
#'
#' @returns An AR forecast result. Use [forecast_series()] to obtain its table.
#'
#' @examples
#' parameters <- default_ar_parameters()
#'
#' forecast <- forecast_ar(
#'   parameters,
#'   initial_errors = c(0.15, 0.12, 0.10),
#'   steps = 24L,
#'   time_step_minutes = 15
#' )
#'
#' head(forecast_series(forecast))
#' plot_ar(forecast)
#' @export
forecast_ar <- S7::new_generic("forecast_ar","x",function(x,...,initial_errors,steps=480L,time_step_minutes=15)S7::S7_dispatch())
#' Decompose an AR forecast into characteristic-root contributions
#'
#' Express the projected AR error as the sum of the modal contributions implied
#' by the characteristic roots. This supports mathematical interpretation and
#' verification of the recurrence.
#'
#' @param x An AR parameter object.
#' @param ... Additional method arguments; currently unused.
#' @param initial_errors Numeric recent errors supplied newest first. Length must
#'   equal AR order.
#' @param steps Positive whole number of forecast steps to return.
#' @param time_step_minutes Minutes represented by one step.
#'
#' @returns A long `data.table` with one row per root and forecast step. Summing
#'   `contribution_real` by `step` reconstructs [forecast_ar()]. Modal time zero
#'   corresponds to forecast step one.
#'
#' @examples
#' parameters <- default_ar_parameters()
#'
#' contributions <- decompose_ar(
#'   parameters,
#'   initial_errors = c(0.20, 0.15, 0.10),
#'   steps = 24L
#' )
#'
#' contributions[
#'   ,
#'   .(projected_error = sum(contribution_real)),
#'   by = step
#' ]
#' @export
decompose_ar <- S7::new_generic("decompose_ar","x",function(x,...,initial_errors,steps=480L,time_step_minutes=15)S7::S7_dispatch())
#' Calculate an ARMA unit-innovation response
#'
#' Evaluate how a unit residual innovation is propagated by the supplied AR and
#' optional MA coefficients.
#'
#' @param x An AR parameter object.
#' @param ... Additional method arguments; currently unused.
#' @param ma_parameters Numeric MA coefficients ordered from most recent to
#'   oldest residual. Use `numeric()` for an AR-only response.
#' @param steps Positive whole number of response timesteps.
#'
#' @returns An ARMA response result containing component contributions and total
#'   error through time.
#'
#' @examples
#' parameters <- default_ar_parameters()
#'
#' unit_response <- response(
#'   parameters,
#'   ma_parameters = c(-0.5, -0.25),
#'   steps = 48L
#' )
#'
#' head(unit_response@series)
#' @export
response <- S7::new_generic("response","x",function(x,...,ma_parameters=numeric(),steps=480L)S7::S7_dispatch())
#' Plot AR and ARMA diagnostic objects
#'
#' S7 generic for plotting roots, error forecasts, assessments and response
#' objects with `ggplot2`.
#'
#' @param x A supported `reach.postproc` result.
#' @param ... Method options. Root plots accept `root_definition` (`"modal"` or
#'   `"lag"`), `show_labels` and `maximum_plot_limit`. Other methods use options
#'   documented with their result type.
#'
#' @returns A `ggplot` object.
#'
#' @examples
#' parameters <- default_ar_parameters()
#' plot_ar(roots(parameters), root_definition = "modal")
#'
#' forecast <- forecast_ar(
#'   parameters,
#'   initial_errors = c(0.15, 0.12, 0.10),
#'   steps = 24L
#' )
#' plot_ar(forecast)
#' @export
plot_ar <- S7::new_generic("plot_ar","x",function(x,...)S7::S7_dispatch())
