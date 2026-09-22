# S7 generics ----------------------------------------------------------------

#' Calculate characteristic roots
#'
#' @param x Object for which characteristic roots are required.
#' @param ... Additional arguments passed to a method.
#'
#' @return A `CharacteristicRoots` object.
#'
#' @export
roots <- S7::new_generic(
  "roots",
  dispatch_args = "x",
  fun = function(x, ...) {
    S7::S7_dispatch()
  }
)

#' Assess AR parameter quality
#'
#' @param x Object to assess.
#' @param ... Additional arguments passed to a method.
#'
#' @return An `ARAssessment` object.
#'
#' @export
assess <- S7::new_generic(
  "assess",
  dispatch_args = "x",
  fun = function(x, ...) {
    S7::S7_dispatch()
  }
)

#' Forecast an autoregressive error series
#'
#' @param x Object defining the AR model.
#' @param ... Additional arguments passed to a method.
#' @param initial_errors Numeric input errors ordered newest first.
#' @param steps Number of future model steps to calculate.
#' @param time_step_minutes Duration represented by one model step.
#'
#' @return An `ARForecast` object.
#'
#' @export
forecast_ar <- S7::new_generic(
  "forecast_ar",
  dispatch_args = "x",
  fun = function(
      x,
      ...,
      initial_errors,
      steps = 480L,
      time_step_minutes = 15
  ) {
    S7::S7_dispatch()
  }
)

#' Decompose an AR forecast into root contributions
#'
#' @param x Object defining the AR model.
#' @param ... Additional arguments passed to a method.
#' @param initial_errors Numeric input errors ordered newest first.
#' @param steps Number of future model steps to calculate.
#' @param time_step_minutes Duration represented by one model step.
#'
#' @return A long-format `data.table` containing one contribution per root and
#'   model step.
#'
#' @export
decompose_ar <- S7::new_generic(
  "decompose_ar",
  dispatch_args = "x",
  fun = function(
      x,
      ...,
      initial_errors,
      steps = 480L,
      time_step_minutes = 15
  ) {
    S7::S7_dispatch()
  }
)

#' Calculate an ARMA unit response
#'
#' @param x Object defining the AR component.
#' @param ... Additional arguments passed to a method.
#' @param ma_parameters Numeric MA coefficients ordered from `b_1` to `b_q`.
#' @param steps Number of response steps, including the impulse step.
#'
#' @return An `ARMAResponse` object.
#'
#' @export
response <- S7::new_generic(
  "response",
  dispatch_args = "x",
  fun = function(
      x,
      ...,
      ma_parameters = numeric(),
      steps = 480L
  ) {
    S7::S7_dispatch()
  }
)

#' Plot a reach.postproc object
#'
#' @param x Object to plot.
#' @param ... Additional arguments passed to a method.
#'
#' @return A `ggplot` object.
#'
#' @export
plot_ar <- S7::new_generic(
  "plot_ar",
  dispatch_args = "x",
  fun = function(x, ...) {
    S7::S7_dispatch()
  }
)
